----------------------------------------------------------------------------------------
--
-- File name:   cs_table_stats_report.sql
--
-- Purpose:     CBO Statistics History for given Table (time series text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/09/13
--
-- Usage:       Execute connected to PDB.
--
--              Enter Table when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_table_stats_report.sql
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
DEF cs_script_name = 'cs_table_stats_report';
DEF cs_hours_range_default = '8760';
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(last_analyzed)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM &&cs_tools_schema..dbc_tables
/
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL owner NEW_V owner FOR A30 HEA 'TABLE_OWNER';
COL oracle_maintained FOR A4 HEA 'ORCL';
COL tables FOR 999,990;
BREAK ON oracle_maintained SKIP PAGE DUPL;
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       u.oracle_maintained,
       t.owner,
       COUNT(DISTINCT t.table_name) AS tables
  FROM &&cs_tools_schema..dbc_tables t,
       cdb_users u
 WHERE t.pdb_name = '&&cs_con_name.'
   AND t.snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND u.username = t.owner
 GROUP BY
       u.oracle_maintained,
       t.owner
 ORDER BY
       u.oracle_maintained DESC,
       t.owner
/
COL table_owner NEW_V table_owner FOR A30;
PRO
PRO 3. Table Owner:
DEF table_owner = '&3.';
UNDEF 3;
SELECT UPPER(NVL('&&table_owner.', '&&owner.')) table_owner FROM DUAL
/
--
COL table_name FOR A30 PRI;
COL num_rows FOR 999,999,999,990;
COL blocks FOR 9,999,999,990;
WITH 
sq1 AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       t.table_name, t.num_rows, t.blocks, t.last_analyzed,
       ROW_NUMBER() OVER (PARTITION BY t.table_name ORDER BY t.snap_time DESC) AS rn
  FROM &&cs_tools_schema..dbc_tables t,
       v$containers c,
       cdb_users u
 WHERE t.pdb_name = '&&cs_con_name.'
   AND t.owner = '&&table_owner.'
   AND t.snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND c.name = t.pdb_name
   AND u.con_id = c.con_id
   AND u.username = t.owner
)
SELECT t.table_name, t.num_rows, t.blocks, t.last_analyzed
  FROM sq1 t
 WHERE t.rn = 1
 ORDER BY
       t.table_name
/
PRO
PRO 4. Table Name:
DEF table_name = '&4.';
UNDEF 4;
COL table_name NEW_V table_name FOR A30 NOPRI;
SELECT UPPER(TRIM('&&table_name.')) table_name FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&table_owner..&&table_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&table_owner." "&&table_name."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO TABLE_OWNER  : &&table_owner.
PRO TABLE_NAME   : &&table_name.
--
COL rows_per_block FOR 999,999,990.0;
COL avg_row_len FOR 999,999,990;
COL sample_size FOR 999,999,999,990;
--
PRO
PRO TABLES (dba_tables) &&table_owner..&&table_name.
PRO ~~~~~~
WITH
my_query AS (
SELECT DISTINCT
       last_analyzed,
       num_rows,
       blocks,
       num_rows/GREATEST(blocks,1) AS rows_per_block,
       avg_row_len,
       sample_size
  FROM &&cs_tools_schema..dbc_tables
 WHERE pdb_name = '&&cs_con_name.'
   AND owner = '&&table_owner.'
   AND table_name = '&&table_name.'
   AND snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
)
SELECT TO_CHAR(q.last_analyzed, '&&cs_datetime_full_format.') last_analyzed,
       q.num_rows,
       q.blocks,
       q.rows_per_block,
       q.avg_row_len,
       q.sample_size
  FROM my_query q
 ORDER BY
       q.last_analyzed
/
--
COL hours_since_gathering FOR 999,990.0 HEA 'HOURS|SINCE|GATHERING';
COL num_rows FOR 999,999,999,990;
COL inserts FOR 999,999,990 HEA 'INSERTS|SINCE|GATHERING';
COL updates FOR 999,999,990 HEA 'UPDATES|SINCE|GATHERING';
COL deletes FOR 999,999,990 HEA 'DELETES|SINCE|GATHERING';
COL inserts_per_sec FOR 999,990.000 HEA 'INSERTS|PER SEC';
COL updates_per_sec FOR 999,990.000 HEA 'UPDATES|PER SEC';
COL deletes_per_sec FOR 999,990.000 HEA 'DELETES|PER SEC';
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
SELECT TO_CHAR(t.last_analyzed, '&&cs_datetime_full_format.') AS last_analyzed,
       t.num_rows,
       ROUND(m.inserts / ((m.timestamp - t.last_analyzed) * 24 * 60 * 60), 3) AS inserts_per_sec,
       ROUND(m.deletes / ((m.timestamp - t.last_analyzed) * 24 * 60 * 60), 3) AS deletes_per_sec,
       ROUND(m.updates / ((m.timestamp - t.last_analyzed) * 24 * 60 * 60), 3) AS updates_per_sec,
       TO_CHAR(m.timestamp, '&&cs_datetime_full_format.') AS timestamp,
       24 * (m.timestamp - t.last_analyzed) AS hours_since_gathering,
       m.inserts,
       m.deletes,
       m.updates
  FROM dba_tables t,
       dba_tab_modifications m
 WHERE t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.'
   AND m.table_owner = t.owner
   AND m.table_name = t.table_name
/
--
COL analyzetime FOR A19 HEA 'Analyze Time';
COL rowcnt FOR 999,999,999,990 HEA 'Row Count';
COL blkcnt FOR 999,999,990 HEA 'Block Count';
COL avgrln FOR 999,999,990 HEA 'Avg Row Len';
COL samplesize FOR 999,999,999,990 HEA 'Sample Size';
--
PRO
PRO CBO STAT TABLE HISTORY (wri$_optstat_tab_history) &&table_owner..&&table_name.
PRO ~~~~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(h.analyzetime, '&&cs_datetime_full_format.') AS analyzetime,
       h.rowcnt,
       h.blkcnt,
       h.avgrln,
       h.samplesize
  FROM dba_objects o,
       wri$_optstat_tab_history h
 WHERE o.owner = '&&table_owner.'
   AND o.object_name = '&&table_name.' 
   AND o.object_type = 'TABLE'
   AND h.obj# = o.object_id
   AND h.analyzetime IS NOT NULL
 UNION
SELECT TO_CHAR(t.last_analyzed, '&&cs_datetime_full_format.') AS analyzetime,
       t.num_rows AS rowcnt,
       t.blocks AS blkcnt,
       t.avg_row_len AS avgrln,
       t.sample_size AS samplesize
  FROM dba_tables t
 WHERE t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.' 
 ORDER BY
       1
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&table_owner." "&&table_name."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--