-- IOD_REPEATING_SESS_KILLER_MONITOR (every 5 mins) ALL
-- Monitors dba_scheduler_jobs job_name = 'IOD_SESS_KILLER' is executing
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, '*** Must execute on PRIMARY ***');
  END IF;
END;
/
--
-- exit with error if 
-- IOD_SESS_KILLER does not exist; or
-- IOD_SESS_KILLER hasn't executed during past 5 minutes; or
-- IOD_SESS_KILLER is not scheduled within next 5 minutes
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
  l_state VARCHAR2(15);
  l_last_start_date DATE;
  l_next_run_date DATE;
BEGIN
  SELECT state, last_start_date, next_run_date
    INTO l_state, l_last_start_date, l_next_run_date
    FROM dba_scheduler_jobs
   WHERE job_name = 'IOD_SESS_KILLER';
  --
  IF l_state NOT IN ('SCHEDULED', 'RETRY SCHEDULED', 'RUNNING') THEN
    raise_application_error(-20000, '*** state for IOD_SESS_KILLER on dba_scheduler_jobs is "'||l_state||'" ***. Expecting: "SCHEDULED" or "RETRY SCHEDULED" or "RUNNING".');
  ELSIF l_last_start_date < SYSDATE - (5/24/60) THEN
    raise_application_error(-20000, '*** last_start_date for IOD_SESS_KILLER on dba_scheduler_jobs is "'||TO_CHAR(l_last_start_date, 'YYYY-MM-DD"T"HH24:MI:SS')||'" ***. Expecting within past 5 minutes.');
  ELSIF l_next_run_date > SYSDATE + (5/24/60) THEN
    raise_application_error(-20000, '*** next_run_date for IOD_SESS_KILLER on dba_scheduler_jobs is "'||TO_CHAR(l_next_run_date, 'YYYY-MM-DD"T"HH24:MI:SS')||'" ***. Expecting within next 5 minutes.');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN 
    raise_application_error(-20000, '*** IOD_SESS_KILLER is missing from dba_scheduler_jobs ***');
END;
/
