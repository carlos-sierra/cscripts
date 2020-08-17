DEF 1 = 'C##IOD';
-- stop and drop obsolete jobs IOD_SESS_CONCURRENCY and IOD_SESS_KILLER
BEGIN
  FOR i IN (SELECT job_name
              FROM dba_scheduler_jobs
             WHERE job_name IN ('IOD_SESS_CONCURRENCY', 'IOD_SESS_KILLER')
               AND state = 'RUNNING')
  LOOP
    DBMS_SCHEDULER.stop_job(i.job_name);
  END LOOP;
  --
  FOR i IN (SELECT job_name
              FROM dba_scheduler_jobs
             WHERE job_name IN ('IOD_SESS_CONCURRENCY', 'IOD_SESS_KILLER')
               AND state = 'SCHEDULED')
  LOOP
    DBMS_SCHEDULER.drop_job(i.job_name);
  END LOOP;
END;
/
--
DECLARE
  l_count INTEGER;
BEGIN
  SELECT COUNT(*) 
    INTO l_count
    FROM dba_scheduler_jobs
   WHERE job_name = 'IOD_SESS_MONITOR';
  --
  IF l_count = 0 THEN
    DBMS_SCHEDULER.CREATE_JOB (
      job_name        => 'IOD_SESS_MONITOR',
      job_type        => 'STORED_PROCEDURE',
      job_action      => '&1..IOD_SESS.MONITOR',
      start_date      => TRUNC(SYSDATE),
      repeat_interval => 'FREQ=SECONDLY;INTERVAL=29;',
      enabled         => TRUE,
      comments        => 'Sessions Monitor'
    );
  END IF;
  --
  SELECT COUNT(*) 
    INTO l_count
    FROM dba_scheduler_jobs
   WHERE job_name = 'IOD_SESS_MONITOR'
     AND repeat_interval = 'FREQ=SECONDLY;INTERVAL=29;';
  --
  IF l_count = 0 THEN
    DBMS_SCHEDULER.SET_ATTRIBUTE (
      name      => 'IOD_SESS_MONITOR',
      attribute => 'repeat_interval',
      value     => 'FREQ=SECONDLY;INTERVAL=29;'
    );
  END IF;
END;
/
--
UNDEF 1;