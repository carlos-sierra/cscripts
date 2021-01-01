----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_gc_status.sql
--
-- Purpose:     KIEV PDB Garbage Collection (GC) status
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/25
--
-- Usage:       Execute connected to PDB or CDB
--
--              Enter range of dates when requested
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_gc_status.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
-- consider only tables with more than these many rows
DEF n_rows = '500';
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_kiev_gc_status';
DEF cs_hours_range_default = '6';
--
ALTER SESSION SET container = CDB$ROOT;
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(last_analyzed)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM &&cs_tools_schema..dbc_tables
/
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
COL owner FOR A30 TRUNC;
COL table_name FOR A30 TRUNC;
COL pdb_name FOR A30 TRUNC;
COL inserts FOR 999,999,999,990;
COL deletes FOR 999,999,999,990;
COL growth FOR 999,999,999,990;
COL max_num_rows FOR 999,999,999,990;
COL no_gc FOR A5;
--
BREAK ON pdb_name SKIP PAGE DUPL;
COMPUTE SUM LABEL '' OF inserts deletes growth max_num_rows ON pdb_name;
--
WITH
kiev AS (
SELECT /*+ MATERIALIZE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ DISTINCT c.name AS pdb_name FROM cdb_tables t, v$containers c WHERE t.table_name = 'KIEVDATASTOREMETADATA' AND c.con_id = t.con_id
),
non_part AS (
SELECT /*+ MATERIALIZE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ DISTINCT c.name AS pdb_name, t.owner, t.table_name FROM cdb_tables t, v$containers c WHERE t.partitioned = 'NO' AND c.con_id = t.con_id
),
tab_modifications AS (
SELECT owner,
       table_name,
       timestamp,
       inserts,
       deletes,
       num_rows,
       pdb_name
  FROM &&cs_tools_schema..dbc_tab_modifications
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
   AND timestamp BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND inserts + deletes >= 0
   AND timestamp - last_analyzed > 0
   AND partition_name IS NULL
   AND updates = 0
   AND pdb_name IN (SELECT pdb_name FROM kiev)
   AND (pdb_name, owner, table_name) IN (SELECT pdb_name, owner, table_name FROM non_part)
)
SELECT table_name,
       CASE WHEN SUM(deletes) = 0 AND SUM(inserts) > 0 THEN '*****' END AS no_gc,
       SUM(inserts) AS inserts,
       SUM(deletes) AS deletes,
       SUM(inserts) - SUM(deletes) AS growth,
       MAX(num_rows) AS max_num_rows,
       owner,
       pdb_name
  FROM tab_modifications
 GROUP BY
       pdb_name,
       table_name,
       owner
 HAVING MAX(num_rows) > &&n_rows.
 ORDER BY
       pdb_name,
       table_name,
       owner
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--