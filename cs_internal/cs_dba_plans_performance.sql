COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL avg_et_ms_awr FOR 99,999,990.000 HEA 'Avg Elapsed|Time AWR (ms)';
COL avg_et_ms_mem FOR 99,999,990.000 HEA 'Avg Elapsed|Time MEM (ms)';
COL avg_cpu_ms_awr FOR 99,999,990.000 HEA 'Avg CPU|Time AWR (ms)';
COL avg_cpu_ms_mem FOR 99,999,990.000 HEA 'Avg CPU|Time MEM (ms)';
COL avg_bg_awr FOR 999,999,999,990 HEA 'Avg|Buffer Gets|AWR';
COL avg_bg_mem FOR 999,999,999,990 HEA 'Avg|Buffer Gets|MEM';
COL avg_row_awr FOR 999,999,990.000 HEA 'Avg|Rows Processed|AWR';
COL avg_row_mem FOR 999,999,990.000 HEA 'Avg|Rows Processed|MEM';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL executions_awr FOR 999,999,999,999 HEA 'Executions|AWR';
COL executions_mem FOR 999,999,999,999 HEA 'Executions|MEM';
COL min_cost FOR 9,999,999,999 HEA 'MIN Cost';
COL max_cost FOR 9,999,999,999 HEA 'MAX Cost';
COL nl FOR 99;
COL hj FOR 99;
COL mj FOR 99;
COL p100_et_ms FOR 99,999,990.000 HEA 'ET 100th|Pctl (ms)';
COL p99_et_ms FOR 99,999,990.000 HEA 'ET 99th|Pctl (ms)';
COL p97_et_ms FOR 99,999,990.000 HEA 'ET 97th|Pctl (ms)';
COL p95_et_ms FOR 99,999,990.000 HEA 'ET 95th|Pctl (ms)';
COL p100_cpu_ms FOR 99,999,990.000 HEA 'CPU 100th|Pctl (ms)';
COL p99_cpu_ms FOR 99,999,990.000 HEA 'CPU 99th|Pctl (ms)';
COL p97_cpu_ms FOR 99,999,990.000 HEA 'CPU 97th|Pctl (ms)';
COL p95_cpu_ms FOR 99,999,990.000 HEA 'CPU 95th|Pctl (ms)';
COL min_time FOR A19 HEA 'Begin Time';
COL max_time FOR A19 HEA 'End Time';
--
PRO
PRO PLANS PERFORMANCE (dba_hist_sqlstat and v$sql)
PRO ~~~~~~~~~~~~~~~~~
WITH
pm AS (
SELECT con_id, plan_hash_value, operation,
       CASE operation WHEN 'NESTED LOOPS' THEN COUNT(DISTINCT id) ELSE 0 END nl,
       CASE operation WHEN 'HASH JOIN' THEN COUNT(DISTINCT id) ELSE 0 END hj,
       CASE operation WHEN 'MERGE JOIN' THEN COUNT(DISTINCT id) ELSE 0 END mj
  FROM v$sql_plan
 WHERE sql_id = '&&cs_sql_id.'
 GROUP BY
       con_id, plan_hash_value, operation 
),
pa AS (
SELECT con_id, plan_hash_value, operation,
       CASE operation WHEN 'NESTED LOOPS' THEN COUNT(DISTINCT id) ELSE 0 END nl,
       CASE operation WHEN 'HASH JOIN' THEN COUNT(DISTINCT id) ELSE 0 END hj,
       CASE operation WHEN 'MERGE JOIN' THEN COUNT(DISTINCT id) ELSE 0 END mj
  FROM dba_hist_sql_plan
 WHERE sql_id = '&&cs_sql_id.'
 GROUP BY
       con_id, plan_hash_value, operation 
),
pm_pa AS (
SELECT con_id, plan_hash_value, MAX(nl) nl, MAX(hj) hj, MAX(mj) mj
  FROM pm
 GROUP BY
       con_id, plan_hash_value
 UNION
SELECT con_id, plan_hash_value, MAX(nl) nl, MAX(hj) hj, MAX(mj) mj
  FROM pa
 GROUP BY
       con_id, plan_hash_value 
),
p AS (
SELECT con_id, plan_hash_value, MAX(nl) nl, MAX(hj) hj, MAX(mj) mj
  FROM pm_pa
 GROUP BY
       con_id, plan_hash_value 
),
phv_perf AS (       
SELECT con_id, plan_hash_value, snap_id,
       SUM(elapsed_time_delta)/SUM(executions_delta) avg_et_us,
       SUM(cpu_time_delta)/SUM(executions_delta) avg_cpu_us
  FROM dba_hist_sqlstat
 WHERE sql_id = '&&cs_sql_id.'
   AND executions_delta > 0
   AND optimizer_cost > 0
 GROUP BY
       con_id, plan_hash_value, snap_id 
),
phv_stats AS (
SELECT con_id, plan_hash_value,
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
       con_id, plan_hash_value 
),
m AS (
SELECT con_id, plan_hash_value,
       SUM(elapsed_time)/NULLIF(SUM(executions), 0) AS avg_et_us,
       SUM(cpu_time)/NULLIF(SUM(executions), 0) AS avg_cpu_us,
       ROUND(SUM(buffer_gets)/NULLIF(SUM(executions), 0)) AS avg_buffer_gets,
       ROUND(SUM(rows_processed)/NULLIF(SUM(executions), 0), 3) AS avg_rows_processed,
       SUM(executions) AS executions,
       MIN(optimizer_cost) AS min_cost,
       MAX(optimizer_cost) AS max_cost,
       MIN(last_active_time) AS min_time,
       MAX(last_active_time) AS max_time
  FROM v$sql
 WHERE sql_id = '&&cs_sql_id.'
   AND executions >= 0
   AND optimizer_cost > 0
 GROUP BY
       con_id, plan_hash_value 
),
a AS (
SELECT h.con_id, h.plan_hash_value,
       SUM(h.elapsed_time_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_et_us,
       SUM(h.cpu_time_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_cpu_us,
       SUM(h.buffer_gets_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_buffer_gets,
       SUM(h.rows_processed_delta)/NULLIF(SUM(h.executions_delta), 0) AS avg_rows_processed,
       SUM(h.executions_delta) AS executions,
       MIN(h.optimizer_cost) AS min_cost,
       MAX(h.optimizer_cost) AS max_cost,
       CAST(MIN(s.begin_interval_time) AS DATE) AS min_time,
       CAST(MAX(s.end_interval_time) AS DATE) AS max_time
  FROM dba_hist_sqlstat h,
       dba_hist_snapshot s
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.sql_id = '&&cs_sql_id.'
   AND h.executions_delta >= 0
   AND h.optimizer_cost > 0
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
 GROUP BY
       h.con_id, h.plan_hash_value 
)
SELECT --p.con_id,
       --c.name AS pdb_name,
       p.plan_hash_value,
       a.avg_et_us/1e3 AS avg_et_ms_awr,
       m.avg_et_us/1e3 AS avg_et_ms_mem,
       a.avg_cpu_us/1e3 AS avg_cpu_ms_awr,
       m.avg_cpu_us/1e3 AS avg_cpu_ms_mem,
       a.avg_buffer_gets AS avg_bg_awr,
       m.avg_buffer_gets AS avg_bg_mem,
       a.avg_rows_processed AS avg_row_awr,
       m.avg_rows_processed AS avg_row_mem,
       a.executions AS executions_awr,
       m.executions AS executions_mem,
       LEAST(NVL(m.min_cost, a.min_cost), NVL(a.min_cost, m.min_cost))AS  min_cost,
       GREATEST(NVL(m.max_cost, a.max_cost), NVL(a.max_cost, m.max_cost)) AS max_cost,
       p.nl,
       p.hj,
       p.mj,
       s.p100_et_us/1e3  AS p100_et_ms,
       s.p99_et_us/1e3   AS p99_et_ms,
       s.p97_et_us/1e3   AS p97_et_ms,
       s.p95_et_us/1e3   AS p95_et_ms,
       s.p100_cpu_us/1e3 AS p100_cpu_ms,
       s.p99_cpu_us/1e3  AS p99_cpu_ms,
       s.p97_cpu_us/1e3  AS p97_cpu_ms,
       s.p95_cpu_us/1e3  AS p95_cpu_ms,
       COALESCE(a.min_time, m.min_time) AS min_time,
       COALESCE(m.max_time, a.max_time) AS max_time
  FROM p, m, a, phv_stats s, v$containers c
 WHERE p.plan_hash_value = m.plan_hash_value(+) AND p.con_id = m.con_id(+)
   AND p.plan_hash_value = a.plan_hash_value(+) AND p.con_id = a.con_id(+)
   AND p.plan_hash_value = s.plan_hash_value(+) AND p.con_id = s.con_id(+)
   AND c.con_id = p.con_id
 ORDER BY
       p.con_id,
       NVL(a.avg_et_us, m.avg_et_us), m.avg_et_us
/
--