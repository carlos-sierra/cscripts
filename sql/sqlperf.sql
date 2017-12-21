----------------------------------------------------------------------------------------
--
-- File name:   sqlperf.sql
--
--              *** Requires Oracle Diagnostics Pack License ***
--
-- Purpose:     Basic SQL performance metrics for a given SQL
--
-- Author:      Carlos Sierra
--
-- Version:     2017/11/04
--
-- Usage:       Execute connected into the PDB of interest.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sqlperf.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
--              To further dive into SQL performance diagnostics use SQLd360.
--             
--              *** Requires Oracle Diagnostics Pack License ***
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

PRO
PRO 1. Enter SQL_ID (required)
DEF sql_id = '&1.';
PRO

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';

SPO sqlperf_&&sql_id._&&current_time..txt;
PRO SQL_ID: &&sql_id.
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

COL avg_et_ms_awr FOR A11 HEA 'ET Avg|AWR (ms)';
COL avg_et_ms_mem FOR A11 HEA 'ET Avg|MEM (ms)';
COL avg_cpu_ms_awr FOR A11 HEA 'CPU Avg|AWR (ms)';
COL avg_cpu_ms_mem FOR A11 HEA 'CPU Avg|MEM (ms)';
COL avg_bg_awr FOR 999,999,990 HEA 'BG Avg|AWR';
COL avg_bg_mem FOR 999,999,990 HEA 'BG Avg|MEM';
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
       NVL(a.avg_et_us, m.avg_et_us), m.avg_et_us;
       
PRO
PRO DBA_HIST_SQLSTAT (summary by phv)
PRO ~~~~~~~~~~~~~~~~
SELECT plan_hash_value,
       TO_CHAR(ROUND(SUM(elapsed_time_delta)/SUM(executions_delta)/1e6,6), '999,990.000000') et_secs_per_exec,
       TO_CHAR(ROUND(SUM(cpu_time_delta)/SUM(executions_delta)/1e6,6), '999,990.000000') cpu_secs_per_exec,
       ROUND(SUM(buffer_gets_delta)/SUM(executions_delta)) buffers_per_exec,
       TO_CHAR(ROUND(SUM(rows_processed_delta)/SUM(executions_delta), 3), '999,999,999,990.000') rows_per_exec,
       SUM(executions_delta) executions,
       TO_CHAR(ROUND(SUM(elapsed_time_delta)/1e6,6), '999,999,999,990') et_secs_tot,
       TO_CHAR(ROUND(SUM(cpu_time_delta)/1e6,6), '999,999,999,990') cpu_secs_tot
  FROM dba_hist_sqlstat
 WHERE sql_id = '&&sql_id.'
   AND executions_delta > 0
 GROUP BY
       plan_hash_value
 ORDER BY
       2;

COL shar FOR A4;
COL obsl FOR A4;
COL obj_sta FOR A7;

PRO
PRO GV$SQL (plan stability)
PRO ~~~~~~
SELECT inst_id,
       child_number,
       plan_hash_value,
       is_shareable shar,
       is_obsolete obsl,
       SUBSTR(object_status, 1, 7) obj_sta, 
       sql_plan_baseline,
       sql_profile,
       sql_patch
  FROM gv$sql
 WHERE sql_id = '&&sql_id.'
   AND executions > 0
 ORDER BY
       inst_id,
       child_number;

COL sens FOR A4;
COL aware FOR A5;
COL u_exec FOR 999999;
COL last_load_time FOR A19;

PRO
PRO GV$SQL (performance)
PRO ~~~~~~
SELECT inst_id,
       child_number,
       plan_hash_value,
       is_bind_sensitive sens,
       is_bind_aware aware,
       is_shareable shar,
       is_obsolete obsl,
       SUBSTR(object_status, 1, 7) obj_sta, 
       users_executing u_exec,
       TO_CHAR(ROUND(elapsed_time/executions/1e6,6), '999,990.000000') et_secs_per_exec,
       TO_CHAR(ROUND(cpu_time/executions/1e6,6), '999,990.000000') cpu_secs_per_exec,
       executions,
       TO_CHAR(ROUND(elapsed_time/1e6,6), '999,999,999,990') et_secs_tot,
       TO_CHAR(ROUND(cpu_time/1e6,6), '999,999,999,990') cpu_secs_tot,
       ROUND(buffer_gets/executions) buffers_per_exec,
       TO_CHAR(ROUND(rows_processed/executions, 3), '999,999,999,990.000') rows_per_exec,
       last_load_time,
       TO_CHAR(last_active_time, 'YYYY-MM-DD"T"HH24:MI:SS') last_active_time,
       invalidations,
       loads
  FROM gv$sql
 WHERE sql_id = '&&sql_id.'
   AND executions > 0
 ORDER BY
       inst_id,
       child_number;

COL first_load_time FOR A19;

PRO
PRO GV$SQLAREA
PRO ~~~~~~~~~~
SELECT inst_id,
       version_count,
       loaded_versions,
       invalidations,
       loads,
       open_versions,
       --kept_versions,
       users_opening,
       users_executing,
       first_load_time,
       last_load_time,
       last_active_time,
       plan_hash_value
  FROM gv$sqlarea
 WHERE sql_id = '&&sql_id.'
 ORDER BY
       inst_id;

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
COL bind_value FOR A120;

PRO
PRO GV$SQL_BIND_CAPTURE (sample)
PRO ~~~~~~~~~~
SELECT inst_id,
       TO_CHAR(last_captured, 'YYYY-MM-DD"T"HH24:MI:SS') last_captured,
       child_number,
       position, 
       SUBSTR(name, 1, 30) bind_name,
       SUBSTR(value_string, 1, 120) bind_value
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
SELECT TO_CHAR(MAX(last_active_time), 'YYYY-MM-DD"T"HH24:MI:SS') last_active_time,
       plan_hash_value,
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
       SUM(CASE is_obsolete WHEN 'Y' THEN 1 ELSE 0 END) obsolete,
       SUM(CASE object_status WHEN 'VALID' THEN 1 ELSE 0 END) valid,
       SUM(CASE object_status WHEN 'INVALID_UNAUTH' THEN 1 ELSE 0 END) invalid,       
       ROUND(SUM(buffer_gets)/SUM(executions)) buffers_per_exec,
       TO_CHAR(ROUND(SUM(rows_processed)/SUM(executions), 3), '999,999,999,990.000') rows_per_exec
  FROM gv$sql
 WHERE sql_id = '&&sql_id.'
   AND executions > 0
 GROUP BY
       plan_hash_value
 ORDER BY
       1 DESC, 2;

SPO OFF;
