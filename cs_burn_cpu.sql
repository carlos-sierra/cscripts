----------------------------------------------------------------------------------------
--
-- File name:   cs_burn_cpu.sql
--
-- Purpose:     Burn CPU in multiple cores/threads for some time
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter number of CPUs to burn and duration in seconds
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_burn_cpu.sql 36 60
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
PRO
PRO **************
PRO ***
PRO *** Be sure job_queue_processes is set to a large number during the use of this script
PRO ***
PRO **************
PRO
PRO CPUs to burn: [{2}|1-100]
DEF cpus_to_burn = '&1.';
UNDEF 1;
COL cpus_to_burn NEW_V cpus_to_burn NOPRI;
SELECT CASE WHEN TO_NUMBER('&&cpus_to_burn.') BETWEEN 1 AND 100 THEN '&&cpus_to_burn.' WHEN TO_NUMBER('&&cpus_to_burn.') > 100 THEN '100' ELSE '2' END AS cpus_to_burn FROM DUAL;
PRO
PRO Seconds: [{60}|1-3600]
DEF seconds = '&2.';
UNDEF 2;
COL seconds NEW_V seconds NOPRI;
SELECT CASE WHEN TO_NUMBER('&&seconds.') BETWEEN 1 AND 3600 THEN '&&seconds.' WHEN TO_NUMBER('&&seconds.') > 3600 THEN '3600' ELSE '60' END AS seconds FROM DUAL;
--
BEGIN
  FOR i IN (SELECT job_name
              FROM dba_scheduler_jobs
             WHERE job_name LIKE 'CS_BURN_CPU%'
               AND state = 'RUNNING')
  LOOP
    DBMS_SCHEDULER.stop_job(i.job_name);
  END LOOP;
  --
  FOR i IN (SELECT job_name
              FROM dba_scheduler_jobs
             WHERE job_name  LIKE 'CS_BURN_CPU%'
               AND state = 'SCHEDULED')
  LOOP
    DBMS_SCHEDULER.drop_job(i.job_name);
  END LOOP;
END;
/
--
DECLARE
w CLOB := q'[
DECLARE
  d DATE := SYSDATE + (&&seconds./24/3600);
  x NUMBER; 
BEGIN
  WHILE SYSDATE < d
  LOOP
    x := DBMS_RANDOM.normal;
  END LOOP;
END;
]';
BEGIN
  FOR i IN 1 .. &&cpus_to_burn.
  LOOP
    DBMS_SCHEDULER.create_job (
      job_name   => 'CS_BURN_CPU_'||LPAD(i, 3, '0'),
      job_type   => 'PLSQL_BLOCK',
      job_action => REPLACE(w, 'job_instance', i),
      enabled    => TRUE
    );
  END LOOP;
END;
/
--
PRO wait...
EXEC DBMS_LOCK.sleep(5);
COL job_name FOR A16 TRUNC; 
COL last_start_date FOR A36 TRUNC;
SELECT job_name, state, last_start_date,
       (CAST(last_start_date AS DATE) + (&&seconds./24/3600) - SYSDATE) * (24*3600) AS secs_to_finish
  FROM dba_scheduler_jobs 
 WHERE job_name LIKE 'CS_BURN_CPU%' ORDER BY job_name;
--
PRO
PRO Use "/" to check on status of these &&cpus_to_burn. CS_BURN_CPU jobs