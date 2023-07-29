DEF iod_user = 'C##IOD';
DEF odis_user = 'ADMIN';
--
COL ampersand NEW_V ampersand NOPRI;
COL double_ampersand NEW_V double_ampersand NOPRI;
SELECT CHR(38) AS ampersand, CHR(38)||CHR(38) AS double_ampersand FROM DUAL;
DEF hints_text = "FIRST_ROWS(1)";
DEF hints_text = "FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')";
DEF cs_file_dir = '/tmp/';
DEF cs_temp_dir = '/u01/app/oracle/tools/tmp';
DEF cs_timestamp_full_format = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
DEF cs_datetime_full_format = 'YYYY-MM-DD"T"HH24:MI:SS';
DEF cs_datetime_display_format = 'yyyy-mm-ddThh:mi:ss';
DEF cs_datetime_short_format = 'YYYY-MM-DD"T"HH24.MI.SS';
DEF cs_datetime_hh24_format = 'YYYY-MM-DD"T"HH24';
DEF cs_datetime_dd_format = 'YYYY-MM-DD';
DEF cs_datetime_dense_format = 'YYYYMMDD_HH24MISS';
DEF cs_me_top = '10';
DEF cs_me_last = '10';
DEF cs_me_days = '30';
DEF cs_aas_on_cpu_per_sql = '2.5';
DEF cs_cpu_ms_per_row = '0.500';
DEF cs_buffer_gets_per_row = '25';
DEF cs_disk_reads_per_row = '1';
DEF cs_min_rows_per_exec_cap = '10';
DEF cs_default_reference = 'NULL';
DEF cs_reference_sanitized = '';
DEF cs_awr_days = '7';
DEF cs_binds_days = '1';
DEF cs_sqlmon_top = '100';
DEF chart_foot_note_0 = 'Notes:';
DEF chart_foot_note_1 = '<br>1) Drag to Zoom, and right click to reset Chart.';
DEF is_stacked = "isStacked: true,";
DEF cs_legend_position = 'right';
DEF vaxis_baseline = "";
DEF vaxis_viewwindow = "";
DEF hAxis_maxValue = "";
DEF cs_hAxis_maxValue = "";
DEF hAxis_maxValue_forecast = '0.375';
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
DEF cs_chart_option_pointsize = '4';
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
DEF cs_other_acronym = '';
DEF cs_onsr = '';
DEF cs_dedicated = '';
DEF cs_odis = '';
DEF cs_skip = '';
DEF cs_dbid = '';
DEF cs_db_name = '';
DEF cs_db_name_u = '';
DEF cs_mysid = '';
DEF cs_con_id = '';
DEF cs_con_name = '';
DEF cs_instance_number = '';
DEF cs_db_version = '';
DEF cs_host_name = '';
DEF cs_startup_time = '';
DEF cs_startup_days = '';
DEF cs_date_time = '';
DEF cs_file_date_time = '';
DEF cs_file_timestamp = '';
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
DEF spool_chart_1st_column = 'Date Column';
--
DEF cs_min_snap_id = '';
DEF cs_min_snap_end_time = '';
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
DEF cs_sql_hv = '';
--
DEF cs_sample_time_from = '';
DEF cs_sample_time_to = '';
-- 
-- [{AUTO}|MANUAL]
DEF cs_snap_type = 'AUTO';
-- [{-666}|sid]
DEF cs_sid = '-666';
--
DEF pdb_creation = '';
--
COL cs_realm NEW_V cs_realm FOR A3 NOPRI;
COL cs_region NEW_V cs_region FOR A14 NOPRI;
COL cs_rgn NEW_V cs_rgn FOR A3 NOPRI;
COL cs_locale NEW_V cs_locale FOR A6 NOPRI;
COL cs_other_acronym NEW_V cs_other_acronym FOR A8 NOPRI;
COL cs_onsr NEW_V cs_onsr FOR A1 NOPRI;
COL cs_dedicated NEW_V cs_dedicated FOR A1 NOPRI;
COL cs_dbid NEW_V cs_dbid FOR A12 NOPRI;
COL cs_db_name NEW_V cs_db_name FOR A9 NOPRI;
COL cs_db_name_u NEW_V cs_db_name_u FOR A9 NOPRI;
COL cs_db_open_mode NEW_V cs_db_open_mode FOR A10 NOPRI;
COL cs_con_id NEW_V cs_con_id FOR A4 NOPRI;
COL cs_mysid NEW_V cs_mysid NOPRI;
COL cs_con_name NEW_V cs_con_name FOR A30 NOPRI;
COL cs_current_schema NEW_V cs_current_schema FOR A30 NOPRI;
COL cs_oracle_home NEW_V cs_oracle_home NOPRI;
COL cs_pdb_open_mode NEW_V cs_pdb_open_mode FOR A10 NOPRI;
COL cs_instance_number NEW_V cs_instance_number FOR A1 NOPRI;
COL cs_cpu_util_perc NEW_V cs_cpu_util_perc FOR A6 NOPRI;
COL cs_cpu_load NEW_V cs_cpu_load FOR A3 NOPRI;
COL cs_num_cpu_cores NEW_V cs_num_cpu_cores FOR A3 NOPRI;
COL cs_num_cpus NEW_V cs_num_cpus FOR A3 NOPRI;
COL cs_cpu_count NEW_V cs_cpu_count FOR A3 NOPRI;
DEF cs_allotted_cpu = '?';
COL cs_allotted_cpu NEW_V cs_allotted_cpu FOR A5 NOPRI;
DEF cs_resource_manager_plan = '?';
COL cs_resource_manager_plan NEW_V cs_resource_manager_plan FOR A30 NOPRI;
COL cs_db_version NEW_V cs_db_version FOR A17 NOPRI;
COL cs_startup_time NEW_V cs_startup_time FOR A19 NOPRI;
COL cs_startup_days NEW_V cs_startup_days FOR A5 NOPRI;
COL cs_date_time NEW_V cs_date_time FOR A19 NOPRI;
COL cs_file_date_time NEW_V cs_file_date_time FOR A19 NOPRI;
COL cs_file_timestamp NEW_V cs_file_timestamp FOR A15 NOPRI;
COL cs_easy_connect_string NEW_V cs_easy_connect_string FOR A132 NOPRI;
COL cs_containers_count NEW_V cs_containers_count NOPRI;
COL cs_cdb_availability_perc NEW_V cs_cdb_availability_perc FOR A3 NOPRI;
--
COL cs_file_prefix NEW_V cs_file_prefix NOPRI;
COL cs_file_name NEW_V cs_file_name NOPRI;
COL cs_script_name NEW_V cs_script_name NOPRI;
--
COL cs_min_snap_id NEW_V cs_min_snap_id FOR A6 NOPRI;
COL cs_min_snap_end_time NEW_V cs_min_snap_end_time FOR A19 NOPRI;
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
VAR cs_begin_total_time NUMBER;
VAR cs_begin_elapsed_time NUMBER;
EXEC :cs_begin_total_time := DBMS_UTILITY.get_time;
DEF cs_total_time = '';
DEF cs_elapsed_time = '';
COL cs_total_time NEW_V cs_total_time NOPRI;
COL cs_elapsed_time NEW_V cs_elapsed_time NOPRI;
--
VAR cs_signature NUMBER;
VAR cs_sql_text CLOB;
VAR cs_zapper_managed_sql_banner CLOB;
VAR kiev_metadata_date VARCHAR2(30);
--
SET TERM OFF;
--
SELECT SYS_CONTEXT('USERENV', 'SID') AS cs_mysid,
       SYS_CONTEXT('USERENV', 'CON_ID') AS cs_con_id,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name,
       SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS cs_current_schema,
       SYS_CONTEXT('USERENV', 'ORACLE_HOME') AS cs_oracle_home,
       TRIM(TO_CHAR(SYSDATE , '&&cs_datetime_full_format.')) AS cs_date_time,
       TRIM(TO_CHAR(SYSDATE , '&&cs_datetime_short_format.')) AS cs_file_date_time,
       TRIM(TO_CHAR(SYSDATE , '&&cs_datetime_dense_format.')) AS cs_file_timestamp
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
COL cs_host_name NEW_V cs_host_name FOR A64 NOPRI;
COL cs_odis NEW_V cs_odis FOR A1 NOPRI;
SELECT TRIM(TO_CHAR(i.instance_number)) AS cs_instance_number,
       i.version AS cs_db_version,
       NVL(i.host_name, 'HOSTNAME') AS cs_host_name,
       CASE WHEN i.host_name IS NULL THEN 'Y' ELSE 'N' END AS cs_odis,
       TO_CHAR(i.startup_time, '&&cs_datetime_full_format.') AS cs_startup_time,
       TRIM(TO_CHAR(ROUND(SYSDATE - i.startup_time, 1), '990.0')) AS cs_startup_days
  FROM v$instance i
