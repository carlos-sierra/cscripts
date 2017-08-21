----------------------------------------------------------------------------------------
--
-- File name:   sqlperf.sql
--
-- Purpose:     Basic SQL performance metrics for a given SQL
--
-- Author:      Carlos Sierra
--
-- Version:     2017/08/24
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
---------------------------------------------------------------------------------------
--
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
PRO PLANS PERFORMANCE
PRO ~~~~~~~~~~~~~~~~~
WITH
p AS (
SELECT plan_hash_value
  FROM gv$sql_plan
 WHERE sql_id = TRIM('&&sql_id.')
   AND other_xml IS NOT NULL
 UNION
SELECT plan_hash_value
  FROM dba_hist_sql_plan
 WHERE sql_id = TRIM('&&sql_id.')
   AND other_xml IS NOT NULL ),
m AS (
SELECT plan_hash_value,
       SUM(elapsed_time)/SUM(executions) avg_et_secs,
       SUM(executions) executions
  FROM gv$sql
 WHERE sql_id = TRIM('&&sql_id.')
   AND executions > 0
 GROUP BY
       plan_hash_value ),
a AS (
SELECT plan_hash_value,
       SUM(elapsed_time_delta)/SUM(executions_delta) avg_et_secs,
       SUM(executions_delta) executions
  FROM dba_hist_sqlstat
 WHERE sql_id = TRIM('&&sql_id.')
   AND executions_delta > 0
 GROUP BY
       plan_hash_value )
SELECT 
       TO_CHAR(ROUND(m.avg_et_secs/1e6, 6), '999,990.000000') avg_et_secs_mem,
       TO_CHAR(ROUND(a.avg_et_secs/1e6, 6), '999,990.000000') avg_et_secs_awr,
       p.plan_hash_value,
       m.executions executions_mem,
       a.executions executions_awr
       --TO_CHAR(ROUND(NVL(m.avg_et_secs, a.avg_et_secs)/1e6, 6), '999,990.000000') avg_et_secs
  FROM p, m, a
 WHERE p.plan_hash_value = m.plan_hash_value(+)
   AND p.plan_hash_value = a.plan_hash_value(+)
 ORDER BY
       NVL(m.avg_et_secs, a.avg_et_secs) NULLS LAST, a.avg_et_secs;
       
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