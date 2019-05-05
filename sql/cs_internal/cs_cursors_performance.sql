COL last_active_time FOR A19 HEA 'Last Active Time';
COL child_number FOR 999999 HEA 'Child|Number';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL users_executing FOR 9,999 HEA 'Users|Exec';
COL avg_et_ms FOR 99,999,990.000 HEA 'Avg Elapsed|Time (ms)';
COL avg_cpu_ms FOR 99,999,990.000 HEA 'Avg CPU|Time (ms)';
COL avg_bg FOR 999,999,990 HEA 'Avg|Buffer Gets';
COL avg_row FOR 999,999,990.000 HEA 'Avg|Rows Processed';
COL executions FOR 999,999,999,990 HEA 'Executions';
COL tot_et_secs FOR 99,999,990 HEA 'Total Elapsed|Time (secs)';
COL tot_cpu_secs FOR 99,999,990 HEA 'Total CPU|Time (secs)';
COL tot_buffer_gets FOR 999,999,999,990 HEA 'Total|Buffer Gets';
COL tot_rows_processed FOR 999,999,999,990 HEA 'Total|Rows Processed';
--
PRO
PRO CURSORS PERFORMANCE (v$sql)
PRO ~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(last_active_time, '&&cs_datetime_full_format.') last_active_time,
       child_number,
       plan_hash_value,
       users_executing,
       elapsed_time/NULLIF(executions,0)/1e3 avg_et_ms,
       cpu_time/NULLIF(executions,0)/1e3 avg_cpu_ms,
       buffer_gets/NULLIF(executions,0) avg_bg,
       rows_processed/NULLIF(executions,0) avg_row,
       executions,
       elapsed_time/1e6 tot_et_secs,
       cpu_time/1e6 tot_cpu_secs,
       buffer_gets tot_buffer_gets,
       rows_processed tot_rows_processed
  FROM v$sql
 WHERE sql_id = '&&cs_sql_id.'
   --AND executions > 0
 ORDER BY
       last_active_time,
       child_number
/
--

