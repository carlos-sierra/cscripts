SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL job_name FOR A30 TRUNC;
COL job_action FOR A40 TRUNC;
COL repeat_interval FOR A30 TRUNC;
COL enabled FOR A7 TRUNC;
COL last_start_date FOR A19 TRUNC;
COL last_run_secs FOR 999,990.000;
COL next_run_date FOR A19 TRUNC;
COL log_date FOR A19 TRUNC;
COL req_start_date FOR A19 TRUNC;
COL actual_start_date FOR A19 TRUNC;
COL run_secs FOR 999,990.000;
COL cpu_secs FOR 999,990.000;
COL output FOR A120 TRUNC;
COL errors FOR A80 TRUNC;
--
PRO
PRO DBA_SCHEDULER_JOBS (IOD Jobs)
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
 WHERE job_name LIKE 'IOD%'
 ORDER BY
       job_name
/
--
PRO
PRO DBA_SCHEDULER_JOB_LOG (last 20)
PRO ~~~~~~~~~~~~~~~~~~~~~
SELECT * FROM (
SELECT log_id,
       TO_CHAR(log_date, 'YYYY-MM-DD"T"HH24:MI:SS') log_date,
       job_name,
       status
  FROM dba_scheduler_job_log -- see also dba_scheduler_running_jobs
 WHERE job_name LIKE 'IOD%'
 ORDER BY
       log_id DESC
 FETCH FIRST 20 ROWS ONLY
)
ORDER BY log_date
/
--
PRO
PRO DBA_SCHEDULER_JOB_RUN_DETAILS (last 20)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT * FROM (
SELECT log_id,
       TO_CHAR(log_date, 'YYYY-MM-DD"T"HH24:MI:SS') log_date,
       job_name,
       status,
       error#,
       TO_CHAR(req_start_date, 'YYYY-MM-DD"T"HH24:MI:SS') req_start_date,
       TO_CHAR(actual_start_date, 'YYYY-MM-DD"T"HH24:MI:SS') actual_start_date,
       EXTRACT(SECOND FROM run_duration) run_secs,
       EXTRACT(SECOND FROM cpu_used) cpu_secs,
       output
       --,errors
  FROM dba_scheduler_job_run_details -- see also dba_scheduler_running_jobs
 WHERE job_name LIKE 'IOD%'
 ORDER BY
       log_id DESC
 FETCH FIRST 20 ROWS ONLY
)
ORDER BY log_id
/  
--