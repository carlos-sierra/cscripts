COL last_active_time FOR A19 HEA 'Last Active Time';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL cursors FOR 9,999,990 HEA 'Child|Cursors';
COL valid FOR 9,999,990 HEA 'Valid|Cursors';
COL invalid FOR 9,999,990 HEA 'Invalid|Cursors';
COL obsolete FOR 9,999,990 HEA 'Obsolete|Cursors';
COL shareable FOR 9,999,990 HEA 'Shareable|Cursors';
COL bind_sens FOR 9,999,990 HEA 'Bind|Sensitive|Cursors';
COL bind_aware FOR 9,999,990 HEA 'Bind|Aware|Cursors';
COL avg_et_ms FOR 99,999,990.000 HEA 'Avg Elapsed|Time (ms)';
COL avg_cpu_ms FOR 99,999,990.000 HEA 'Avg CPU|Time (ms)';
COL avg_bg FOR 999,999,999,990 HEA 'Avg|Buffer Gets';
COL avg_row FOR 999,999,990.000 HEA 'Avg|Rows Processed';
COL executions FOR 999,999,999,990 HEA 'Executions';
--
PRO
PRO PLANS SUMMARY (v$sql)
PRO ~~~~~~~~~~~~~
SELECT TO_CHAR(MAX(last_active_time), '&&cs_datetime_full_format.') last_active_time,
       plan_hash_value,
       COUNT(DISTINCT child_number) cursors,
       SUM(CASE SUBSTR(object_status, 1, 5) WHEN 'VALID' THEN 1 ELSE 0 END) valid,
       SUM(CASE SUBSTR(object_status, 1, 7) WHEN 'INVALID' THEN 1 ELSE 0 END) invalid,       
       SUM(CASE is_obsolete WHEN 'Y' THEN 1 ELSE 0 END) obsolete,
       SUM(CASE is_shareable WHEN 'Y' THEN 1 ELSE 0 END) shareable,
       SUM(CASE is_bind_sensitive WHEN 'Y' THEN 1 ELSE 0 END) bind_sens,
       SUM(CASE is_bind_aware WHEN 'Y' THEN 1 ELSE 0 END) bind_aware,
       SUM(elapsed_time)/NULLIF(SUM(executions), 0)/1e3 avg_et_ms,
       SUM(cpu_time)/NULLIF(SUM(executions), 0)/1e3 avg_cpu_ms,
       SUM(buffer_gets)/NULLIF(SUM(executions), 0) avg_bg,
       SUM(rows_processed)/NULLIF(SUM(executions), 0) avg_row,
       SUM(executions) executions
  FROM v$sql
 WHERE sql_id = '&&cs_sql_id.'
   --AND executions > 0
 GROUP BY
       plan_hash_value
 ORDER BY
       1, 2
/
--
