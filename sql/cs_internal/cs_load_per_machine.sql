COL machine FOR A64 HEA 'Machine (Application Server)';
COL load_percent FOR 990.0 HEA 'Load|Perc%';
BREAK ON REPORT;
COMPUTE SUM LABEL "TOTAL" OF load_percent ON REPORT;
--
PRO
PRO LOAD PER MACHINE (v$active_session_history)
PRO ~~~~~~~~~~~~~~~~
WITH
load AS (
SELECT h.machine,
       COUNT(DISTINCT TO_CHAR(sql_exec_start, 'YYYYMMDDHH24MISS')||'.'||TO_CHAR(sql_exec_id)) AS executions
  FROM v$active_session_history h
 WHERE h.sql_id = '&&cs_sql_id.'
 GROUP BY
       h.machine
)
SELECT machine,
       100 * executions / SUM(executions) OVER () AS load_percent
  FROM load
 ORDER BY
       machine
/
--
PRO
PRO LOAD PER MACHINE 7d (dba_hist_active_sess_history)
PRO ~~~~~~~~~~~~~~~~~~~
WITH
load AS (
SELECT h.machine,
       COUNT(DISTINCT TO_CHAR(sql_exec_start, 'YYYYMMDDHH24MISS')||'.'||TO_CHAR(sql_exec_id)) AS executions
  FROM dba_hist_active_sess_history h
 WHERE h.sql_id = '&&cs_sql_id.'
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.sample_time > SYSDATE - 7
   AND h.snap_id >= &&cs_7d_snap_id.
 GROUP BY
       h.machine
)
SELECT machine,
       100 * executions / SUM(executions) OVER () AS load_percent
  FROM load
 ORDER BY
       machine
/
--
CLEAR BREAK COMPUTE;
