----------------------------------------------------------------------------------------
--
-- File name:   sql_regression.sql
--
-- Purpose:     Find SQL statements that have had a performance regression or improvement
--              of more than 10x during the past 7 days (10 and 7 are default values)
--
-- Author:      Carlos Sierra
--
-- Version:     2017/08/21
--
-- Usage:       Latency of a critical transaction has gone south on a PDB and no clear
--              evidence is visible on OEM. Suspecting SQL regression or Locking.
--
--              Designed to be used on OLTP loads, where transaction rate is high.
--              
--              Pass values (when asked) for change threshold (default of 10 times) and 
--              how far back in history you want to review (default of 7 days).
--
--              Execute connected into the PDB of interest, or CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> ALTER SESSION SET CONTAINER = vcn_v2;
--              SQL> @sql_regression.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
--              Use together with sql_locking_*.sql scripts.          
--
--              To further dive into SQL performance diagnostics use SQLd360.
--             
---------------------------------------------------------------------------------------
--
ACC change_factor PROMPT 'Change factor (i.e. 10, 5, 2) default 10: '
ACC sample_time PROMPT 'Date and Time (i.e. 2017-09-15T18:00:07): ';

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
BREAK ON inst SKIP 1 ON container_id ON sql_id SKIP 1 ON sql_text_100_only;
COL inst FOR 9990 HEA 'Inst';
COL new_snap_id FOR 9999999 HEA 'Snap|After';
COL lag_snap_id FOR 9999999 HEA 'Snap|Before';
COL after_date FOR A19 HEA 'Snap End Date|After Change';
COL before_date FOR A19 HEA 'Snap End Date|Before Change';
COL elapsed_secs_per_exec FOR 99,990.000000 HEA 'Seconds|per Execution|After Change';
COL lag_elapsed_secs_per_exec FOR 99,990.000000 HEA 'Seconds|per Execution|Before Change';
COL change FOR A7 HEA 'Change';
COL bg_per_exec FOR 999999999999 HEA 'Buffer Gets|per Execution|After Change';
COL lag_bg_per_exec FOR 999999999999 HEA 'Buffer Gets|per Execution|Before Change';
COL rows_per_exec FOR 999,999,990.000 HEA 'Rows Returned|per Execution|After Change';
COL lag_rows_per_exec FOR 999,999,990.000 HEA 'Rows Returned|per Execution|Before Change';
COL execs_per_sec FOR 999,990.000 HEA 'Executions|per Second|After Change';
COL lag_execs_per_sec FOR 999,990.000 HEA 'Executions|per Second|Before Change';
COL new_plan_hash_value FOR A15 HEA 'Plan Hash Value|After Change';
COL lag_plan_hash_value FOR A15 HEA 'Plan Hash Value|Before Change';
COL sql_text_100_only FOR A100 HEA 'SQL Text';
COL container_id FOR 999999 HEA 'CON_ID';
COL parsing_schema_name FOR A30 HEA 'Parsing Schema Name';

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;
COL this_dbid NEW_V this_dbid;
SELECT dbid this_dbid FROM v$database;
COL change_factor NEW_V change_factor;
SELECT NVL('&&change_factor.', '10') change_factor FROM DUAL;

SPO sql_regression_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO CHANGE_FACTOR: &&change_factor.x
PRO SAMPLE_TIME: &&sample_time.

PRO
PRO SQL statements for which seconds per execution seems to have changed more than &&change_factor.x around &&sample_time..
PRO