/
--
COL cs_skip NEW_V cs_skip FOR A2 NOPRI;
COL list_sqlbaseline_script NEW_V list_sqlbaseline_script NOPRI;
COL list_dg_members_script NEW_V list_dg_members_script NOPRI;
COL cs_set_container_to_cdb_root NEW_V cs_set_container_to_cdb_root NOPRI;
COL cs_set_container_to_curr_pdb NEW_V cs_set_container_to_curr_pdb NOPRI;
COL cs_tools_schema NEW_V cs_tools_schema NOPRI;
COL cs_stgtab_owner NEW_V cs_stgtab_owner NOPRI;
COL cs_stgtab_prefix NEW_V cs_stgtab_prefix NOPRI;
COL cs_spbl_create_pre NEW_V cs_spbl_create_pre NOPRI;
COL cs_spbl_create_post NEW_V cs_spbl_create_post NOPRI;
COL cs_spbl_validate NEW_V cs_spbl_validate NOPRI;
COL cs_list_cbo_hints NEW_V cs_list_cbo_hints NOPRI;
COL cs_list_cbo_hints_b NEW_V cs_list_cbo_hints_b NOPRI;
COL cs_zapper_managed NEW_V cs_zapper_managed NOPRI;
DEF cs_zapper_managed_sql = 'N';
--
SELECT CASE WHEN '&&cs_odis.' = 'Y' THEN '--' END AS cs_skip,
       CASE WHEN '&&cs_odis.' = 'Y' THEN 'cs_spbl_internal_list_simple.sql' ELSE 'cs_spbl_internal_list_debug.sql' END AS list_sqlbaseline_script,
       CASE WHEN '&&cs_odis.' = 'Y' THEN 'cs_null.sql' ELSE 'cs_internal_list_dg_members.sql' END AS list_dg_members_script,
       CASE WHEN '&&cs_odis.' = 'Y' THEN 'cs_null.sql' ELSE 'cs_set_container_to_cdb_root.sql' END AS cs_set_container_to_cdb_root,
       CASE WHEN '&&cs_odis.' = 'Y' THEN 'cs_null.sql' ELSE 'cs_set_container_to_curr_pdb.sql' END AS cs_set_container_to_curr_pdb,
       CASE WHEN '&&cs_odis.' = 'Y' THEN '&&odis_user.' ELSE '&&iod_user.' END AS cs_tools_schema,
       CASE WHEN '&&cs_odis.' = 'Y' THEN '&&odis_user.' ELSE '&&iod_user.' END AS cs_stgtab_owner,
       CASE WHEN '&&cs_odis.' = 'Y' THEN 'odis' ELSE 'iod' END AS cs_stgtab_prefix,
       CASE WHEN '&&cs_odis.' = 'Y' THEN 'cs_null.sql' ELSE 'cs_spbl_create_pre.sql' END AS cs_spbl_create_pre,
       CASE WHEN '&&cs_odis.' = 'Y' THEN 'cs_null.sql' ELSE 'cs_spbl_create_post.sql' END AS cs_spbl_create_post,
       CASE WHEN '&&cs_odis.' = 'Y' THEN 'cs_null.sql' ELSE 'cs_spbl_validate.sql' END AS cs_spbl_validate,
       CASE WHEN '&&cs_odis.' = 'Y' THEN 'cs_null.sql' ELSE 'cs_list_cbo_hints.sql' END AS cs_list_cbo_hints,
       CASE WHEN '&&cs_odis.' = 'Y' THEN 'cs_null.sql' ELSE 'cs_list_cbo_hints_b.sql' END AS cs_list_cbo_hints_b,
       CASE WHEN '&&cs_odis.' = 'Y' THEN 'cs_null.sql' ELSE 'cs_zapper_managed.sql' END AS cs_zapper_managed
  FROM DUAL
