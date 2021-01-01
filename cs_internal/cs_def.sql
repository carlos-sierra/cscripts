DEF cs_stgtab_tablespace = 'IOD';
DEF cs_tools_schema = 'C##IOD';
DEF cs_stgtab_owner = '&&cs_tools_schema.';
DEF cs_stgtab_prefix = 'iod';
DEF cs_file_dir = '/tmp/';
DEF cs_temp_dir = '/u01/app/oracle/tools';
DEF cs_timestamp_full_format = 'YYYY-MM-DD"T"HH24:MI:SS.FF6';
DEF cs_datetime_full_format = 'YYYY-MM-DD"T"HH24:MI:SS';
DEF cs_datetime_display_format = 'yyyy-mm-ddThh:mi:ss';
DEF cs_datetime_short_format = 'YYYY-MM-DD"T"HH24.MI.SS';
DEF cs_datetime_hh24_format = 'YYYY-MM-DD"T"HH24';
DEF cs_datetime_dd_format = 'YYYY-MM-DD';
DEF cs_def_reference = 'oci_dbperf';
DEF cs_me_top = '10';
DEF cs_me_last = '10';
DEF cs_me_days = '30';
DEF cs_aas_on_cpu_per_sql = '2.5';
DEF cs_cpu_ms_per_row = '0.500';
DEF cs_buffer_gets_per_row = '25';
DEF cs_disk_reads_per_row = '1';
DEF cs_min_rows_per_exec_cap = '10';
DEF cs_reference_sanitized = '';
DEF cs_sqlstat_days = '60';
DEF cs_awr_days = '7';
DEF cs_binds_days = '1';
DEF cs_sqlmon_top = '100';
DEF chart_foot_note_0 = 'Notes:';
DEF chart_foot_note_1 = '<br>1) Drag to Zoom, and right click to reset Chart.';
DEF is_stacked = "isStacked: true,";
DEF vaxis_baseline = "";
DEF vaxis_viewwindow = "";
DEF hAxis_maxValue = "";
DEF cs_hAxis_maxValue = "";
DEF hAxis_maxValue_forecast = '0.2';
-- [{linear}|polynomial|exponential|none]
DEF cs_trendlines_types = '[{none}|linear|polynomial|exponential]'
DEF cs_trendlines_type = 'none';
DEF cs_trendlines_series = "";
DEF cs_trendlines = "";
DEF cs_chart_width = '1200px';
DEF cs_chart_height = '500px';
DEF cs_chartarea_left = '90';
DEF cs_chartarea_top = '75';
DEF cs_chartarea_width = '75%';
DEF cs_chartarea_height = '70%';
DEF cs_chart_option_explorer = '';
DEF cs_chart_option_pie = '//';
-- cs_chart_option_focustarget [{datum}|category]
DEF cs_chart_option_focustarget = 'datum';
DEF cs_chart_pie_slice_text = "// pieSliceText: 'percentage',";
DEF cs_oem_colors_series = '';
DEF cs_oem_colors_slices = '//';
DEF cs_curve_type = '//';
DEF cs_def_local_dir = '.';
DEF cs_local_dir = '';
--
DEF cs_realm = '';
DEF cs_rgn = '';
DEF cs_region = '';
DEF cs_locale = '';
DEF cs_dbid = '';
DEF cs_db_name = '';
DEF cs_db_name_u = '';
DEF cs_con_id = '';
DEF cs_con_name = '';
DEF cs_instance_number = '';
DEF cs_db_version = '';
DEF cs_host_name = '';
DEF cs_startup_time = '';
DEF cs_startup_days = '';
DEF cs_date_time = '';
DEF cs_file_date_time = '';
DEF cs_current_schema = '';
DEF cs_containers_count = '';
DEF cs_cdb_availability_perc = '';
DEF cs_host_shape = '';
DEF cs_disk_config = '';
--
DEF cs_file_prefix = '';
DEF cs_file_name = '';
DEF cs_script_name = '';
DEF cs_script_acronym = '';
DEF spool_id_chart_footer_script = 'cs_null.sql';
--
DEF cs_max_snap_id = '';
DEF cs_max_snap_end_time = '';
DEF cs_last_snap_mins = '';
DEF cs_snap_interval_seconds = '';
DEF cs_ash_interval_ms = '';
--
DEF cs_1h_snap_id = '';
DEF cs_1d_snap_id = '';
DEF cs_7d_snap_id = '';
DEF cs_30d_snap_id = '';
--
DEF cs_sql_id = '';
DEF cs_signature = '';
DEF cs_sql_handle = '';
DEF cs_plan_hash_value = '';
DEF cs_application_category = '';
--
DEF cs_sample_time_from = '';
DEF cs_sample_time_to = '';
-- 
DEF pdb_creation = '';
--
COL cs_realm NEW_V cs_realm FOR A3 NOPRI;
COL cs_region NEW_V cs_region FOR A14 NOPRI;
COL cs_rgn NEW_V cs_rgn FOR A3 NOPRI;
COL cs_locale NEW_V cs_locale FOR A6 NOPRI;
COL cs_dbid NEW_V cs_dbid FOR A12 NOPRI;
COL cs_db_name NEW_V cs_db_name FOR A9 NOPRI;
COL cs_db_name_u NEW_V cs_db_name_u FOR A9 NOPRI;
COL cs_db_open_mode NEW_V cs_db_open_mode FOR A10 NOPRI;
COL cs_con_id NEW_V cs_con_id FOR A4 NOPRI;
COL cs_con_name NEW_V cs_con_name FOR A30 NOPRI;
COL cs_current_schema NEW_V cs_current_schema FOR A30 NOPRI;
COL cs_pdb_open_mode NEW_V cs_pdb_open_mode FOR A10 NOPRI;
COL cs_instance_number NEW_V cs_instance_number FOR A1 NOPRI;
COL cs_cpu_load NEW_V cs_cpu_load FOR A3 NOPRI;
COL cs_num_cpu_cores NEW_V cs_num_cpu_cores FOR A3 NOPRI;
COL cs_num_cpus NEW_V cs_num_cpus FOR A3 NOPRI;
COL cs_cpu_count NEW_V cs_cpu_count FOR A3 NOPRI;
DEF cs_allotted_cpu = '?';
COL cs_allotted_cpu NEW_V cs_allotted_cpu FOR A5 NOPRI;
DEF cs_resource_manager_plan = '?';
COL cs_resource_manager_plan NEW_V cs_resource_manager_plan FOR A30 NOPRI;
COL cs_db_version NEW_V cs_db_version FOR A17 NOPRI;
COL cs_host_name NEW_V cs_host_name FOR A64 NOPRI;
COL cs_startup_time NEW_V cs_startup_time FOR A19 NOPRI;
COL cs_startup_days NEW_V cs_startup_days FOR A5 NOPRI;
COL cs_date_time NEW_V cs_date_time FOR A19 NOPRI;
COL cs_file_date_time NEW_V cs_file_date_time FOR A15 NOPRI;
COL cs_easy_connect_string NEW_V cs_easy_connect_string FOR A132 NOPRI;
COL cs_containers_count NEW_V cs_containers_count NOPRI;
COL cs_cdb_availability_perc NEW_V cs_cdb_availability_perc FOR A3 NOPRI;
--
COL cs_file_prefix NEW_V cs_file_prefix NOPRI;
COL cs_file_name NEW_V cs_file_name NOPRI;
COL cs_script_name NEW_V cs_script_name NOPRI;
--
COL cs_max_snap_id NEW_V cs_max_snap_id FOR A6 NOPRI;
COL cs_max_snap_end_time NEW_V cs_max_snap_end_time FOR A19 NOPRI;
COL cs_last_snap_mins NEW_V cs_last_snap_mins FOR A7 NOPRI;
COL cs_snap_interval_seconds NEW_V cs_snap_interval_seconds FOR A4 NOPRI;
COL cs_ash_interval_ms NEW_V cs_ash_interval_ms FOR A5 NOPRI;
--
COL cs_1h_snap_id NEW_V cs_1h_snap_id FOR A6 NOPRI;
COL cs_1d_snap_id NEW_V cs_1d_snap_id FOR A6 NOPRI;
COL cs_7d_snap_id NEW_V cs_7d_snap_id FOR A6 NOPRI;
COL cs_30d_snap_id NEW_V cs_30d_snap_id FOR A6 NOPRI;
COL cs_startup_snap_id NEW_V cs_startup_snap_id FOR A6 NOPRI;
--
COL cs_signature NEW_V cs_signature FOR A20 NOPRI;
COL cs_sql_handle NEW_V cs_sql_handle FOR A20 NOPRI;
--
COL stgtab_sqlbaseline_script NEW_V stgtab_sqlbaseline_script NOPRI;
COL stgtab_sqlprofile_script NEW_V stgtab_sqlprofile_script NOPRI;
COL stgtab_sqlpatch_script NEW_V stgtab_sqlpatch_script NOPRI;
COL pdb_creation NEW_V pdb_creation NOPRI;
--
VAR cs_signature NUMBER;
VAR cs_sql_text CLOB;
--
SET TERM OFF;
--
SELECT CASE WHEN COUNT(*) > 0 THEN 'cs_spbl_internal_stgtab_baseline.sql' ELSE 'cs_null.sql' END AS stgtab_sqlbaseline_script
  FROM dba_tables
 WHERE owner = UPPER('&&cs_stgtab_owner.')
   AND table_name = UPPER('&&cs_stgtab_prefix._stgtab_baseline')
