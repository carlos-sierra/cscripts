----------------------------------------------------------------------------------------
--
-- File name:   cs_table_mod_report.sql
--
-- Purpose:     Table Modification History (INS, DEL and UPD) for given Table (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/03/18
--
-- Usage:       Execute connected to PDB.
--
--              Enter Table when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_table_mod_report.sql
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
DEF cs_script_name = 'cs_table_mod_report';
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
COL inserts_per_sec FOR 999,990.000 HEA 'INSERTS|PER SEC';
COL updates_per_sec FOR 999,990.000 HEA 'UPDATES|PER SEC';
COL deletes_per_sec FOR 999,990.000 HEA 'DELETES|PER SEC';
COL growth_per_sec FOR 999,990.000 HEA 'GROWTH|PER SEC';
COL inserts FOR 999,999,990;
COL deletes FOR 999,999,990;
COL growth FOR 999,999,990;
COL updates FOR 999,999,990;
COL partition_name FOR A30;
BREAK ON REPORT;
COMPUTE AVG LABEL 'AVG' MAX LABEL 'MAX' OF inserts_per_sec updates_per_sec deletes_per_sec growth_per_sec inserts deletes growth updates ON REPORT;
--
SELECT timestamp,
       ROUND(inserts / ((timestamp - last_analyzed) * 24 * 60 * 60), 3) AS inserts_per_sec,
       ROUND(deletes / ((timestamp - last_analyzed) * 24 * 60 * 60), 3) AS deletes_per_sec,
       ROUND((inserts - deletes) / ((timestamp - last_analyzed) * 24 * 60 * 60), 3) AS growth_per_sec,
       ROUND(updates / ((timestamp - last_analyzed) * 24 * 60 * 60), 3) AS updates_per_sec,
       inserts,
       deletes,
       inserts - deletes AS growth,
       updates,
       partition_name
  FROM &&cs_tools_schema..dbc_tab_modifications
 WHERE pdb_name = '&&cs_con_name.'
   AND owner = '&&table_owner.'
   AND table_name = '&&table_name.'
   AND timestamp BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND inserts + updates + deletes >= 0
   AND timestamp - last_analyzed > 0
 ORDER BY
       timestamp, partition_name
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