/
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
SELECT i.version_full AS cs_db_version -- 19c
  FROM v$instance i
/
--
SELECT c.open_mode AS cs_pdb_open_mode
  FROM v$containers c
 WHERE c.con_id = SYS_CONTEXT('USERENV', 'CON_ID')
/
--
SELECT TRIM(TO_CHAR(ROUND(100 * os.busy_time / (os.busy_time + os.idle_time), 1), '990.0'))||'%' AS cs_cpu_util_perc
FROM (
SELECT NULLIF(GREATEST(busy_t2.value - busy_t1.value, 0), 0) AS busy_time, NULLIF(GREATEST(idle_t2.value - idle_t1.value, 0), 0) AS idle_time
FROM
(SELECT value FROM dba_hist_osstat WHERE stat_name = 'BUSY_TIME' ORDER BY snap_id DESC NULLS LAST FETCH FIRST 1 ROW ONLY) busy_t1,
(SELECT value FROM dba_hist_osstat WHERE stat_name = 'IDLE_TIME' ORDER BY snap_id DESC NULLS LAST FETCH FIRST 1 ROW ONLY) idle_t1,
(SELECT value FROM v$osstat WHERE stat_name = 'BUSY_TIME') busy_t2,
(SELECT value FROM v$osstat WHERE stat_name = 'IDLE_TIME') idle_t2
) os
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
DEF cs_scope_1 = '';
DEF cs_sqlstat_days = '61';
@@cs_sample_time_boundaries.sql
@@cs_snap_id_from_and_to.sql
--
/****************************************************************************************/
--
ALTER SESSION SET container = CDB$ROOT;
--
SELECT 'CONTAINERS:'||TRIM(TO_CHAR(COUNT(*))) AS cs_containers_count FROM v$containers WHERE con_id > 2 AND open_mode = 'READ WRITE'
/
--
SELECT TO_CHAR(ROUND(100 * &&cs_tools_schema..PDB_CONFIG.get_cdb_availability), 'FM990') AS cs_cdb_availability_perc FROM DUAL
/
--
DEF cs_region = 'UNKNOWN_REGION';
SELECT CASE WHEN '&&cs_host_name.' = 'HOSTNAME' THEN 'UNKNOWN_REGION' ELSE &&cs_tools_schema..IOD_META_AUX.get_region('&&cs_host_name.') END AS cs_region FROM DUAL
/
--
SELECT REPLACE(&&cs_tools_schema..IOD_META_AUX.get_realm('&&cs_region.'), '?', 'X') AS cs_realm, REPLACE(&&cs_tools_schema..IOD_META_AUX.get_region_acronym('&&cs_region.'), '?', 'X') AS cs_rgn FROM DUAL
/
--
SELECT REPLACE(&&cs_tools_schema..IOD_META_AUX.get_other_acronym('&&cs_region.'), '?', 'X') AS cs_other_acronym, REPLACE(&&cs_tools_schema..IOD_META_AUX.get_onsr('&&cs_region.'), '?', 'X') AS cs_onsr, REPLACE(&&cs_tools_schema..IOD_META_AUX.get_dedicated('&&cs_region.'), '?', 'X') AS cs_dedicated FROM DUAL
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
       WHEN '&&cs_con_name.' = 'CDB$ROOT' THEN '&&cs_cpu_count. (SAME AS CPU_COUNT)' 
       WHEN r.utilization_limit IS NULL OR '&&cs_cpu_count.' IS NULL THEN '?' 
       ELSE TRIM(TO_CHAR(ROUND(r.utilization_limit * TO_NUMBER('&&cs_cpu_count.') / 100, 1), '990.0'))||'('||r.utilization_limit||'% OF CPU_COUNT)' END AS cs_allotted_cpu
  FROM v$parameter p, dba_cdb_rsrc_plan_directives r
 WHERE p.name = 'resource_manager_plan'
   AND r.directive_type(+) = 'PDB'
   AND r.plan(+) = REPLACE(p.value, 'FORCE:')
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
   AND r.plan(+) = REPLACE(p.value, 'FORCE:')
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
DEF cs_avg_running_sessions_cdb = '?';
COL cs_avg_running_sessions_cdb NEW_V cs_avg_running_sessions_cdb NOPRI;
SELECT TRIM(TO_CHAR(ROUND(avg_running_sessions))) AS cs_avg_running_sessions_cdb FROM (
SELECT end_time, SUM(avg_running_sessions) AS avg_running_sessions, ROW_NUMBER() OVER (ORDER BY end_time DESC) AS rn 
FROM &&cs_tools_schema..dbc_rsrcmgrmetric_history 
WHERE /*consumer_group_name = 'OTHER_GROUPS' AND*/ end_time > SYSDATE - (1/24) 
GROUP BY end_time
) WHERE rn = 1
/
DEF cs_avg_running_sessions_pdb = '?';
COL cs_avg_running_sessions_pdb NEW_V cs_avg_running_sessions_pdb NOPRI;
SELECT TRIM(TO_CHAR(ROUND(avg_running_sessions))) AS cs_avg_running_sessions_pdb FROM (
SELECT end_time, SUM(avg_running_sessions) AS avg_running_sessions, ROW_NUMBER() OVER (ORDER BY end_time DESC) AS rn 
FROM &&cs_tools_schema..dbc_rsrcmgrmetric_history 
WHERE pdb_name = '&&cs_con_name.' AND /*consumer_group_name = 'OTHER_GROUPS' AND*/ end_time > SYSDATE - (1/24) 
GROUP BY end_time
) WHERE rn = 1
/
-- replaced due to performance concerns (it would take up to 8 seconds in some environments)
-- SELECT TRIM(TO_CHAR(ROUND(SUM(avg_running_sessions)))) AS cs_avg_running_sessions_cdb FROM v$rsrcmgrmetric WHERE consumer_group_name = 'OTHER_GROUPS'
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
BEGIN
  FOR i IN (SELECT owner, table_name FROM dba_tables WHERE owner = UPPER('&&cs_tools_schema.') AND table_name = UPPER('kiev_ind_columns'))
  LOOP
    EXECUTE IMMEDIATE 'SELECT TO_CHAR(timestamp, ''&&cs_timestamp_full_format.'') AS kiev_metadata_date FROM '||i.owner||'.'||i.table_name||' WHERE ROWNUM = 1' INTO :kiev_metadata_date;
  END LOOP;