/
--
SELECT CASE WHEN COUNT(*) > 0 THEN 'cs_sprf_internal_stgtab_sqlprofile.sql' ELSE 'cs_null.sql' END AS stgtab_sqlprofile_script
  FROM dba_tables
 WHERE owner = UPPER('&&cs_stgtab_owner.')
   AND table_name = UPPER('&&cs_stgtab_prefix._stgtab_sqlprof')
/
--
SELECT CASE WHEN COUNT(*) > 0 THEN 'cs_spch_internal_stgtab_sqlpatch.sql' ELSE 'cs_null.sql' END AS stgtab_sqlpatch_script
  FROM dba_tables
 WHERE owner = UPPER('&&cs_stgtab_owner.')
   AND table_name = UPPER('&&cs_stgtab_prefix._stgtab_sqlpatch')
/
--
SELECT SYS_CONTEXT('USERENV', 'CON_ID') AS cs_con_id,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name,
       SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS cs_current_schema,
       TRIM(TO_CHAR(SYSDATE , '&&cs_datetime_full_format.')) AS cs_date_time,
       TRIM(TO_CHAR(SYSDATE , '&&cs_datetime_short_format.')) AS cs_file_date_time
  FROM DUAL
/
--
SELECT TRIM(TO_CHAR(d.dbid)) AS cs_dbid,
       LOWER(d.name) AS cs_db_name,
       UPPER(d.name) AS cs_db_name_u,
       d.open_mode AS cs_db_open_mode
  FROM v$database d
