----------------------------------------------------------------------------------------
--
-- File name:   create_sql_plan_baseline.sql
--
-- Purpose:     Create a SQL Plan Baseline for a given SQL
--
-- Author:      Carlos Sierra
--
-- Version:     2017/12/01
--
-- Usage:       Execute connected into the PDB of interest.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @create_sql_plan_baseline.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
--              To further dive into SQL performance diagnostics use SQLd360.
--             
---------------------------------------------------------------------------------------
--
WHENEVER SQLERROR EXIT FAILURE;
COL not_on_root NOPRI;
SELECT CASE SYS_CONTEXT('USERENV', 'CON_NAME') WHEN 'CDB$ROOT' THEN TO_CHAR(1/0) END not_on_root FROM DUAL;
WHENEVER SQLERROR CONTINUE;

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT OFF;

ACC sql_id PROMPT 'SQL_ID: ';

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

SPO sql_plan_baseline_&&sql_id._&&current_time..txt;
PRO SQL_ID: &&sql_id.
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

---------------------------------------------------------------------------------------

VAR signature NUMBER;
VAR sql_text CLOB;

BEGIN
  SELECT exact_matching_signature, sql_text INTO :signature, :sql_text FROM gv$sql WHERE sql_id = '&&sql_id.' AND ROWNUM = 1;
END;
/

BEGIN
  IF :signature IS NULL THEN
    SELECT sql_text INTO :sql_text FROM dba_hist_sqltext WHERE sql_id = '&&sql_id.' AND ROWNUM = 1;
    :signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:sql_text);
  END IF;
END;
/

COL sql_handle NEW_V sql_handle;
SELECT sql_handle FROM dba_sql_plan_baselines WHERE signature = :signature AND ROWNUM = 1;

COL plan_name FOR A30;
COL created FOR A30;
COL last_executed FOR A30;
SELECT created, plan_name, origin, enabled, accepted, fixed, reproduced, last_executed, last_modified, description
FROM dba_sql_plan_baselines WHERE signature = :signature
ORDER BY created, plan_name;

---------------------------------------------------------------------------------------

COL avg_et_ms_awr FOR A11 HEA 'ET Avg|AWR (ms)';
COL avg_et_ms_mem FOR A11 HEA 'ET Avg|MEM (ms)';
COL avg_cpu_ms_awr FOR A11 HEA 'CPU Avg|AWR (ms)';
COL avg_cpu_ms_mem FOR A11 HEA 'CPU Avg|MEM (ms)';
COL avg_bg_awr FOR 999,999,990 HEA 'BG Avg|AWR';
COL avg_bg_mem FOR 999,999,990 HEA 'BG Avg|MEM';
COL avg_row_awr FOR 999,999,990 HEA 'Rows Avg|AWR';
COL avg_row_mem FOR 999,999,990 HEA 'Rows Avg|MEM';
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
       ROUND(SUM(rows_processed)/SUM(executions)) avg_rows_processed,
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
       ROUND(SUM(rows_processed_delta)/SUM(executions_delta)) avg_rows_processed,
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
       NVL(a.avg_et_us, m.avg_et_us), m.avg_et_us;

PRO
PRO Select up to 3 plans executed over 1000 times:
PRO
ACC plan_hash_value_1 PROMPT '1st Plan Hash Value: ';
ACC plan_hash_value_2 PROMPT '2nd Plan Hash Value (opt): ';
ACC plan_hash_value_3 PROMPT '3rd Plan Hash Value (opt): ';
PRO
ACC fixed_flag PROMPT 'FIXED (opt): ';
COL fixed NEW_V fixed;
SELECT CASE WHEN UPPER('&&fixed_flag.') IN ('Y', 'YES') THEN 'YES' ELSE 'NO' END fixed FROM DUAL;

---------------------------------------------------------------------------------------

VAR plans NUMBER;

BEGIN
  :plans := 0;
  :plans := DBMS_SPM.load_plans_from_cursor_cache(sql_id => '&&sql_id.', plan_hash_value => NVL(TO_NUMBER('&&plan_hash_value_1.'), -666), fixed => '&&fixed.');
END;
/
PRO Plans created from memory for PHV &&plan_hash_value_1.
PRINT plans

BEGIN
  :plans := 0;
  IF '&&plan_hash_value_2.' IS NOT NULL THEN
    :plans := DBMS_SPM.load_plans_from_cursor_cache(sql_id => '&&sql_id.', plan_hash_value => NVL(TO_NUMBER('&&plan_hash_value_2.'), -666), fixed => '&&fixed.');
  END IF;
