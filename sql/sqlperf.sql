SET FEED OFF VER OFF HEA ON LIN 2000 PAGES 50 TAB OFF TIMI OFF LONG 80000 LONGC 2000 TRIMS ON AUTOT OFF;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

SPO sqlperf_&&sql_id._&&current_time..txt;
PRO SQL_ID: &&sql_id.
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

PRO
PRO DBA_HIST_SQLSTAT (summary by phv)
PRO ~~~~~~~~~~~~~~~~
SELECT plan_hash_value,
       TO_CHAR(ROUND(SUM(elapsed_time_delta)/SUM(executions_delta)/1e6,6), '999,990.000000') et_secs_per_exec,
       TO_CHAR(ROUND(SUM(cpu_time_delta)/SUM(executions_delta)/1e6,6), '999,990.000000') cpu_secs_per_exec,
       SUM(executions_delta) executions,
       TO_CHAR(ROUND(SUM(elapsed_time_delta)/1e6,6), '999,999,999,990') et_secs_tot,
       TO_CHAR(ROUND(SUM(cpu_time_delta)/1e6,6), '999,999,999,990') cpu_secs_tot,
       ROUND(SUM(buffer_gets_delta)/SUM(executions_delta)) buffers_per_exec,
       TO_CHAR(ROUND(SUM(rows_processed_delta)/SUM(executions_delta), 3), '999,999,999,990.000') rows_per_exec
  FROM dba_hist_sqlstat
 WHERE sql_id = '&&sql_id.'
   AND executions_delta > 0
 GROUP BY
       plan_hash_value
 ORDER BY
       2;

PRO
PRO GV$SQL (plan stability)
PRO ~~~~~~
SELECT inst_id,
       child_number,
       plan_hash_value,
       sql_profile,
       sql_plan_baseline,
       sql_patch
  FROM gv$sql
 WHERE sql_id = '&&sql_id.'
   AND executions > 0
 ORDER BY
       inst_id,
       child_number;

COL sens FOR A4;
COL aware FOR A5;
COL shar FOR A4;
COL u_exec FOR 999999;

PRO
PRO GV$SQL (performance)
PRO ~~~~~~
SELECT inst_id,
       child_number,
       plan_hash_value,
       is_bind_sensitive sens,
       is_bind_aware aware,
       is_shareable shar,
       users_executing u_exec,
       TO_CHAR(ROUND(elapsed_time/executions/1e6,6), '999,990.000000') et_secs_per_exec,
       TO_CHAR(ROUND(cpu_time/executions/1e6,6), '999,990.000000') cpu_secs_per_exec,
       executions,
       TO_CHAR(ROUND(elapsed_time/1e6,6), '999,999,999,990') et_secs_tot,
       TO_CHAR(ROUND(cpu_time/1e6,6), '999,999,999,990') cpu_secs_tot,
       TO_CHAR(last_active_time, 'YYYY-MM-DD"T"HH24:MI:SS') last_active_time,
       ROUND(buffer_gets/executions) buffers_per_exec,
       TO_CHAR(ROUND(rows_processed/executions, 3), '999,999,999,990.000') rows_per_exec
  FROM gv$sql
 WHERE sql_id = '&&sql_id.'
   AND executions > 0
 ORDER BY
       inst_id,
       child_number;

COL sid_serial# FOR A12;
COL current_timed_event FOR A80;

PRO
PRO GV$SESSION (active)
PRO ~~~~~~~~~~
SELECT inst_id,
       sql_child_number child_number,
       sid||','||serial# sid_serial#,
       TO_CHAR(sql_exec_start, 'YYYY-MM-DD"T"HH24:MI:SS') sql_exec_start,
       CASE state WHEN 'WAITING' THEN SUBSTR(wait_class||' - '||event, 1, 100) ELSE 'ON CPU' END current_timed_event
  FROM gv$session
 WHERE sql_id = '&&sql_id.'
   AND status = 'ACTIVE'
 ORDER BY
       inst_id,
       child_number,
       sid;

COL bind_name FOR A30;
COL bind_value FOR A80;

PRO
PRO GV$SQL_BIND_CAPTURE (sample)
PRO ~~~~~~~~~~
SELECT inst_id,
       TO_CHAR(last_captured, 'YYYY-MM-DD"T"HH24:MI:SS') last_captured,
       child_number,
       position, 
       SUBSTR(name, 1, 30) bind_name,
       SUBSTR(value_string, 1, 80) bind_value
  FROM gv$sql_bind_capture 
 WHERE sql_id = '&&sql_id.'
 ORDER BY
       inst_id,
       last_captured,
       child_number,
       position;

COL os_stat FOR A13;

PRO
PRO GV$OSSTAT (load and cores)
PRO ~~~~~~~~~~
SELECT inst_id,
       stat_name os_stat,
       ROUND(value, 1) value
  FROM gv$osstat
 WHERE stat_name IN ('LOAD', 'NUM_CPU_CORES')
 ORDER BY
       inst_id,
       stat_name;

PRO
PRO GV$SQL (summary by phv)
PRO ~~~~~~
SELECT plan_hash_value,
       TO_CHAR(ROUND(SUM(elapsed_time)/SUM(executions)/1e6,6), '999,990.000000') et_secs_per_exec,
       TO_CHAR(ROUND(SUM(cpu_time)/SUM(executions)/1e6,6), '999,990.000000') cpu_secs_per_exec,
       SUM(executions) executions,
       --TO_CHAR(ROUND(SUM(elapsed_time)/1e6,6), '999,999,999,990') et_secs_tot,
       --TO_CHAR(ROUND(SUM(cpu_time)/1e6,6), '999,999,999,990') cpu_secs_tot,
       COUNT(DISTINCT child_number) cursors,
       MAX(child_number) max_child,
       SUM(CASE is_bind_sensitive WHEN 'Y' THEN 1 ELSE 0 END) bind_sens,
       SUM(CASE is_bind_aware WHEN 'Y' THEN 1 ELSE 0 END) bind_aware,
       SUM(CASE is_shareable WHEN 'Y' THEN 1 ELSE 0 END) shareable,
       TO_CHAR(MAX(last_active_time), 'YYYY-MM-DD"T"HH24:MI:SS') last_active_time,
       ROUND(SUM(buffer_gets)/SUM(executions)) buffers_per_exec,
       TO_CHAR(ROUND(SUM(rows_processed)/SUM(executions), 3), '999,999,999,990.000') rows_per_exec
  FROM gv$sql
 WHERE sql_id = '&&sql_id.'
   AND executions > 0
 GROUP BY
       plan_hash_value
 ORDER BY
       2;

SPO OFF;