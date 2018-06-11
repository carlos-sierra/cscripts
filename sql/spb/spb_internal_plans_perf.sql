-- spb_internal_plans_perf.sql
-- summary of plans performance given a sql_id
-- this script is for internal use and only to be called from other scriprs

COL avg_et_ms_awr FOR A11 HEA 'ET Avg|AWR (ms)';
COL avg_et_ms_mem FOR A11 HEA 'ET Avg|MEM (ms)';
COL avg_cpu_ms_awr FOR A11 HEA 'CPU Avg|AWR (ms)';
COL avg_cpu_ms_mem FOR A11 HEA 'CPU Avg|MEM (ms)';
COL avg_bg_awr FOR 999,999,990 HEA 'BG Avg|AWR';
COL avg_bg_mem FOR 999,999,990 HEA 'BG Avg|MEM';
COL avg_row_awr FOR 999,990.000 HEA 'Rows Avg|AWR';
COL avg_row_mem FOR 999,990.000 HEA 'Rows Avg|MEM';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL executions_awr FOR 999,999,999,999 HEA 'Executions|AWR';
COL executions_mem FOR 999,999,999,999 HEA 'Executions|MEM';
COL min_cost FOR 9,999,999 HEA 'MIN Cost';
COL max_cost FOR 9,999,999 HEA 'MAX Cost';
COL nl FOR 99;
COL hj FOR 99;
COL mj FOR 99;
COL p100_et_ms FOR A11 HEA 'ET 100th|Pctl (ms)';
COL p99_et_ms FOR A11 HEA 'ET 99th|Pctl (ms)';
COL p97_et_ms FOR A11 HEA 'ET 97th|Pctl (ms)';
COL p95_et_ms FOR A11 HEA 'ET 95th|Pctl (ms)';
COL p100_cpu_ms FOR A11 HEA 'CPU 100th|Pctl (ms)';
COL p99_cpu_ms FOR A11 HEA 'CPU 99th|Pctl (ms)';
COL p97_cpu_ms FOR A11 HEA 'CPU 97th|Pctl (ms)';
COL p95_cpu_ms FOR A11 HEA 'CPU 95th|Pctl (ms)';
--
PRO
PRO PLANS PERFORMANCE
PRO ~~~~~~~~~~~~~~~~~
WITH
pm AS (
SELECT plan_hash_value, operation,
       CASE operation WHEN 'NESTED LOOPS' THEN COUNT(DISTINCT id) ELSE 0 END nl,
       CASE operation WHEN 'HASH JOIN' THEN COUNT(DISTINCT id) ELSE 0 END hj,
       CASE operation WHEN 'MERGE JOIN' THEN COUNT(DISTINCT id) ELSE 0 END mj
  FROM gv$sql_plan
 WHERE sql_id = TRIM('&&sql_id.')
 GROUP BY
       plan_hash_value,
       operation ),
pa AS (
SELECT plan_hash_value, operation,
       CASE operation WHEN 'NESTED LOOPS' THEN COUNT(DISTINCT id) ELSE 0 END nl,
       CASE operation WHEN 'HASH JOIN' THEN COUNT(DISTINCT id) ELSE 0 END hj,
       CASE operation WHEN 'MERGE JOIN' THEN COUNT(DISTINCT id) ELSE 0 END mj
  FROM dba_hist_sql_plan
 WHERE sql_id = TRIM('&&sql_id.')
 GROUP BY
       plan_hash_value,
       operation ),
pm_pa AS (
SELECT plan_hash_value, MAX(nl) nl, MAX(hj) hj, MAX(mj) mj
  FROM pm
 GROUP BY
       plan_hash_value
 UNION
SELECT plan_hash_value, MAX(nl) nl, MAX(hj) hj, MAX(mj) mj
  FROM pa
 GROUP BY
       plan_hash_value ),
p AS (
SELECT plan_hash_value, MAX(nl) nl, MAX(hj) hj, MAX(mj) mj
  FROM pm_pa
 GROUP BY
       plan_hash_value ),
phv_perf AS (       
SELECT plan_hash_value,
       snap_id,
       SUM(elapsed_time_delta)/SUM(executions_delta) avg_et_us,
       SUM(cpu_time_delta)/SUM(executions_delta) avg_cpu_us
  FROM dba_hist_sqlstat
 WHERE sql_id = TRIM('&&sql_id.')
   AND executions_delta > 0
   AND optimizer_cost > 0
 GROUP BY
       plan_hash_value,
       snap_id ),
