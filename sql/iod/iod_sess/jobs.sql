SET HEA ON LIN 2490 PAGES 100 TAB OFF LONG 240000 LONGC 120;
--
COL job_action FOR A30;
COL repeat_interval FOR A30;
COL enabled FOR A7;
COL last_start_date FOR A19;
COL last_run_secs FOR 999,990.000;
COL next_run_date FOR A19;
COL log_date FOR A19;
COL req_start_date FOR A19;
COL actual_start_date FOR A19;
COL run_secs FOR 999,990.000;
COL cpu_secs FOR 999,990.000;
COL output FOR A120;
COL errors FOR A80;
--
SELECT job_type, 
       job_action, 
       repeat_interval, 
       enabled, 
       state, 
       run_count, 
       EXTRACT(SECOND FROM last_run_duration) last_run_secs,
       TO_CHAR(last_start_date, 'YYYY-MM-DD"T"HH24:MI:SS') last_start_date, 
       TO_CHAR(next_run_date, 'YYYY-MM-DD"T"HH24:MI:SS') next_run_date
  FROM dba_scheduler_jobs
 WHERE job_name = 'IOD_SESS_KILLER'
/
--
SELECT log_id,
       TO_CHAR(log_date, 'YYYY-MM-DD"T"HH24:MI:SS') log_date,
       status
  FROM dba_scheduler_job_log -- see also dba_scheduler_running_jobs
 WHERE job_name = 'IOD_SESS_KILLER'
 ORDER BY
       log_id DESC
 FETCH FIRST 10 ROWS ONLY
/
SELECT log_id,
       TO_CHAR(log_date, 'YYYY-MM-DD"T"HH24:MI:SS') log_date,
       status,
       error#,
       TO_CHAR(req_start_date, 'YYYY-MM-DD"T"HH24:MI:SS') req_start_date,
       TO_CHAR(actual_start_date, 'YYYY-MM-DD"T"HH24:MI:SS') actual_start_date,
       EXTRACT(SECOND FROM run_duration) run_secs,
       EXTRACT(SECOND FROM cpu_used) cpu_secs,
       output
       --,errors
  FROM dba_scheduler_job_run_details -- see also dba_scheduler_running_jobs
 WHERE job_name = 'IOD_SESS_KILLER'
 ORDER BY
       log_id DESC
 FETCH FIRST 10 ROWS ONLY
/  
--
DECLARE
  l_count INTEGER;
BEGIN
  SELECT COUNT(*) 
    INTO l_count
    FROM dba_scheduler_jobs
   WHERE job_name = 'IOD_SESS_KILLER';
  --
  IF l_count = 0 THEN
    DBMS_SCHEDULER.CREATE_JOB (
      job_name        => 'IOD_SESS_KILLER',
      job_type        => 'STORED_PROCEDURE',
      job_action      => 'C##IOD.IOD_SESS.KILLER',
      start_date      => TRUNC(SYSDATE),
      repeat_interval => 'FREQ=SECONDLY;INTERVAL=15;',
      enabled         => TRUE,
      comments        => 'Kill inactive user sessions holding a lock on KT'
    );
    /*
    DBMS_SCHEDULER.SET_ATTRIBUTE (
      name      => 'IOD_SESS_KILLER',
      attribute => 'repeat_interval',
      value     => 'FREQ=SECONDLY;INTERVAL=15;'
    );
    */
  END IF;
END;
/