WITH 
hist_sqlstat AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       -- gets all history to provision for lag of first row within window,
       -- and if sql was performing better there may be large gaps before window.
       dbid,
       instance_number,
       sql_id,
       con_id,
       snap_id,
       COUNT(*) execution_plans,
       MIN(plan_hash_value) min_plan_hash_value,
       MAX(plan_hash_value) max_plan_hash_value,
       SUM(executions_delta) executions_delta,
       SUM(elapsed_time_delta) elapsed_time_delta,
       SUM(buffer_gets_delta) buffer_gets_delta,
       SUM(rows_processed_delta) rows_processed_delta
  FROM dba_hist_sqlstat
 WHERE dbid = &&this_dbid.
   AND executions_delta > 0
   AND con_id > 2
 GROUP BY
       dbid,
       instance_number,
       sql_id,
       con_id,
       snap_id
),
hist_sqlstat_extended AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       -- gets lag row and projects column into current row.
       -- gets elapsed seconds per Executionution.
       -- gets plan hash value if there is only one, else plan count.
       h.dbid,
       h.instance_number,
       h.sql_id,
       h.con_id,
       h.snap_id,
       LAG(h.snap_id) OVER (PARTITION BY h.dbid, h.instance_number, h.sql_id ORDER BY h.snap_id) lag_snap_id,       
       ROUND(h.elapsed_time_delta/GREATEST(h.executions_delta,1)/1e6, 6) elapsed_secs_per_exec,
       LAG(ROUND(h.elapsed_time_delta/GREATEST(h.executions_delta,1)/1e6, 6)) OVER (PARTITION BY h.dbid, h.instance_number, h.sql_id ORDER BY h.snap_id) lag_elapsed_secs_per_exec,
       h.executions_delta,
       LAG(h.executions_delta) OVER (PARTITION BY h.dbid, h.instance_number, h.sql_id ORDER BY h.snap_id) lag_executions_delta,
       h.elapsed_time_delta,
       LAG(h.elapsed_time_delta) OVER (PARTITION BY h.dbid, h.instance_number, h.sql_id ORDER BY h.snap_id) lag_elapsed_time_delta,
       h.buffer_gets_delta,
       LAG(h.buffer_gets_delta) OVER (PARTITION BY h.dbid, h.instance_number, h.sql_id ORDER BY h.snap_id) lag_buffer_gets_delta,
       h.rows_processed_delta,
       LAG(h.rows_processed_delta) OVER (PARTITION BY h.dbid, h.instance_number, h.sql_id ORDER BY h.snap_id) lag_rows_processed_delta,
       CASE h.execution_plans WHEN 1 THEN TO_CHAR(h.min_plan_hash_value) ELSE h.execution_plans||' plans' END plan_hash_value,
       LAG(CASE h.execution_plans WHEN 1 THEN TO_CHAR(h.min_plan_hash_value) ELSE h.execution_plans||' plans' END) OVER (PARTITION BY h.dbid, h.instance_number, h.sql_id ORDER BY h.snap_id) lag_plan_hash_value
  FROM hist_sqlstat h
),
hist_sqlstat_extended_plus AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       -- gets snapshot end dates.
       -- get duration of both selected snaps (before and after).
       -- filters on window of interest (last Y days).
       -- filters on change threshold (where seconds per Executionution was higher/lower than X times).
       h.dbid,
       h.instance_number,
       h.sql_id,
       h.con_id,
       h.snap_id,
       CAST(s1.end_interval_time AS DATE) after_date,
       24 * 60 * 60 * (CAST(s1.end_interval_time AS DATE) - CAST(s1.begin_interval_time AS DATE)) after_secs,
       h.lag_snap_id,       
       CAST(s2.end_interval_time AS DATE) before_date,
       24 * 60 * 60 * (CAST(s2.end_interval_time AS DATE) - CAST(s2.begin_interval_time AS DATE)) before_secs,
       h.elapsed_secs_per_exec,
       h.lag_elapsed_secs_per_exec,
       h.executions_delta,
       h.lag_executions_delta,
       h.elapsed_time_delta,
       h.lag_elapsed_time_delta,
       h.buffer_gets_delta,
       h.lag_buffer_gets_delta,
       h.rows_processed_delta,
       h.lag_rows_processed_delta,
       h.plan_hash_value,
       h.lag_plan_hash_value
  FROM hist_sqlstat_extended h,
       dba_hist_snapshot s1,
       dba_hist_snapshot s2
 WHERE h.elapsed_secs_per_exec > 0
   AND (h.lag_elapsed_secs_per_exec > 0 OR h.lag_elapsed_secs_per_exec IS NULL)
   AND ((h.elapsed_secs_per_exec/h.lag_elapsed_secs_per_exec) > &&change_factor. OR (h.lag_elapsed_secs_per_exec/h.elapsed_secs_per_exec) > &&change_factor. OR h.lag_elapsed_secs_per_exec IS NULL)
   AND s1.snap_id = h.snap_id 
   AND s1.dbid = h.dbid 
   AND s1.instance_number = h.instance_number
   AND CAST(s1.end_interval_time AS DATE) BETWEEN TO_DATE('&&sample_time.', 'YYYY-MM-DD"T"HH24:MI:SS') - 1 AND TO_DATE('&&sample_time.', 'YYYY-MM-DD"T"HH24:MI:SS') + 1 -- +/- 1d
   AND s2.snap_id(+) = h.lag_snap_id 
   AND s2.dbid(+) = h.dbid 
   AND s2.instance_number(+) = h.instance_number
)
SELECT 
       -- computes buffer gets and rows per Executionution.
       -- computes number of executions per second.
       h.instance_number inst,
       h.con_id container_id,       
       h.sql_id,
       h.lag_snap_id,
       TO_CHAR(h.before_date, 'YYYY-MM-DD"T"HH24:MI:SS') before_date,
       h.snap_id new_snap_id,
       TO_CHAR(h.after_date, 'YYYY-MM-DD"T"HH24:MI:SS') after_date,
       h.lag_elapsed_secs_per_exec,
       h.elapsed_secs_per_exec,
       CASE 
         WHEN (h.elapsed_secs_per_exec/h.lag_elapsed_secs_per_exec) > &&change_factor. THEN LPAD('-'||ROUND(h.elapsed_secs_per_exec/h.lag_elapsed_secs_per_exec)||'x', 6)
         WHEN (h.lag_elapsed_secs_per_exec/h.elapsed_secs_per_exec) > &&change_factor. THEN LPAD('+'||ROUND(h.lag_elapsed_secs_per_exec/h.elapsed_secs_per_exec)||'x', 6)
       END change,
       ROUND(h.lag_buffer_gets_delta/GREATEST(h.lag_executions_delta,1)) lag_bg_per_exec,
       ROUND(h.buffer_gets_delta/GREATEST(h.executions_delta,1)) bg_per_exec,       
       ROUND(h.lag_rows_processed_delta/GREATEST(h.lag_executions_delta,1),3) lag_rows_per_exec,
       ROUND(h.rows_processed_delta/GREATEST(h.executions_delta,1),3) rows_per_exec,  
       ROUND(h.lag_executions_delta/h.before_secs,3) lag_execs_per_sec,
       ROUND(h.executions_delta/h.after_secs,3) execs_per_sec,
       h.lag_plan_hash_value,
       h.plan_hash_value new_plan_hash_value,
       (SELECT SUBSTR(q.parsing_schema_name, 1, 30) FROM v$sql q WHERE q.sql_id = h.sql_id AND q.con_id = h.con_id AND ROWNUM = 1) parsing_schema_name,
       (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sql q WHERE q.sql_id = h.sql_id AND q.con_id = h.con_id AND ROWNUM = 1) sql_text_100_only
  FROM hist_sqlstat_extended_plus h
 WHERE h.con_id > 2
 ORDER BY
       h.dbid,
       h.instance_number,
       h.con_id,
       h.sql_id,
       h.snap_id
/

PRO
PRO Investigate further using SQLd360, else planx.sql, else sqlperf.sql.
PRO 

SPO OFF;
CL BREAK;