END;
/
COL kiev_metadata_date NEW_V kiev_metadata_date NOPRI;
SELECT :kiev_metadata_date AS kiev_metadata_date FROM DUAL
/ 
-- 
-- time when host was rebooted (executed from CD$ROOT only)
DEF cs_system_boot_time = '';
COL cs_system_boot_time NEW_V cs_system_boot_time FOR A19 NOPRI;
SELECT TO_CHAR(MAX(system_boot_time), '&&cs_datetime_full_format.') AS cs_system_boot_time FROM &&cs_tools_schema..dbc_system;
--
-- phonebook, compartment_id and kiev_data_store
DEF cs_phonebook_pdb = '';
DEF cs_compartment_id_pdb = '';
DEF cs_kiev_store_name = '';
--
COL cs_phonebook_pdb NEW_V cs_phonebook_pdb FOR A256 NOPRI;
COL cs_compartment_id_pdb NEW_V cs_compartment_id_pdb FOR A128 NOPRI;
COL cs_kiev_store_name NEW_V cs_kiev_store_name FOR A128 NOPRI;
--
-- executed from CD$ROOT only
SELECT NVL(phonebook, 'UNKNOWN') AS cs_phonebook_pdb, -- out of horizon (oc1) else from kiev/dbpcs metadata
       NVL(compartment_id, 'UNKNOWN') AS cs_compartment_id_pdb, -- out of kiev or dbcps metadata
       NVL(kiev_store_name, 'N/A') AS cs_kiev_store_name -- null for kiev multi-schema pdbs
  FROM &&cs_tools_schema..dbc_pdb_metadata_v
 WHERE pdb_name = '&&cs_con_name.' -- from SYS_CONTEXT('USERENV', 'CON_NAME') when connected into PDB