phv_stats AS (
SELECT plan_hash_value,
       MAX(avg_et_us) p100_et_us,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY avg_et_us) p99_et_us,
       PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY avg_et_us) p97_et_us,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY avg_et_us) p95_et_us,
       MAX(avg_cpu_us) p100_cpu_us,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY avg_cpu_us) p99_cpu_us,
       PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY avg_cpu_us) p97_cpu_us,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY avg_cpu_us) p95_cpu_us
  FROM phv_perf
 GROUP BY
       plan_hash_value ),
m AS (
SELECT plan_hash_value,
       SUM(elapsed_time)/SUM(executions) avg_et_us,
       SUM(cpu_time)/SUM(executions) avg_cpu_us,
       ROUND(SUM(buffer_gets)/SUM(executions)) avg_buffer_gets,
       ROUND(SUM(rows_processed)/SUM(executions), 3) avg_rows_processed,
       SUM(executions) executions,
       MIN(optimizer_cost) min_cost,
       MAX(optimizer_cost) max_cost
  FROM gv$sql
 WHERE sql_id = TRIM('&&sql_id.')
   AND executions > 0
   AND optimizer_cost > 0
 GROUP BY
       plan_hash_value ),
a AS (
SELECT plan_hash_value,
       SUM(elapsed_time_delta)/SUM(executions_delta) avg_et_us,
       SUM(cpu_time_delta)/SUM(executions_delta) avg_cpu_us,
       ROUND(SUM(buffer_gets_delta)/SUM(executions_delta)) avg_buffer_gets,
       ROUND(SUM(rows_processed_delta)/SUM(executions_delta), 3) avg_rows_processed,
       SUM(executions_delta) executions,
       MIN(optimizer_cost) min_cost,
       MAX(optimizer_cost) max_cost
  FROM dba_hist_sqlstat
 WHERE sql_id = TRIM('&&sql_id.')
   AND executions_delta > 0
   AND optimizer_cost > 0
 GROUP BY
       plan_hash_value )
SELECT 
       p.plan_hash_value,
       LPAD(TRIM(TO_CHAR(ROUND(a.avg_et_us/1e3, 6), '9999,990.000')), 11) avg_et_ms_awr,
       LPAD(TRIM(TO_CHAR(ROUND(m.avg_et_us/1e3, 6), '9999,990.000')), 11) avg_et_ms_mem,
       LPAD(TRIM(TO_CHAR(ROUND(a.avg_cpu_us/1e3, 6), '9999,990.000')), 11) avg_cpu_ms_awr,
       LPAD(TRIM(TO_CHAR(ROUND(m.avg_cpu_us/1e3, 6), '9999,990.000')), 11) avg_cpu_ms_mem,
       a.avg_buffer_gets avg_bg_awr,
       m.avg_buffer_gets avg_bg_mem,
       a.avg_rows_processed avg_row_awr,
       m.avg_rows_processed avg_row_mem,
       a.executions executions_awr,
       m.executions executions_mem,
       LEAST(NVL(m.min_cost, a.min_cost), NVL(a.min_cost, m.min_cost)) min_cost,
       GREATEST(NVL(m.max_cost, a.max_cost), NVL(a.max_cost, m.max_cost)) max_cost,
       p.nl,
       p.hj,
       p.mj,
       LPAD(TRIM(TO_CHAR(ROUND(s.p100_et_us/1e3, 6), '9999,990.000')), 11) p100_et_ms,
       LPAD(TRIM(TO_CHAR(ROUND(s.p99_et_us/1e3, 6), '9999,990.000')), 11) p99_et_ms,
       LPAD(TRIM(TO_CHAR(ROUND(s.p97_et_us/1e3, 6), '9999,990.000')), 11) p97_et_ms,
       LPAD(TRIM(TO_CHAR(ROUND(s.p95_et_us/1e3, 6), '9999,990.000')), 11) p95_et_ms,
       LPAD(TRIM(TO_CHAR(ROUND(s.p100_cpu_us/1e3, 6), '9999,990.000')), 11) p100_cpu_ms,
       LPAD(TRIM(TO_CHAR(ROUND(s.p99_cpu_us/1e3, 6), '9999,990.000')), 11) p99_cpu_ms,
       LPAD(TRIM(TO_CHAR(ROUND(s.p97_cpu_us/1e3, 6), '9999,990.000')), 11) p97_cpu_ms,
       LPAD(TRIM(TO_CHAR(ROUND(s.p95_cpu_us/1e3, 6), '9999,990.000')), 11) p95_cpu_ms
  FROM p, m, a, phv_stats s
 WHERE p.plan_hash_value = m.plan_hash_value(+)
   AND p.plan_hash_value = a.plan_hash_value(+)
   AND p.plan_hash_value = s.plan_hash_value(+)
 ORDER BY
       NVL(a.avg_et_us, m.avg_et_us), m.avg_et_us
/