END;
/
PRO Plans created from memory for PHV &&plan_hash_value_2.
PRINT plans

BEGIN
  :plans := 0;
  IF '&&plan_hash_value_3.' IS NOT NULL THEN
    :plans := DBMS_SPM.load_plans_from_cursor_cache(sql_id => '&&sql_id.', plan_hash_value => NVL(TO_NUMBER('&&plan_hash_value_3.'), -666), fixed => '&&fixed.');
  END IF;
END;
/
PRO Plans created from memory for PHV &&plan_hash_value_3.
PRINT plans

---------------------------------------------------------------------------------------

COL dbid NEW_V dbid NOPRI;
SELECT dbid FROM v$database;

COL begin_snap_id NEW_V begin_snap_id NOPRI;
COL end_snap_id NEW_V end_snap_id NOPRI;

SELECT MIN(p.snap_id) begin_snap_id, MAX(p.snap_id) end_snap_id
  FROM dba_hist_sqlstat p,
       dba_hist_snapshot s
 WHERE p.dbid = &&dbid
   AND p.sql_id = '&&sql_id.'
   AND s.snap_id = p.snap_id
   AND s.dbid = p.dbid
   AND s.instance_number = p.instance_number;

VAR sqlset_name VARCHAR2(30);
EXEC :sqlset_name := REPLACE('s_&&sql_id.', ' ');
PRINT sqlset_name;

SET SERVEROUT ON;
VAR plans NUMBER;
DECLARE
  l_sqlset_name VARCHAR2(30);
  l_description VARCHAR2(256);
  sts_cur       SYS.DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
  :plans := 0;
  l_sqlset_name := :sqlset_name;
  l_description := 'SQL_ID:&&sql_id.BEGIN:&&begin_snap_id.END:&&end_snap_id.';
  l_description := REPLACE(REPLACE(l_description, ' '), ',', ', ');

  BEGIN
    DBMS_OUTPUT.put_line('dropping sqlset: '||l_sqlset_name);
    SYS.DBMS_SQLTUNE.drop_sqlset (
      sqlset_name  => l_sqlset_name,
      sqlset_owner => USER );
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.put_line(SQLERRM||' while trying to drop STS: '||l_sqlset_name||' (safe to ignore)');
  END;

  l_sqlset_name :=
  SYS.DBMS_SQLTUNE.create_sqlset (
    sqlset_name  => l_sqlset_name,
    description  => l_description,
    sqlset_owner => USER );
  DBMS_OUTPUT.put_line('created sqlset: '||l_sqlset_name);

  OPEN sts_cur FOR
    SELECT VALUE(p)
      FROM TABLE(DBMS_SQLTUNE.select_workload_repository (&&begin_snap_id., &&end_snap_id.,
      q'[sql_id = '&&sql_id.' AND plan_hash_value IN (NVL(TO_NUMBER('&&plan_hash_value_1.'), -666), NVL(TO_NUMBER('&&plan_hash_value_2.'), -666), NVL(TO_NUMBER('&&plan_hash_value_3.'), -666)) AND loaded_versions > 0]',
      NULL, NULL, NULL, NULL, 1, NULL, 'ALL')) p;

  SYS.DBMS_SQLTUNE.load_sqlset (
    sqlset_name     => l_sqlset_name,
    populate_cursor => sts_cur );
  DBMS_OUTPUT.put_line('loaded sqlset: '||l_sqlset_name);

  CLOSE sts_cur;

  :plans := DBMS_SPM.load_plans_from_sqlset (
    sqlset_name  => l_sqlset_name,
    sqlset_owner => USER,
    fixed        => '&&fixed.' );
END;
/
PRO Plans created from AWR for PHVs &&plan_hash_value_1. &&plan_hash_value_2. &&plan_hash_value_3.
PRINT plans

---------------------------------------------------------------------------------------

COL sql_handle NEW_V sql_handle;
SELECT sql_handle FROM dba_sql_plan_baselines WHERE signature = :signature AND ROWNUM = 1;

SELECT created, plan_name, origin, enabled, accepted, fixed, reproduced, last_executed, last_modified, description
FROM dba_sql_plan_baselines WHERE signature = :signature
ORDER BY created, plan_name;

SET HEA OFF PAGES 0
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE('&&sql_handle.'));
SET HEA ON PAGES 25

SELECT created, plan_name, origin, enabled, accepted, fixed, reproduced, last_executed, last_modified, description
FROM dba_sql_plan_baselines WHERE signature = :signature
ORDER BY created, plan_name;

SPO OFF;
