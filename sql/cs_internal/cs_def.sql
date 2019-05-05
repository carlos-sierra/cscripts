DEF cs_stgtab_owner = 'c##iod';
DEF cs_stgtab_prefix = 'iod';
DEF cs_file_dir = '/tmp/';
DEF cs_timestamp_full_format = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
DEF cs_datetime_full_format = 'YYYY-MM-DD"T"HH24:MI:SS';
DEF cs_datetime_display_format = 'yyyy-mm-ddThh:mi:ss';
DEF cs_datetime_short_format = 'YYYY-MM-DD"T"HH24.MI.SS';
DEF cs_datetime_hh24_format = 'YYYY-MM-DD"T"HH24';
DEF cs_def_reference = 'DBPERF';
--DEF cs_reference = '';
DEF cs_reference_sanitized = '';
DEF cs_chart_option_explorer = '';
DEF cs_chart_option_pie = '//';
DEF cs_oem_colors_series = '';
DEF cs_oem_colors_slices = '//';
DEF cs_curve_type = '//';
--DEF cs_def_local_dir = '/Users/csierra/Issues/';
DEF cs_def_local_dir = '.';
DEF cs_local_dir = '';
--
DEF cs_region = '';
DEF cs_locale = '';
DEF cs_dbid = '';
DEF cs_db_name = '';
DEF cs_con_id = '';
DEF cs_con_name = '';
DEF cs_instance_number = '';
DEF cs_db_version = '';
DEF cs_host_name = '';
DEF cs_startup_time = '';
DEF cs_startup_days = '';
DEF cs_date_time = '';
DEF cs_file_date_time = '';
--
DEF cs_file_prefix = '';
DEF cs_file_name = '';
DEF cs_script_name = '';
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
--
COL cs_region NEW_V cs_region FOR A14 NOPRI;
COL cs_locale NEW_V cs_locale FOR A6 NOPRI;
COL cs_dbid NEW_V cs_dbid FOR A12 NOPRI;
COL cs_db_name NEW_V cs_db_name FOR A9 NOPRI;
COL cs_db_open_mode NEW_V cs_db_open_mode FOR A10 NOPRI;
COL cs_con_id NEW_V cs_con_id FOR A4 NOPRI;
COL cs_con_name NEW_V cs_con_name FOR A30 NOPRI;
COL cs_current_schema NEW_V cs_current_schema FOR A30 NOPRI;
COL cs_pdb_open_mode NEW_V cs_pdb_open_mode FOR A10 NOPRI;
COL cs_instance_number NEW_V cs_instance_number FOR A1 NOPRI;
COL cs_num_cpu_cores NEW_V cs_num_cpu_cores FOR A3 NOPRI;
COL cs_db_version NEW_V cs_db_version FOR A17 NOPRI;
COL cs_host_name NEW_V cs_host_name FOR A64 NOPRI;
COL cs_startup_time NEW_V cs_startup_time FOR A19 NOPRI;
COL cs_startup_days NEW_V cs_startup_days FOR A5 NOPRI;
COL cs_date_time NEW_V cs_date_time FOR A19 NOPRI;
COL cs_file_date_time NEW_V cs_file_date_time FOR A15 NOPRI;
COL cs_easy_connect_string NEW_V cs_easy_connect_string FOR A132 NOPRI;
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
VAR cs_signature NUMBER;
VAR cs_sql_text CLOB;
--
SELECT UPPER(SUBSTR(i.host_name,INSTR(i.host_name,'.',-1)+1)) cs_region,
       CASE
       WHEN d.name = 'KIEV01' OR d.name LIKE CHR(37)||'RG' THEN 'RGN'
       WHEN UPPER(SUBSTR(i.host_name,INSTR(i.host_name,'.',-1)+1)) = 'R2' AND d.name IN ('KIEV02', 'KIEV1R2') THEN 'RGN'
       ELSE UPPER(SUBSTR(i.host_name,INSTR(i.host_name,'.',-1,2)+1,INSTR(i.host_name,'.',-1)-INSTR(i.host_name,'.',-1,2)-1))
       END cs_locale,
       TRIM(TO_CHAR(d.dbid)) cs_dbid,
       d.name cs_db_name,
       d.open_mode cs_db_open_mode,
       SYS_CONTEXT('USERENV', 'CON_ID') cs_con_id,
       SYS_CONTEXT('USERENV', 'CON_NAME') cs_con_name,
       SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') cs_current_schema,
       c.open_mode cs_pdb_open_mode,
       TRIM(TO_CHAR(i.instance_number)) cs_instance_number,
       i.version cs_db_version,
       i.host_name cs_host_name,
       TO_CHAR(i.startup_time, '&&cs_datetime_full_format.') cs_startup_time,
       TRIM(TO_CHAR(o.value)) cs_num_cpu_cores,
       TRIM(TO_CHAR(ROUND(SYSDATE - i.startup_time, 1), '990.0')) cs_startup_days,
       TRIM(TO_CHAR(SYSDATE , '&&cs_datetime_full_format.')) cs_date_time,
       TRIM(TO_CHAR(SYSDATE , '&&cs_datetime_short_format.')) cs_file_date_time
  FROM v$database d, v$instance i, v$containers c, v$osstat o
 WHERE c.con_id = SYS_CONTEXT('USERENV', 'CON_ID')
   AND o.stat_name = 'NUM_CPU_CORES'
/
--
WITH 
service AS (
SELECT CASE WHEN ds.pdb = 'CDB$ROOT' THEN 'oradb' WHEN ts.name = 'KIEV' THEN 'kiev' ELSE 'orapdb' END type,
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
       s.type||'-'||
       CASE  
         WHEN s.pdb = 'CDB$ROOT' THEN REPLACE(LOWER(SYS_CONTEXT('USERENV','DB_NAME')),'_','-') 
         ELSE REPLACE(LOWER(s.pdb),'_','-')
       END||'.svc.'||       
       CASE REGEXP_COUNT(REPLACE(REPLACE(LOWER(SYS_CONTEXT('USERENV','DB_DOMAIN')),'regional.',''),'.regional',''),'\.')
         WHEN 0 THEN SUBSTR(i.host_name,INSTR(i.host_name,'.',-1,1)+1)
         ELSE SUBSTR(i.host_name,INSTR(i.host_name,'.',-1,2)+1)
       END||'/'||
       s.name cs_easy_connect_string
  FROM service s, v$instance i
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
--CLEAR SCREEN;
PRO
PRO Reference: (e.g. DBPERF-, DBPERFOCI-, IOD-, KIEV-, CAPA-, CHANGE-) 
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