/
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
/****************************************************************************************/
--
DEF cs_easy_connect_string = 'CONNECT_STRING';
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
       CASE
       WHEN '&&cs_host_name.' = 'HOSTNAME' THEN 'CONNECT_STRING'
       ELSE
          s.type||'-'||
          CASE  
            WHEN s.pdb = 'CDB$ROOT' THEN REPLACE(LOWER(SYS_CONTEXT('USERENV','DB_NAME')),'_','-') 
            ELSE REPLACE(LOWER(s.pdb),'_','-')
          END||'.svc.'||       
          CASE 
            WHEN REGEXP_COUNT(REPLACE(REPLACE(LOWER(SYS_CONTEXT('USERENV','DB_DOMAIN')),'regional.',''),'.regional',''),'\.') = 0 THEN SUBSTR('&&cs_host_name.',INSTR('&&cs_host_name.','.',-1,1)+1)
            ELSE SUBSTR('&&cs_host_name.',INSTR('&&cs_host_name.','.',-1,2)+1)
          END||'/'||
          s.name 
       END cs_easy_connect_string
  FROM service s
/
--
SELECT TRIM(TO_CHAR(snap_id)) cs_min_snap_id,
       TRIM(TO_CHAR(end_interval_time, '&&cs_datetime_full_format.')) cs_min_snap_end_time
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
 ORDER BY
       snap_id ASC
 FETCH FIRST 1 ROW ONLY
