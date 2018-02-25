SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL dbid NEW_V dbid;
COL db_name NEW_V db_name;
SELECT dbid, LOWER(name) db_name FROM v$database
/

COL instance_number NEW_V instance_number;
COL host_name NEW_V host_name;
SELECT instance_number, LOWER(host_name) host_name FROM v$instance
/

COL con_name NEW_V con_name;
SELECT 'NONE' con_name FROM DUAL;
SELECT LOWER(SYS_CONTEXT('USERENV', 'CON_NAME')) con_name FROM DUAL
/

COL locale NEW_V locale;
SELECT LOWER(REPLACE(SUBSTR('&&host_name.', 1 + INSTR('&&host_name.', '.', 1, 2), 30), '.', '_')) locale FROM DUAL
/

COL output_file_name NEW_V output_file_name;
SELECT 'autotask_windows_&&locale._&&db_name._'||REPLACE('&&con_name.','$')||'_'||TO_CHAR(SYSDATE, 'YYYYMMDD"T"HH24MMSS') output_file_name FROM DUAL
/

SPO &&output_file_name..txt;
PRO
PRO &&output_file_name..txt
PRO
PRO LOCALE   : &&locale.
PRO DATABASE : &&db_name.
PRO CONTAINER: &&con_name.
PRO HOST     : &&host_name.

COL client_name FOR A32;

PRO
PRO dba_autotask_operation
PRO ~~~~~~~~~~~~~~~~~~~~~~

SELECT client_name,
       status
  FROM dba_autotask_operation
/

COL window_name FOR A16;
COL active FOR A6;
COL enabled FOR A7;
COL duration FOR A15;
COL repeat_interval FOR A80;

PRO
PRO dba_scheduler_windows
PRO ~~~~~~~~~~~~~~~~~~~~~

SELECT window_name, 
       active,
       enabled,
       duration,
       repeat_interval
  FROM dba_scheduler_windows
 WHERE owner = 'SYS'
/

COL window_name FOR A16;
COL window_active FOR A6 HEA 'ACTIVE';
COL window_next_time FOR A19;
COL autotask_status FOR A8 HEA 'AUTOTASK';
COL optimizer_stats FOR A8 HEA 'STATS|GATHER';
COL segment_advisor FOR A8 HEA 'SEGMENT|ADVISOR';
COL sql_tune_advisor FOR A8 HEA 'SQL|TUNING|ADVISOR';

PRO
PRO dba_autotask_window_clients
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT window_name,
       window_active,
       autotask_status,
       TO_CHAR(window_next_time, 'YYYY-MM-DD"T"HH24:MI:SS') window_next_time,
       optimizer_stats,
       segment_advisor,
       sql_tune_advisor
  FROM dba_autotask_window_clients
/

COL window_start_time FOR A19;
COL window_end_time FOR A19;
COL window_duration FOR A8 HEA 'DURATION|HH:MM:SS';
COL window_name FOR A16;
COL jobs_created HEA 'JOBS|CREATED';
COL jobs_started HEA 'JOBS|STARTED';
COL jobs_completed HEA 'JOBS|COMPLETED';

PRO
PRO dba_autotask_client_history
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT TO_CHAR(window_start_time, 'YYYY-MM-DD"T"HH24:MI:SS') window_start_time,
       TO_CHAR(window_end_time, 'YYYY-MM-DD"T"HH24:MI:SS') window_end_time,
       TO_CHAR(EXTRACT(HOUR FROM window_duration), 'fm00')||':'||
       TO_CHAR(EXTRACT(MINUTE FROM window_duration), 'fm00')||':'||
       TO_CHAR(EXTRACT(SECOND FROM window_duration), 'fm00')
       window_duration,
       window_name,
       jobs_created,
       jobs_started,
       jobs_completed,
       client_name
  FROM dba_autotask_client_history
 ORDER BY
       window_start_time
/

COL window_start_time FOR A19;
COL window_duration FOR A8 HEA 'WINDOW|DURATION|HH:MM:SS';
COL window_name FOR A16;
COL job_start_time FOR A19;
COL job_duration FOR A8 HEA 'JOB|DURATION|HH:MM:SS';
COL job_status FOR A10;
COL job_error FOR 99999 HEA 'JOB|ERROR';

PRO
PRO dba_autotask_job_history
PRO ~~~~~~~~~~~~~~~~~~~~~~~~

SELECT TO_CHAR(job_start_time, 'YYYY-MM-DD"T"HH24:MI:SS') job_start_time,
       TO_CHAR(EXTRACT(HOUR FROM job_duration), 'fm00')||':'||
       TO_CHAR(EXTRACT(MINUTE FROM job_duration), 'fm00')||':'||
       TO_CHAR(EXTRACT(SECOND FROM job_duration), 'fm00')
       job_duration,
       job_status,
       job_error,
       TO_CHAR(window_start_time, 'YYYY-MM-DD"T"HH24:MI:SS') window_start_time,
       TO_CHAR(EXTRACT(HOUR FROM window_duration), 'fm00')||':'||
       TO_CHAR(EXTRACT(MINUTE FROM window_duration), 'fm00')||':'||
       TO_CHAR(EXTRACT(SECOND FROM window_duration), 'fm00')
       window_duration,
       window_name,
       client_name
  FROM dba_autotask_job_history
 ORDER BY
       job_start_time
/

COL job_start_date FOR A10 HEA 'JOB|START_DATE';
COL seconds FOR 9999999;
COL jobs FOR 9999;

SELECT client_name,
       TO_CHAR(TRUNC(CAST(job_start_time AS DATE)), 'YYYY-MM-DD') job_start_date,
       COUNT(*) jobs,
       ROUND(24 * 60 * 60 * SUM(CAST(job_start_time + job_duration AS DATE) - CAST(job_start_time AS DATE))) seconds
  FROM dba_autotask_job_history
 GROUP BY
       client_name,
       TRUNC(CAST(job_start_time AS DATE))
 ORDER BY
       1,2
/

COL max_job_start_time FOR A19;

SELECT client_name, COUNT(*) jobs,
       ROUND(24 * 60 * 60 * SUM(CAST(job_start_time + job_duration AS DATE) - CAST(job_start_time AS DATE))) seconds,
       TO_CHAR(MAX(job_start_time), 'YYYY-MM-DD"T"HH24:MI:SS') max_job_start_time
  FROM dba_autotask_job_history
 GROUP BY
       client_name
/

PRO
PRO &&output_file_name..txt

SPO OFF;
CL COL;
