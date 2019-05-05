----------------------------------------------------------------------------------------
--
-- File name:   cs_tables.sql
--
-- Purpose:     Tables Size
--
-- Author:      Carlos Sierra
--
-- Version:     2019/05/02
--
-- Usage:       Execute connected to PDB or CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_tables.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_tables';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL dummy NOPRI;
COL pdb_name FOR A30 TRUNC;
COL owner FOR A30 TRUNC;
COL table_name FOR A30 TRUNC;
COL total_mbs FOR 99,999,990.0;
COL table_mbs FOR 99,999,990.0;
COL indexes_mbs FOR 99,999,990.0;
COL lobs_mbs FOR 99,999,990.0;
COL est_data_mbs FOR 99,999,990.0;
COL tabs FOR 9990;
COL lobs FOR 9990;
COL idxs FOR 9990;
COL num_rows FOR 999,999,999,990;
COL avg_row_len FOR 999,999,990;
COL last_analyzed FOR A19;
--
BREAK ON dummy;
COMPUT SUM OF total_mbs table_mbs indexes_mbs tabs lobs_mbs est_data_mbs lobs idxs num_rows ON dummy;
--
PRO
PRO All Tables
PRO ~~~~~~~~~~
WITH
tables AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       s.owner,
       s.segment_name table_name,
       SUM(s.bytes) bytes
  FROM cdb_segments s,
       cdb_users u,
       v$containers c
 WHERE s.segment_type LIKE 'TABLE%'
   AND s.owner NOT LIKE 'C##%'
   AND u.con_id = s.con_id
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
   AND c.con_id = s.con_id
 GROUP BY
       c.name,
       s.owner,
       s.segment_name
),
dtables AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       t.owner,
       t.table_name,
       t.num_rows,
       t.avg_row_len,
       t.last_analyzed
  FROM cdb_tables t,
       cdb_users u,
       v$containers c
 WHERE t.owner NOT LIKE 'C##%'
   AND u.con_id = t.con_id
   AND u.username = t.owner
   AND u.oracle_maintained = 'N'
   AND c.con_id = t.con_id
),
indexes AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       s.owner,
       i.table_name,
       SUM(s.bytes) bytes,
       COUNT(DISTINCT s.segment_name) cnt
  FROM cdb_segments s,
       cdb_users u,
       v$containers c,
       cdb_indexes i
 WHERE s.segment_type LIKE '%INDEX%'
   AND s.owner NOT LIKE 'C##%'
   AND u.con_id = s.con_id
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
   AND c.con_id = s.con_id
   AND i.con_id = s.con_id
   AND i.owner = s.owner
   AND i.index_name = s.segment_name
 GROUP BY
       c.name,
       s.owner,
       i.table_name
),
lobs AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       s.owner,
       l.table_name,
       SUM(s.bytes) bytes,
       COUNT(DISTINCT s.segment_name) cnt
  FROM cdb_segments s,
       cdb_users u,
       v$containers c,
       cdb_lobs l
 WHERE s.segment_type LIKE 'LOB%'
   AND s.owner NOT LIKE 'C##%'
   AND s.segment_type <> 'LOBINDEX'
   AND u.con_id = s.con_id
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
   AND c.con_id = s.con_id
   AND l.con_id = s.con_id
   AND l.owner = s.owner
   AND l.segment_name = s.segment_name
 GROUP BY
       c.name,
       s.owner,
       l.table_name
)
SELECT NULL dummy,
       t.owner,
       t.table_name,
       (NVL(t.bytes,0)+NVL(i.bytes,0)+NVL(l.bytes,0))/POWER(2,20) total_mbs,
       NVL(t.bytes,0)/POWER(2,20) table_mbs,
       NVL(l.bytes,0)/POWER(2,20) lobs_mbs,
       NVL(i.bytes,0)/POWER(2,20) indexes_mbs,
       1 tabs,
       NVL(l.cnt,0) lobs,
       NVL(i.cnt,0) idxs,
       NVL(d.num_rows,0) num_rows,
       NVL(d.avg_row_len,0) avg_row_len,
       NVL(d.num_rows*d.avg_row_len,0)/POWER(2,20) est_data_mbs,
       d.last_analyzed,
       t.pdb_name
  FROM tables t,
       dtables d,
       indexes i,
       lobs l
 WHERE d.pdb_name(+) = t.pdb_name
   AND d.owner(+) = t.owner
   AND d.table_name(+) = t.table_name
   AND i.pdb_name(+) = t.pdb_name
   AND i.owner(+) = t.owner
   AND i.table_name(+) = t.table_name
   AND l.pdb_name(+) = t.pdb_name
   AND l.owner(+) = t.owner
   AND l.table_name(+) = t.table_name
 ORDER BY
       t.pdb_name,
       t.owner,
       t.table_name
