COL sql_exec_start FOR A19 HEA 'SQL Exec Start';
COL rn_sql_exec_start FOR 999,990 HEA 'Sta RN';
COL last_refresh_time FOR A19 HEA 'Last Refresh Time';
COL sql_exec_id NEW_V sql_exec_id FOR 99999999999 HEA 'SQL Exec ID';
COL status FOR A20 HEA 'Status';
COL duration FOR 999,990 HEA 'Duration';
COL rn_duration FOR 999,990 HEA 'Dur RN';
COL plan_hash FOR 9999999999 HEA 'Plan Hash';
COL full_plan_hash FOR 9999999999 HEA 'Full Plan Hash';
COL elapsed_time FOR 999,990.000 HEA 'Elapsed Time';
COL cpu_time FOR 999,990.000 HEA 'CPU Time';
COL user_io_wait_time FOR 999,990.000 HEA 'User IO Time';
COL concurrency_wait_time FOR 999,990.000 HEA 'Concurrency';
COL application_wait_time FOR 999,990.000 HEA 'Application';
COL plsql_exec_time FOR 999,990.000 HEA 'PL/SQL';
COL user_fetch_count FOR 999,990 HEA 'Fetches';
COL buffer_gets FOR 999,999,999,990 HEA 'Buffer Gets';
COL read_reqs FOR 999,999,990 HEA 'Read Reqs';
COL read_bytes FOR 999,999,999,999,990 HEA 'Read Bytes';
COL sid_serial FOR A15 HEA 'Sid,Serial';
COL pdb_name FOR A30 TRUNC HEA 'PDB Name';
COL user_name FOR A30 TRUNC HEA 'User Name';
COL module FOR A40 TRUNC HEA 'Module';
COL service FOR A40 TRUNC HEA 'Service';
COL program FOR A40 TRUNC HEA 'Program';
--
PRO
PRO SQL MONITOR REPORTS (v$sql_monitor) top &&cs_sqlmon_top. and &&cs_sqlmon_top. most recent
PRO ~~~~~~~~~~~~~~~~~~~
WITH 
sql_mon_mem_reports AS (
SELECT /*+ OPT_PARAM('_newsort_enabled' 'FALSE') OPT_PARAM('_adaptive_fetch_enabled' 'FALSE') OPT_PARAM('query_rewrite_enabled' 'FALSE') */ /* ORA-00600: internal error code, arguments: [15851], [3], [2], [1], [1] */ 
       r.sql_exec_start,
       ROW_NUMBER() OVER(ORDER BY r.sql_exec_start DESC NULLS LAST/*, MAX(r.last_refresh_time) - r.sql_exec_start DESC NULLS LAST*/) AS rn_sql_exec_start,
       MAX(r.last_refresh_time) AS last_refresh_time,
       r.sql_exec_id,
       MAX(r.status) AS status,
       MAX(r.sql_plan_hash_value) AS plan_hash,
       MAX(r.sql_full_plan_hash_value) AS full_plan_hash,
       ROUND((MAX(r.last_refresh_time) - r.sql_exec_start) * 24 * 3600) AS duration,
       ROW_NUMBER() OVER(ORDER BY MAX(r.last_refresh_time) - r.sql_exec_start DESC NULLS LAST/*, r.sql_exec_start DESC NULLS LAST*/) AS rn_duration,
       ROUND(SUM(r.elapsed_time) /  POWER(10, 6), 3) AS elapsed_time,
       ROUND(SUM(r.cpu_time) /  POWER(10, 6), 3) AS cpu_time,
       ROUND(SUM(r.user_io_wait_time) /  POWER(10, 6), 3) AS user_io_wait_time,
       ROUND(SUM(r.concurrency_wait_time) /  POWER(10, 6), 3) AS concurrency_wait_time,
       ROUND(SUM(r.application_wait_time) /  POWER(10, 6), 3) AS application_wait_time,
       ROUND(SUM(r.plsql_exec_time) /  POWER(10, 6), 3) AS plsql_exec_time,
       SUM(r.fetches) AS user_fetch_count,
       SUM(r.buffer_gets) AS buffer_gets,
       SUM(r.physical_read_requests) AS read_reqs,
       SUM(r.physical_read_bytes) AS read_bytes,
       MIN(LPAD(r.sid,5)||','||r.session_serial#) AS sid_serial,
       c.name AS pdb_name,
       MAX(r.username) AS user_name,
       MAX(r.module) AS module,
       MAX(r.program) AS program,
       MAX(r.service_name) AS service
  FROM v$sql_monitor r,
       v$containers c
 WHERE r.sql_id = '&&cs_sql_id.'
   AND c.con_id = r.con_id
   AND c.open_mode = 'READ WRITE'
 GROUP BY
       c.name,
       r.sql_exec_id,
       r.sql_exec_start
--  ORDER BY
--        8 DESC NULLS LAST, 1 DESC NULLS LAST
-- FETCH FIRST &&cs_sqlmon_top. ROWS ONLY
)
SELECT *
  FROM sql_mon_mem_reports
 WHERE rn_sql_exec_start <= &&cs_sqlmon_top. OR rn_duration <= &&cs_sqlmon_top.
 ORDER BY
       sql_exec_start, rn_sql_exec_start
/