/
--
SELECT TRIM(TO_CHAR(i.instance_number)) AS cs_instance_number,
       i.version AS cs_db_version,
       i.host_name AS cs_host_name,
       TO_CHAR(i.startup_time, '&&cs_datetime_full_format.') AS cs_startup_time,
       TRIM(TO_CHAR(ROUND(SYSDATE - i.startup_time, 1), '990.0')) AS cs_startup_days
  FROM v$instance i
/
--
SELECT c.open_mode AS cs_pdb_open_mode
  FROM v$containers c
 WHERE c.con_id = SYS_CONTEXT('USERENV', 'CON_ID')
/
--
SELECT TRIM(TO_CHAR(o.value)) AS cs_num_cpu_cores
  FROM v$osstat o
 WHERE o.stat_name = 'NUM_CPU_CORES'
/
--
SELECT TRIM(TO_CHAR(o2.value)) AS cs_num_cpus
  FROM v$osstat o2
 WHERE o2.stat_name = 'NUM_CPUS'
/
--
SELECT TRIM(TO_CHAR(ROUND(o3.value))) AS cs_cpu_load
  FROM v$osstat o3
 WHERE o3.stat_name = 'LOAD'
/
--
SELECT p.value AS cs_cpu_count
  FROM v$parameter p
 WHERE p.name = 'cpu_count'
