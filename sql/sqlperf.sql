SPO sqlperf.txt;

SET LIN 300 PAGES 100;

PRO DBA_HIST_SQLSTAT (summary)
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

PRO GV$SQL (performance)
PRO ~~~~~~
SELECT inst_id,
       child_number,
       plan_hash_value,
       is_shareable s,
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

PRO GV$SQL (summary)
PRO ~~~~~~
SELECT plan_hash_value,
       TO_CHAR(ROUND(SUM(elapsed_time)/SUM(executions)/1e6,6), '999,990.000000') et_secs_per_exec,
       TO_CHAR(ROUND(SUM(cpu_time)/SUM(executions)/1e6,6), '999,990.000000') cpu_secs_per_exec,
       SUM(executions) executions,
       TO_CHAR(ROUND(SUM(elapsed_time)/1e6,6), '999,999,999,990') et_secs_tot,
       TO_CHAR(ROUND(SUM(cpu_time)/1e6,6), '999,999,999,990') cpu_secs_tot,
       COUNT(DISTINCT child_number) cursors,
       MAX(child_number) max_child,
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