/
--
PRO
PRO Top Tables
PRO ~~~~~~~~~~
WITH
tables AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       s.owner,
       s.segment_name table_name,
       SUM(s.bytes) bytes
  FROM cdb_segments s,
       cdb_users u,
       v$containers c
 WHERE s.segment_type LIKE 'TABLE%'
   AND s.owner NOT LIKE 'C##%'
   AND u.con_id = s.con_id
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
   AND c.con_id = s.con_id
 GROUP BY
       c.name,
       s.owner,
       s.segment_name
),
dtables AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       t.owner,
       t.table_name,
       t.num_rows,
       t.avg_row_len,
       t.last_analyzed
  FROM cdb_tables t,
       cdb_users u,
       v$containers c
 WHERE t.owner NOT LIKE 'C##%'
   AND u.con_id = t.con_id
   AND u.username = t.owner
   AND u.oracle_maintained = 'N'
   AND c.con_id = t.con_id
),
indexes AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       s.owner,
       i.table_name,
       SUM(s.bytes) bytes,
       COUNT(DISTINCT s.segment_name) cnt
  FROM cdb_segments s,
       cdb_users u,
       v$containers c,
       cdb_indexes i
 WHERE s.segment_type LIKE '%INDEX%'
   AND s.owner NOT LIKE 'C##%'
   AND u.con_id = s.con_id
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
   AND c.con_id = s.con_id
   AND i.con_id = s.con_id
   AND i.owner = s.owner
   AND i.index_name = s.segment_name
 GROUP BY
       c.name,
       s.owner,
       i.table_name
),
lobs AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       s.owner,
       l.table_name,
       SUM(s.bytes) bytes,
       COUNT(DISTINCT s.segment_name) cnt
  FROM cdb_segments s,
       cdb_users u,
       v$containers c,
       cdb_lobs l
 WHERE s.segment_type LIKE 'LOB%'
   AND s.owner NOT LIKE 'C##%'
   AND s.segment_type <> 'LOBINDEX'
   AND u.con_id = s.con_id
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
   AND c.con_id = s.con_id
   AND l.con_id = s.con_id
   AND l.owner = s.owner
   AND l.segment_name = s.segment_name
 GROUP BY
       c.name,
       s.owner,
       l.table_name
)
SELECT NULL dummy,
       t.owner,
       t.table_name,
       (NVL(t.bytes,0)+NVL(i.bytes,0)+NVL(l.bytes,0))/POWER(2,20) total_mbs,
       NVL(t.bytes,0)/POWER(2,20) table_mbs,
       NVL(l.bytes,0)/POWER(2,20) lobs_mbs,
       NVL(i.bytes,0)/POWER(2,20) indexes_mbs,
       1 tabs,
       NVL(l.cnt,0) lobs,
       NVL(i.cnt,0) idxs,
       NVL(d.num_rows,0) num_rows,
       NVL(d.avg_row_len,0) avg_row_len,
       NVL(d.num_rows*d.avg_row_len,0)/POWER(2,20) est_data_mbs,
       d.last_analyzed,
       t.pdb_name
  FROM tables t,
       dtables d,
       indexes i,
       lobs l
 WHERE d.pdb_name(+) = t.pdb_name
   AND d.owner(+) = t.owner
   AND d.table_name(+) = t.table_name
   AND i.pdb_name(+) = t.pdb_name
   AND i.owner(+) = t.owner
   AND i.table_name(+) = t.table_name
   AND l.pdb_name(+) = t.pdb_name
   AND l.owner(+) = t.owner
   AND l.table_name(+) = t.table_name
 ORDER BY
       NVL(t.bytes,0)+NVL(i.bytes,0)+NVL(l.bytes,0) DESC
FETCH FIRST 20 ROWS ONLY
/
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--


