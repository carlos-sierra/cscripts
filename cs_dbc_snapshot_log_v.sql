----------------------------------------------------------------------------------------
--
-- File name:   cs_dbc_snapshot_log_v.sql
--
-- Purpose:     DBC Snapshot Log Report
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_dbc_snapshot_log_v.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL view_owner NEW_V view_owner NOPRI;
SELECT owner AS view_owner FROM dba_views WHERE view_name = 'DBC_SNAPSHOT_LOG_V';
--
COL table_name FOR A30;
COL region_acronym FOR A3 HEA 'RGN';
COL locale FOR A6;
COL runs FOR 999,990;
COL avg_secs FOR 999,990;
COL secs_per_day FOR 999,999,990;
COL total_rows_processed FOR 999,999,999,990;
COL errors FOR 99,990;
COL seconds FOR 999,990;
COL last_rows_processed FOR 999,999,999,990;
COL last_error_stack FOR A100;
--
BREAK ON REPORT;
COMPUTE SUM LABEL "TOTAL" OF runs secs_per_day total_rows_processed errors seconds last_rows_processed ON REPORT;
--
PRO
PRO Source (from CDB)
PRO ~~~~~~
SELECT  --region_acronym, 
        --locale, 
        --db_name, 
        table_name,
        runs,
        first_time,
        avg_secs,
        secs_per_day,
        errors,
        total_rows_processed,
        last_begin_time,
        last_end_time,
        seconds,
        last_rows_processed,
        last_error_stack  
  FROM &&view_owner..dbc_snapshot_log_v
/
--
COL min_since_last FOR 9,999,990.00 HEA 'MINUTES_AGO';
COL min_until_next FOR 9,999,990.00 HEA 'MINUTES_2GO';
COL avg_rows FOR 999,999,999,990;
COL to_key FOR A14;
COL error_message FOR A100;
--
BREAK ON REPORT;
COMPUTE SUM LABEL "TOTAL" OF runs total_rows_processed errors seconds ON REPORT;
--
PRO
PRO Target (into OMR)
PRO ~~~~~~
SELECT  s.collect_name AS table_name,
        s.collections AS runs,
        s.first_time,
        s.last_time,
        s.status,
        s.min_since_last,
        s.min_until_next,
        s.errors,
        s.total_rows AS total_rows_processed,
        s.avg_rows,
        s.elap_sec AS seconds,
        s.avg_sec AS avg_secs,
        --from_key,
        s.to_key,
        h.error_message
  FROM &&view_owner..iod_metadata_ctl_summ s, &&view_owner..iod_metadata_ctl_hist h
 WHERE h.collect_name = s.collect_name
   AND h.start_time = s.last_time
ORDER BY s.collect_name
/
--
CLEAR BREAK;
--
COL job_name FOR A30;
COL job_action FOR A40;
COL repeat_interval FOR A30;
COL enabled FOR A7;
COL last_start_date FOR A19;
COL last_run_secs FOR 999,990.000;
COL next_run_date FOR A19;
--
PRO
PRO DBA_SCHEDULER_JOBS
PRO ~~~~~~~~~~~~~~~~~~
SELECT job_name,
       job_type, 
       job_action, 
       repeat_interval, 
       enabled, 
       state, 
       run_count, 
       EXTRACT(SECOND FROM last_run_duration) last_run_secs,
       TO_CHAR(last_start_date, 'YYYY-MM-DD"T"HH24:MI:SS') last_start_date, 
       TO_CHAR(next_run_date, 'YYYY-MM-DD"T"HH24:MI:SS') next_run_date
  FROM dba_scheduler_jobs
 WHERE job_name LIKE 'IOD_META%'
 ORDER BY
       job_name
/