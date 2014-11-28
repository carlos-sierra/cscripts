----------------------------------------------------------------------------------------
--
-- File name:   sql_with_multiple_plans.sql
--
-- Purpose:     Lists SQL Statements with multiple Execution Plans 
--              performing significantly different
--
-- Author:      Carlos Sierra
--
-- Version:     2014/11/28
--
-- Usage:       Lists SQL Statements that have more than one Execution Plan, and where
--              these plans have a history of significantly different performance.
--
-- Example:     @sql_with_multiple_plans.sql
--
-- Notes:       Developed and tested on 11.2.0.3.
--
--              Requires an Oracle Diagnostics Pack License since AWR data is accessed.
--
--              To further investigate poorly performing SQL use sqltxplain.sql or sqlhc 
--              (or planx.sql or sqlmon.sql or sqlash.sql).
--             
---------------------------------------------------------------------------------------
--
SPO sql_with_multiple_plans.txt;
DEF days_of_history_accessed = '31';
DEF max_num_rows = '20';

SET lin 300 ver OFF;
COL plans FOR 9999;
COL aprox_tot_secs HEA 'Approx|Total Secs';
COL med_secs_per_exec HEA 'Median Secs|Per Exec';
COL std_secs_per_exec HEA 'Std Dev Secs|Per Exec';
COL avg_secs_per_exec HEA 'Avg Secs|Per Exec';
COL min_secs_per_exec HEA 'Min Secs|Per Exec';
COL max_secs_per_exec HEA 'Max Secs|Per Exec';
COL sql_text_80 FOR A80;

PRO SQL Statements with multiple Execution Plans performing significantly different

WITH
per_phv AS (
SELECT h.dbid,
       h.sql_id,
       h.plan_hash_value, 
       MIN(s.begin_interval_time) min_time,
       MAX(s.end_interval_time) max_time,
       MEDIAN(h.elapsed_time_total / h.executions_total) med_time_per_exec,
       STDDEV(h.elapsed_time_total / h.executions_total) std_time_per_exec,
       AVG(h.elapsed_time_total / h.executions_total)    avg_time_per_exec,
       MIN(h.elapsed_time_total / h.executions_total)    min_time_per_exec,
       MAX(h.elapsed_time_total / h.executions_total)    max_time_per_exec,
       STDDEV(h.elapsed_time_total / h.executions_total) / AVG(h.elapsed_time_total / h.executions_total) std_dev,
       MAX(h.executions_total) executions_total,
       MEDIAN(h.elapsed_time_total / h.executions_total) * MAX(h.executions_total) total_elapsed_time
  FROM dba_hist_sqlstat h, 
       dba_hist_snapshot s
 WHERE h.executions_total > 1 
   AND h.plan_hash_value > 0
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
   AND CAST(s.end_interval_time AS DATE) > SYSDATE - &&days_of_history_accessed. 
 GROUP BY
       h.dbid,
       h.sql_id,
       h.plan_hash_value
),
ranked1 AS (
SELECT RANK () OVER (ORDER BY STDDEV(med_time_per_exec)/AVG(med_time_per_exec) DESC) rank_num1,
       dbid,
       sql_id,
       COUNT(*) plans,
       SUM(total_elapsed_time) total_elapsed_time,
       MIN(med_time_per_exec) min_med_time_per_exec,
       MAX(med_time_per_exec) max_med_time_per_exec
  FROM per_phv
 GROUP BY
       dbid,
       sql_id
HAVING COUNT(*) > 1
),
ranked2 AS (
SELECT RANK () OVER (ORDER BY r.total_elapsed_time DESC) rank_num2,
       r.rank_num1,
       r.sql_id,
       r.plans,
       p.plan_hash_value,
       TO_CHAR(CAST(p.min_time AS DATE), 'YYYY-MM-DD/HH24') min_time,
       TO_CHAR(CAST(p.max_time AS DATE), 'YYYY-MM-DD/HH24') max_time,
       TO_CHAR(ROUND(p.med_time_per_exec / 1e6, 3), '999,990.000') med_secs_per_exec,
       p.executions_total executions,
       TO_CHAR(ROUND(p.med_time_per_exec * p.executions_total / 1e6, 3), '999,990.000') aprox_tot_secs,
       TO_CHAR(ROUND(p.std_time_per_exec / 1e6, 3), '999,990.000') std_secs_per_exec,
       TO_CHAR(ROUND(p.avg_time_per_exec / 1e6, 3), '999,990.000') avg_secs_per_exec,
       TO_CHAR(ROUND(p.min_time_per_exec / 1e6, 3), '999,990.000') min_secs_per_exec,
       TO_CHAR(ROUND(p.max_time_per_exec / 1e6, 3), '999,990.000') max_secs_per_exec,
       REPLACE((SELECT DBMS_LOB.SUBSTR(s.sql_text, 80) FROM dba_hist_sqltext s WHERE s.dbid = r.dbid AND s.sql_id = r.sql_id), CHR(10)) sql_text_80
  FROM ranked1 r,
       per_phv p
 WHERE r.rank_num1 <= &&max_num_rows. * 5
   AND p.dbid = r.dbid
   AND p.sql_id = r.sql_id
)
SELECT --r.rank_num2,
       --r.rank_num1,
       r.sql_id,
       r.plans,
       r.plan_hash_value,
       r.min_time,
       r.max_time,
       r.med_secs_per_exec,
       r.executions,
       r.aprox_tot_secs,
       r.std_secs_per_exec,
       r.avg_secs_per_exec,
       r.min_secs_per_exec,
       r.max_secs_per_exec,
       r.sql_text_80
  FROM ranked2 r
 WHERE rank_num2 <= &&max_num_rows.
 ORDER BY
       r.rank_num2,
       r.sql_id,
       r.min_time,
       r.plan_hash_value
/

SPO OFF;