/
--
SELECT TO_CHAR(h.op_timestamp, '&&cs_datetime_full_format') AS pdb_creation
  FROM dba_pdb_history h
 WHERE h.operation = 'CREATE'
/
--
COL dba_or_cdb NEW_V dba_or_cdb NOPRI;
SELECT CASE WHEN SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN 'cdb' ELSE 'dba' END AS dba_or_cdb FROM DUAL
/
--
COL cs_sample_time_from NEW_V cs_sample_time_from NOPRI;
COL cs_sample_time_to NEW_V cs_sample_time_to NOPRI;
SELECT TO_CHAR(SYSDATE - 7, '&&cs_datetime_full_format.') AS cs_sample_time_from, TO_CHAR(SYSDATE, '&&cs_datetime_full_format.') AS cs_sample_time_to FROM DUAL
/
--
/****************************************************************************************/
--
ALTER SESSION SET container = CDB$ROOT;
--
SELECT CASE WHEN COUNT(*) > 1 THEN 'CONTAINERS:'||TRIM(TO_CHAR(COUNT(*))) END AS cs_containers_count FROM v$containers
/
--
SELECT TO_CHAR(ROUND(100 * &&cs_tools_schema..PDB_CONFIG.get_cdb_availability), 'FM990') AS cs_cdb_availability_perc FROM DUAL
/
--
SELECT &&cs_tools_schema..IOD_META_AUX.get_region('&&cs_host_name.') AS cs_region FROM DUAL
/
--
SELECT &&cs_tools_schema..IOD_META_AUX.get_realm('&&cs_region.') AS cs_realm, &&cs_tools_schema..IOD_META_AUX.get_region_acronym('&&cs_region.') AS cs_rgn FROM DUAL
/
--
SELECT &&cs_tools_schema..IOD_META_AUX.get_locale(value) AS cs_locale FROM v$parameter WHERE name = 'db_domain'
/
--
COL zapper_19_actions_script NEW_V zapper_19_actions_script NOPRI;
SELECT CASE WHEN COUNT(*) > 0 THEN 'cs_zapper_19_actions.sql' ELSE 'cs_null.sql' END AS zapper_19_actions_script
  FROM dba_tables
 WHERE owner = UPPER('&&cs_stgtab_owner.')
   AND table_name = UPPER('zapper_log')
/
--
COL oem_me_sqlperf_script NEW_V oem_me_sqlperf_script NOPRI;
SELECT CASE WHEN COUNT(*) > 0 THEN 'cs_oem_me_sqlperf.sql' ELSE 'cs_null.sql' END AS oem_me_sqlperf_script
  FROM dba_tables
 WHERE owner = UPPER('&&cs_stgtab_owner.')
   AND table_name = UPPER('alerts_hist')
/
--
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ 
       r.plan AS cs_resource_manager_plan, 
       CASE 
       WHEN '&&cs_con_name.' = 'CDB$ROOT' THEN '&&cs_cpu_count.' 
       WHEN r.utilization_limit IS NULL OR '&&cs_cpu_count.' IS NULL THEN '?' 
       ELSE TRIM(TO_CHAR(ROUND(r.utilization_limit * TO_NUMBER('&&cs_cpu_count.') / 100, 1), '990.0'))||'('||r.utilization_limit||'%)' END AS cs_allotted_cpu
  FROM v$parameter p, dba_cdb_rsrc_plan_directives r
 WHERE p.name = 'resource_manager_plan'
   AND r.directive_type(+) = 'PDB'
   AND r.plan(+) = REPLACE(value, 'FORCE:')
   AND r.pluggable_database(+) = '&&cs_con_name.'
