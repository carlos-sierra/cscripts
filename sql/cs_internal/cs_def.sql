DEF cs_stgtab_owner = 'c##iod';
DEF cs_stgtab_prefix = 'iod';
DEF cs_file_dir = '/tmp/';
DEF cs_datetime_full_format = 'YYYY-MM-DD"T"HH24:MI:SS';
DEF cs_datetime_short_format = 'YYYYMMDD_HH24MISS';
DEF cs_def_reference = 'IOD';
DEF cs_reference = '';
DEF cs_reference_sanitized = '';
DEF cs_def_local_dir = '/Users/csierra/Issues/';
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
COL cs_con_id NEW_V cs_con_id FOR A4 NOPRI;
COL cs_con_name NEW_V cs_con_name FOR A30 NOPRI;
COL cs_instance_number NEW_V cs_instance_number FOR A1 NOPRI;
COL cs_num_cpu_cores NEW_V cs_num_cpu_cores FOR A3 NOPRI;
COL cs_db_version NEW_V cs_db_version FOR A17 NOPRI;
COL cs_host_name NEW_V cs_host_name FOR A64 NOPRI;
COL cs_startup_time NEW_V cs_startup_time FOR A19 NOPRI;
COL cs_startup_days NEW_V cs_startup_days FOR A5 NOPRI;
COL cs_date_time NEW_V cs_date_time FOR A19 NOPRI;
COL cs_file_date_time NEW_V cs_file_date_time FOR A15 NOPRI;
--
COL cs_file_prefix NEW_V cs_file_prefix NOPRI;
COL cs_file_name NEW_V cs_file_name NOPRI;
COL cs_script_name NEW_V cs_script_name NOPRI;
--
COL cs_max_snap_id NEW_V cs_max_snap_id FOR A6 NOPRI;
COL cs_max_snap_end_time NEW_V cs_max_snap_end_time FOR A19 NOPRI;
COL cs_last_snap_mins NEW_V cs_last_snap_mins FOR A7 NOPRI;
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
       TO_CHAR(d.dbid) cs_dbid,
       d.name cs_db_name,
       SYS_CONTEXT('USERENV', 'CON_ID') cs_con_id,
       SYS_CONTEXT('USERENV', 'CON_NAME') cs_con_name,
       TO_CHAR(i.instance_number) cs_instance_number,
       i.version cs_db_version,
       i.host_name cs_host_name,
       i.startup_time cs_startup_time,
       o.value cs_num_cpu_cores,
       TRIM(TO_CHAR(ROUND(SYSDATE - i.startup_time, 1), '990.0')) cs_startup_days,
       TO_CHAR(SYSDATE , '&&cs_datetime_full_format.') cs_date_time,
       TO_CHAR(SYSDATE , '&&cs_datetime_short_format.') cs_file_date_time
  FROM v$database d, v$instance i, v$osstat o
 WHERE o.stat_name = 'NUM_CPU_CORES'
/
--
SELECT TO_CHAR(snap_id) cs_max_snap_id,
       TO_CHAR(end_interval_time, '&&cs_datetime_full_format.') cs_max_snap_end_time,
       TRIM(TO_CHAR(ROUND((SYSDATE - CAST(end_interval_time AS DATE)) * 24 * 60, 1), '99990.0')) cs_last_snap_mins
  FROM dba_hist_snapshot
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
 ORDER BY
       snap_id DESC
 FETCH FIRST 1 ROW ONLY
/
--
PRO Issue Reference: (e.g. IOD-10439, ODSI-1153)
DEF issue_reference = '&&issue_reference.';
COL cs_reference NEW_V cs_reference NOPRI;
SELECT NVL('&&issue_reference.', '&&cs_def_reference.') cs_reference FROM DUAL;
COL cs_reference_sanitized NEW_V cs_reference_sanitized NOPRI;
SELECT TRANSLATE('&&cs_reference.', '*()@#$[]{}|/\".,?<>''', '___________________') cs_reference_sanitized FROM DUAL;
--
PRO SCP Target Local Directory: (e.g. &&cs_def_local_dir.&&cs_reference_sanitized.)
DEF target_local_directory = '&&target_local_directory.';
COL cs_local_dir NEW_V cs_local_dir NOPRI;
SELECT NVL('&&target_local_directory.', '&&cs_def_local_dir.&&cs_reference_sanitized.') cs_local_dir FROM DUAL;
--