/
--
@@cs_last_snap.sql
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
SELECT owner cs_kiev_owner FROM dba_tables WHERE table_name = 'KIEVDATASTOREMETADATA' AND num_rows > 0 ORDER BY num_rows
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
@@/tmp/cs_default_reference.sql
SET TERM ON;
--CLEAR SCREEN;
PRO
PRO Reference: [{&&cs_default_reference.}|DBPERF-nnnnn|IOD-nnnnn|NOC-nnnnn|PROJECT-nnnnn]
PRO Enter Reference: &&cs_reference.
COL cs_reference NEW_V cs_reference NOPRI;
SELECT UPPER(REPLACE(COALESCE('&&cs_reference.', '&&cs_default_reference.'), ' ')) AS cs_reference FROM DUAL;
COL cs_reference_sanitized NEW_V cs_reference_sanitized NOPRI;
SELECT TRANSLATE('&&cs_reference.', '*()@#$[]{}|/\".,?<>''', '___________________') cs_reference_sanitized FROM DUAL;
--
DEF target_local_directory = '&&cs_def_local_dir.';
COL cs_local_dir NEW_V cs_local_dir NOPRI;
SELECT NVL('&&target_local_directory.', '&&cs_def_local_dir.') cs_local_dir FROM DUAL;
--
DEF cs_extended_reference = '';
COL cs_extended_reference NEW_V cs_extended_reference NOPRI;
SELECT '&&cs_reference.'||
       CASE '&&cs_odis.' WHEN 'N' THEN ' &&cs_realm. &&cs_region. &&cs_rgn. &&cs_locale.' END||
       ' &&cs_db_name..&&cs_con_name.'||
       NVL2('&&cs_other_acronym.', ' &&cs_other_acronym.', NULL)||
       CASE '&&cs_odis.' WHEN 'Y' THEN ' ODIS' END||
       CASE '&&cs_onsr.' WHEN 'Y' THEN ' ONSR' END||
       CASE '&&cs_dedicated.' WHEN 'Y' THEN ' DEDICATED' END AS cs_extended_reference 
  FROM DUAL
/
SPO /tmp/cs_default_reference.sql;
PRO DEF cs_default_reference = "&&cs_reference.";
SPO OFF;
--
SET TERM OFF;
VAR who_am_i CLOB;
!who am i > /tmp/get_who_am_i.txt
get /tmp/get_who_am_i.txt
.
999999 ]'; END;;
0 BEGIN :who_am_i := q'[
/
DEF who_am_i = 'oracle';
COL who_am_i NEW_V who_am_i NOPRI;
SELECT REGEXP_SUBSTR(:who_am_i, '[a-z]+') AS who_am_i FROM DUAL
/
DEF engineer_info = '';
COL engineer_info NEW_V engineer_info NOPRI;
SELECT SUBSTR('&&who_am_i. '||SUBSTR(REPLACE('&&cs_reference.', ' '), 1, 30)||' &&cs_date_time.', 1, 64) AS engineer_info FROM DUAL
/
-- V$SESSION.CLIENT_INFO
EXEC DBMS_APPLICATION_INFO.set_client_info(client_info => '&&engineer_info.');
-- V$SESSION.CLIENT_IDENTIFIER V$ACTIVE_SESSION_HISTORY.CLIENT_ID DBA_HIST_ACTIVE_SESS_HISTORY.CLIENT_ID
EXEC DBMS_SESSION.set_identifier(client_id => '&&engineer_info.');
SET TERM ON;