/
--
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ 
       COALESCE('&&cs_resource_manager_plan.', r.plan) AS cs_resource_manager_plan, 
       CASE 
       WHEN '&&cs_con_name.' = 'CDB$ROOT' THEN '&&cs_cpu_count.' 
       WHEN r.utilization_limit IS NULL OR '&&cs_cpu_count.' IS NULL THEN '?' 
       WHEN '&&cs_allotted_cpu.' <> '?' THEN '&&cs_allotted_cpu.'
       ELSE TRIM(TO_CHAR(ROUND(r.utilization_limit * TO_NUMBER('&&cs_cpu_count.') / 100, 1), '990.0'))||'('||r.utilization_limit||'% by Default)' END AS cs_allotted_cpu
  FROM v$parameter p, dba_cdb_rsrc_plan_directives r
 WHERE p.name = 'resource_manager_plan'
   AND r.directive_type(+) = 'DEFAULT_DIRECTIVE'
   AND r.plan(+) = REPLACE(value, 'FORCE:')
   AND r.pluggable_database(+) = 'ORA$DEFAULT_PDB_DIRECTIVE'
/
--
COL blackout_dates_script NEW_V blackout_dates_script NOPRI;
SELECT CASE WHEN COUNT(*) > 0 THEN 'cs_blackout_internal.sql' ELSE 'cs_null.sql' END AS blackout_dates_script
  FROM dba_tables
 WHERE owner = UPPER('&&cs_stgtab_owner.')
   AND table_name = 'BLACKOUT'
/
DEF cs_blackout_times = '';
@@&&blackout_dates_script.
--
DEF cs_avg_running_sessions = 'TBD';
COL cs_avg_running_sessions NEW_V cs_avg_running_sessions NOPRI;
SELECT TRIM(TO_CHAR(ROUND(avg_running_sessions))) AS cs_avg_running_sessions FROM (
SELECT end_time, SUM(avg_running_sessions) AS avg_running_sessions, ROW_NUMBER() OVER (ORDER BY end_time DESC) AS rn FROM &&cs_tools_schema..dbc_rsrcmgrmetric_history WHERE consumer_group_name = 'OTHER_GROUPS' AND end_time > SYSDATE - (1/24) GROUP BY end_time
) WHERE rn = 1
/
-- replaced due to performance concerns (it would take up to 8 seconds in some environments)
-- SELECT TRIM(TO_CHAR(ROUND(SUM(avg_running_sessions)))) AS cs_avg_running_sessions FROM v$rsrcmgrmetric WHERE consumer_group_name = 'OTHER_GROUPS'
-- /
--
COL cs_host_shape NEW_V cs_host_shape NOPRI;
COL cs_disk_config NEW_V cs_disk_config NOPRI;
SELECT 'SHAPE:'||host_shape AS cs_host_shape, 'DISK:'||disk_config AS cs_disk_config
  FROM &&cs_tools_schema..dbc_system
 ORDER BY
       timestamp DESC
