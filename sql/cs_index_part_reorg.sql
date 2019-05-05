----------------------------------------------------------------------------------------
--
-- File name:   cs_index_part_reorg.sql
--
-- Purpose:     Calculate index reorg savings
--
-- Author:      Rodrigo Righetti
--
-- Version:     2019/04/16
--
-- Usage:       Execute connected to PDB.
--
--              Enter Owner, Table and Index when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_index_part_reorg.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
col partition_name for a20
set pages 67
set lines 150

PRO 1. Table Owner:
DEF table_owner = '&1.';
SELECT DISTINCT UPPER(owner) table_owner
  FROM dba_tables
 WHERE owner = UPPER(TRIM('&&table_owner.'))
/

PRO 2. Table Name:
DEF table_name = '&2.';
SELECT DISTINCT UPPER(table_name) table_name
  FROM dba_tables
 WHERE table_name = UPPER(TRIM('&&table_name.'))
/

PRO 3. Index Name:
DEF index_name = '&3.';
SELECT DISTINCT UPPER(index_name) index_name
  FROM dba_indexes
 WHERE index_name = UPPER(TRIM('&&index_name.'))
/


WITH ca AS (
    SELECT /*+ MATERIALIZE */
        SUM(avg_col_len) actual_size,
        SUM(avg_col_len) * 1.25 est_size
    FROM
        dba_tab_columns
    WHERE
        table_name = '&&table_name.'
        and owner = '&&table_owner.'
        AND column_name IN (
            SELECT
                column_name
            FROM
                dba_ind_columns
            WHERE
                index_name = '&&index_name.'
        )
), ps AS (
    SELECT /*+ MATERIALIZE */
        partition_name,
        round(bytes / power(2, 20), 2) size_mb
    FROM
        dba_segments
    WHERE
        segment_name = '&&index_name.'
), pr AS (
    SELECT /*+ MATERIALIZE */
        partition_name,
        num_rows
    FROM
        dba_ind_partitions
    WHERE
        index_name = '&&index_name.'
)
SELECT
    *
FROM
    (
        SELECT
            pr.partition_name,
            pr.num_rows,
            ps.size_mb,
            round((ca.actual_size * pr.num_rows) / power(2, 20), 2) est_used_size_mb,
            round((ca.est_size * pr.num_rows) / power(2, 20), 2) est_rebuild_size_mb,
            round((1 -(((ca.est_size * pr.num_rows) / power(2, 20)) / ps.size_mb)) * 100, 2) savings_pct
        FROM
            pr,
            ps,
            ca
        WHERE
            pr.partition_name = ps.partition_name
        ORDER BY
            round((1 -(((ca.est_size * pr.num_rows) / power(2, 20)) / ps.size_mb)) * 100, 2)
    )
UNION ALL
SELECT
    'TOTAL',
    SUM(pr.num_rows) num_rows,
    SUM(ps.size_mb) size_mb,
    SUM(round((ca.actual_size * pr.num_rows) / power(2, 20), 2)) est_used_size_mb,
    SUM(round((ca.est_size * pr.num_rows) / power(2, 20), 2)) est_rebuild_size_mb,
    round((1 -(SUM(round((ca.est_size * pr.num_rows) / power(2, 20), 2)) / SUM(ps.size_mb))) * 100, 2) savings_pct
FROM
    pr,
    ps,
    ca
WHERE
    pr.partition_name = ps.partition_name;