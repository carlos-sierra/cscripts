-- cs_plans_performance.sql: called by multiple cs_sprf*, cs_spch*, cs_spbl*, and by: cs_planx.sql, cs_sqlperf.sql and cs_purge_cursor.sql 
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash|Value';
COL et_ms_per_exec_awr FOR 99,999,990.000 HEA 'DB|Latency(ms)|Per Exec|AWR';
COL et_ms_per_exec_mem FOR 99,999,990.000 HEA 'DB|Latency(ms)|Per Exec|CUR';
COL cpu_ms_per_exec_awr FOR 99,999,990.000 HEA 'CPU|Latency(ms)|Per Exec|AWR';
COL cpu_ms_per_exec_mem FOR 99,999,990.000 HEA 'CPU|Latency(ms)|Per Exec|CUR';
COL gets_per_exec_awr FOR 999,999,990 HEA 'Buffer|Gets|Per Exec|AWR';
COL gets_per_exec_mem FOR 999,999,990 HEA 'Buffer|Gets|Per Exec|CUR';
COL rows_per_exec_awr FOR 999,999,990.000 HEA 'Rows|Processed|Per Exec|AWR';
COL rows_per_exec_mem FOR 999,999,990.000 HEA 'Rows|Processed|Per Exec|CUR';
COL executions_awr FOR 999,999,999,990 HEA 'Total|Executions|AWR';
COL executions_mem FOR 999,999,999,990 HEA 'Total|Executions|CUR';
COL min_optimizer_cost FOR 9999999999 HEA 'Optimizer|Cost|MIN';
COL max_optimizer_cost FOR 9999999999 HEA 'Optimizer|Cost|MAX';
COL nl FOR 999;
COL hj FOR 999;
COL mj FOR 999;
COL p100_et_ms_per_exec FOR 99,999,990.000 HEA 'DB|Latency(ms)|Per Exec|MAX';
COL p99_et_ms_per_exec FOR 99,999,990.000 HEA 'DB|Latency(ms)|Per Exec|p99 PCTL';
COL p97_et_ms_per_exec FOR 99,999,990.000 HEA 'DB|Latency(ms)|Per Exec|p97 PCTL';
COL p95_et_ms_per_exec FOR 99,999,990.000 HEA 'DB|Latency(ms)|Per Exec|p95 PCTL';
COL p100_cpu_ms_per_exec FOR 99,999,990.000 HEA 'CPU|Latency(ms)|Per Exec|MAX';
COL p99_cpu_ms_per_exec FOR 99,999,990.000 HEA 'CPU|Latency(ms)|Per Exec|p99 PCTL';
COL p97_cpu_ms_per_exec FOR 99,999,990.000 HEA 'CPU|Latency(ms)|Per Exec|p97 PCTL';
COL p95_cpu_ms_per_exec FOR 99,999,990.000 HEA 'CPU|Latency(ms)|Per Exec|p95 PCTL';
COL pdb_name FOR A30 HEA 'PDB Name' TRUNC;
COL min_time FOR A23 HEA 'Begin Timestamp';
COL max_time FOR A23 HEA 'End Timestamp';
COL sep0 FOR A1 HEA '+|!|!|!';
COL sep1 FOR A1 HEA '+|!|!|!';
COL sep2 FOR A1 HEA '+|!|!|!';
COL sep3 FOR A1 HEA '+|!|!|!';
COL sep4 FOR A1 HEA '+|!|!|!';
COL sep5 FOR A1 HEA '+|!|!|!';
COL sep6 FOR A1 HEA '+|!|!|!';
--
PRO
PRO PLANS PERFORMANCE - SUMMARY (dba_hist_sqlstat AWR and gv$sql CUR)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
pm AS (
SELECT con_id, plan_hash_value, operation,
       CASE operation WHEN 'NESTED LOOPS' THEN COUNT(DISTINCT id) ELSE 0 END AS nl,
       CASE operation WHEN 'HASH JOIN' THEN COUNT(DISTINCT id) ELSE 0 END AS hj,
       CASE operation WHEN 'MERGE JOIN' THEN COUNT(DISTINCT id) ELSE 0 END AS mj
  FROM gv$sql_plan
 WHERE sql_id = '&&cs_sql_id.'
 GROUP BY
       con_id, plan_hash_value, operation 
),
pa AS (
SELECT con_id, plan_hash_value, operation,
       CASE operation WHEN 'NESTED LOOPS' THEN COUNT(DISTINCT id) ELSE 0 END AS nl,
       CASE operation WHEN 'HASH JOIN' THEN COUNT(DISTINCT id) ELSE 0 END AS hj,
       CASE operation WHEN 'MERGE JOIN' THEN COUNT(DISTINCT id) ELSE 0 END AS mj
  FROM dba_hist_sql_plan
 WHERE sql_id = '&&cs_sql_id.'
   AND dbid = TO_NUMBER('&&cs_dbid.') 
 GROUP BY
       con_id, plan_hash_value, operation 
),
pm_pa AS (
SELECT con_id, plan_hash_value, MAX(nl) AS nl, MAX(hj) AS hj, MAX(mj) AS mj
  FROM pm
 GROUP BY
       con_id, plan_hash_value
 UNION
SELECT con_id, plan_hash_value, MAX(nl) AS nl, MAX(hj) AS hj, MAX(mj) AS mj
  FROM pa
 GROUP BY
       con_id, plan_hash_value 
),
p AS (
SELECT con_id, plan_hash_value, MAX(nl) AS nl, MAX(hj) AS hj, MAX(mj) AS mj
  FROM pm_pa
 GROUP BY
       con_id, plan_hash_value 
),
phv_perf AS (       
SELECT con_id, plan_hash_value, snap_id,
       SUM(elapsed_time_delta)/NULLIF(SUM(executions_delta), 0)/1e3 AS et_ms_per_exec,
       SUM(cpu_time_delta)/NULLIF(SUM(executions_delta), 0)/1e3 AS cpu_ms_per_exec
  FROM dba_hist_sqlstat
 WHERE sql_id = '&&cs_sql_id.'
--    AND executions_delta > 0 -- not needed!
   AND optimizer_cost > 0 -- if 0 or null then whole row is suspected bogus
 GROUP BY
       con_id, plan_hash_value, snap_id 
),
phv_stats AS (
SELECT con_id, plan_hash_value,
       MAX(et_ms_per_exec) p100_et_ms_per_exec,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY et_ms_per_exec) p99_et_ms_per_exec,
       PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY et_ms_per_exec) p97_et_ms_per_exec,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY et_ms_per_exec) p95_et_ms_per_exec,
       MAX(cpu_ms_per_exec) p100_cpu_ms_per_exec,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY cpu_ms_per_exec) p99_cpu_ms_per_exec,
       PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY cpu_ms_per_exec) p97_cpu_ms_per_exec,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY cpu_ms_per_exec) p95_cpu_ms_per_exec
  FROM phv_perf
 GROUP BY
       con_id, plan_hash_value 
),
m AS (
SELECT con_id, plan_hash_value,
       SUM(elapsed_time)/NULLIF(SUM(executions), 0)/1e3 AS et_ms_per_exec,
       SUM(cpu_time)/NULLIF(SUM(executions), 0)/1e3 AS cpu_ms_per_exec,
       SUM(buffer_gets)/NULLIF(SUM(executions), 0) AS gets_per_exec,
       SUM(rows_processed)/NULLIF(SUM(executions), 0) AS rows_per_exec,
       SUM(executions) AS executions,
       MIN(optimizer_cost) AS min_optimizer_cost,
       MAX(optimizer_cost) AS max_optimizer_cost,
       MIN(last_active_time) AS min_time,
       MAX(last_active_time) AS max_time
  FROM gv$sql
 WHERE sql_id = '&&cs_sql_id.'
--    AND executions >= 0 -- not needed!
   AND optimizer_cost > 0 -- if 0 or null then whole row is suspected bogus
 GROUP BY
       con_id, plan_hash_value 
),
a AS (
SELECT h.con_id, h.plan_hash_value,
       SUM(h.elapsed_time_delta)/NULLIF(SUM(h.executions_delta), 0)/1e3 AS et_ms_per_exec,
       SUM(h.cpu_time_delta)/NULLIF(SUM(h.executions_delta), 0)/1e3 AS cpu_ms_per_exec,
       SUM(h.buffer_gets_delta)/NULLIF(SUM(h.executions_delta), 0) AS gets_per_exec,
       SUM(h.rows_processed_delta)/NULLIF(SUM(h.executions_delta), 0) AS rows_per_exec,
       SUM(h.executions_delta) AS executions,
       MIN(h.optimizer_cost) AS min_optimizer_cost,
       MAX(h.optimizer_cost) AS max_optimizer_cost,
       CAST(MIN(s.begin_interval_time) AS DATE) AS min_time,
       CAST(MAX(s.end_interval_time) AS DATE) AS max_time
  FROM dba_hist_sqlstat h,
       dba_hist_snapshot s
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
--    AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.sql_id = '&&cs_sql_id.'
--    AND h.executions_delta >= 0 -- not needed!
   AND h.optimizer_cost > 0 -- if 0 or null then whole row is suspected bogus
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
 GROUP BY
       h.con_id, h.plan_hash_value 
)
SELECT '!' AS sep0,
       p.plan_hash_value,
       '|' AS sep1,
       a.et_ms_per_exec AS et_ms_per_exec_awr,
       m.et_ms_per_exec AS et_ms_per_exec_mem,
       a.cpu_ms_per_exec AS cpu_ms_per_exec_awr,
       m.cpu_ms_per_exec AS cpu_ms_per_exec_mem,
       '!' AS sep2,
       a.executions AS executions_awr,
       m.executions AS executions_mem,
       '!' AS sep3,
       a.gets_per_exec AS gets_per_exec_awr,
       m.gets_per_exec AS gets_per_exec_mem,
       a.rows_per_exec AS rows_per_exec_awr,
       m.rows_per_exec AS rows_per_exec_mem,
       '!' AS sep4,
       s.p100_et_ms_per_exec,
       s.p99_et_ms_per_exec,
       s.p97_et_ms_per_exec,
       s.p95_et_ms_per_exec,
       s.p100_cpu_ms_per_exec,
       s.p99_cpu_ms_per_exec,
       s.p97_cpu_ms_per_exec,
       s.p95_cpu_ms_per_exec,
       '!' AS sep5,
       LEAST(COALESCE(a.min_optimizer_cost, m.min_optimizer_cost), COALESCE(m.min_optimizer_cost, a.min_optimizer_cost))AS min_optimizer_cost,
       GREATEST(COALESCE(a.max_optimizer_cost, m.max_optimizer_cost), COALESCE(m.max_optimizer_cost, a.max_optimizer_cost)) AS max_optimizer_cost,
       p.nl,
       p.hj,
       p.mj,
       '!' AS sep6,
       c.name AS pdb_name,
       LEAST(COALESCE(a.min_time, m.min_time), COALESCE(m.min_time, a.min_time)) AS min_time,
       GREATEST(COALESCE(m.max_time, a.max_time), COALESCE(a.max_time, m.max_time)) AS max_time
  FROM p, m, a, phv_stats s, v$containers c
 WHERE p.plan_hash_value = m.plan_hash_value(+) AND p.con_id = m.con_id(+)
   AND p.plan_hash_value = a.plan_hash_value(+) AND p.con_id = a.con_id(+)
   AND p.plan_hash_value = s.plan_hash_value(+) AND p.con_id = s.con_id(+)
   AND c.con_id = p.con_id
 ORDER BY
       LEAST(COALESCE(a.et_ms_per_exec, m.et_ms_per_exec), COALESCE(m.et_ms_per_exec, a.et_ms_per_exec))
/
--