FETCH FIRST 1 ROW ONLY
/
-- 
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
/****************************************************************************************/
--
WITH 
service AS (
SELECT /*+ MATERIALIZWE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       CASE WHEN ds.pdb = 'CDB$ROOT' THEN 'oradb' WHEN ts.name = 'KIEV' THEN 'kiev' ELSE 'orapdb' END type,
       ds.name||'.'||SYS_CONTEXT('USERENV','DB_DOMAIN') name, 
       vs.con_id, ds.pdb
  FROM cdb_services ds,
       v$active_services vs,
       v$tablespace ts
 WHERE 1 = 1
   AND ds.pdb = SYS_CONTEXT ('USERENV', 'CON_NAME')
   AND ds.name LIKE 's\_%' ESCAPE '\'
   AND ds.name NOT LIKE '%\_ro' ESCAPE '\'
   AND vs.con_name = ds.pdb
   AND vs.name = ds.name
   AND ts.con_id(+) = vs.con_id
   AND ts.name(+) = 'KIEV'
)
SELECT --s.pdb,
       --'jdbc:oracle:thin:@//'||
       s.type||'-'||
       CASE  
         WHEN s.pdb = 'CDB$ROOT' THEN REPLACE(LOWER(SYS_CONTEXT('USERENV','DB_NAME')),'_','-') 
         ELSE REPLACE(LOWER(s.pdb),'_','-')
       END||'.svc.'||       
       CASE REGEXP_COUNT(REPLACE(REPLACE(LOWER(SYS_CONTEXT('USERENV','DB_DOMAIN')),'regional.',''),'.regional',''),'\.')
         WHEN 0 THEN SUBSTR('&&cs_host_name.',INSTR('&&cs_host_name.','.',-1,1)+1)
         ELSE SUBSTR('&&cs_host_name.',INSTR('&&cs_host_name.','.',-1,2)+1)
       END||'/'||
       s.name cs_easy_connect_string
  FROM service s
/
--
SELECT TRIM(TO_CHAR(snap_id)) cs_max_snap_id,
       TRIM(TO_CHAR(end_interval_time, '&&cs_datetime_full_format.')) cs_max_snap_end_time,
       TRIM(TO_CHAR(ROUND((SYSDATE - CAST(end_interval_time AS DATE)) * 24 * 60, 1), '99990.0')) cs_last_snap_mins
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
--
SELECT TRIM(TO_CHAR((24 * 3600 * EXTRACT(day FROM snap_interval)) + (3600 * EXTRACT(hour FROM snap_interval)) + (60 * EXTRACT(minute FROM snap_interval)) + EXTRACT(second FROM snap_interval))) cs_snap_interval_seconds
  FROM dba_hist_wr_control
/
SELECT TRIM(TO_CHAR(sampling_interval)) cs_ash_interval_ms
  FROM v$ash_info
/
--
SELECT TRIM(TO_CHAR(MIN(snap_id))) cs_1h_snap_id
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND end_interval_time > SYSDATE - (1/24)
/
SELECT TRIM(TO_CHAR(MIN(snap_id))) cs_1d_snap_id
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND end_interval_time > SYSDATE - 1
/
SELECT TRIM(TO_CHAR(MIN(snap_id))) cs_7d_snap_id
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND end_interval_time > SYSDATE - 7
/
SELECT TRIM(TO_CHAR(MIN(snap_id))) cs_30d_snap_id
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND end_interval_time > SYSDATE - 30
/
SELECT TRIM(TO_CHAR(MIN(snap_id))) cs_startup_snap_id
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND begin_interval_time > TO_DATE('&&cs_startup_time.', '&&cs_datetime_full_format.')
/
--
DEF cs_kiev_owner = '';
COL cs_kiev_owner NEW_V cs_kiev_owner NOPRI;
SELECT owner cs_kiev_owner FROM dba_tables WHERE table_name = 'KIEVBUCKETS' AND num_rows > 0 ORDER BY num_rows
/
DEF cs_jason_value = '';
COL cs_jason_value NEW_V cs_jason_value NOPRI;
select JSON_VALUE(DATA, '$.transactorConfiguration.algorithmType') cs_jason_value
from &&cs_kiev_owner..kievdynamicconfiguration
where version=(select MAX(version) from &&cs_kiev_owner..kievdynamicconfiguration)
/
DEF cs_kiev_version = '';
COL cs_kiev_version NEW_V cs_kiev_version FOR A30 TRUNC NOPRI;
DEF cs_schema_name = '';
COL cs_schema_name NEW_V cs_schema_name FOR A30 TRUNC NOPRI;
SELECT CASE WHEN '&&cs_kiev_owner.' IS NULL THEN 'NOT_KIEV' ELSE NVL('&&cs_jason_value.', 'CLASSIC') END AS cs_kiev_version, NVL('&&cs_kiev_owner.', 'NOT_KIEV') AS cs_schema_name FROM DUAL
/
--
SET TERM ON;
--CLEAR SCREEN;
PRO
PRO Reference: (e.g. IOD-, DBPERF-, KIEV-, CHANGE-, DBPERFOCI-) 
PRO Enter Reference: &&cs_reference.
COL cs_reference NEW_V cs_reference NOPRI;
SELECT NVL('&&cs_reference.', '&&cs_def_reference.') cs_reference FROM DUAL;
COL cs_reference_sanitized NEW_V cs_reference_sanitized NOPRI;
SELECT TRANSLATE('&&cs_reference.', '*()@#$[]{}|/\".,?<>''', '___________________') cs_reference_sanitized FROM DUAL;
--
DEF target_local_directory = '&&cs_def_local_dir.';
COL cs_local_dir NEW_V cs_local_dir NOPRI;
SELECT NVL('&&target_local_directory.', '&&cs_def_local_dir.') cs_local_dir FROM DUAL;
--