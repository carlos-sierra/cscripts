SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

COL con_id FOR 999999;
COL ratio FOR 990.0;
COL plan_name FOR A30;
COL c_ms_per_exec FOR 999,990.0 HEA 'CURSOR_MS|PER_EXEC';
COL b_ms_per_exec FOR 999,990.0 HEA 'SPB_MS|PER_EXEC';
COL c_executions HEA 'CURSOR|EXECUTIONS';
COL sql_text_100 FOR A100;
COL kiev_api FOR A100; 
BREAK ON con_id SKIP PAGE;

SPO spb_perf_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

WITH 
cached_plans_with_spb AS (
SELECT con_id,
       sql_id,
       SUBSTR(sql_text, 1, 100) sql_text_100,
       plan_hash_value,
       exact_matching_signature,
       sql_plan_baseline,
       SUM(elapsed_time) elapsed_time,
       SUM(executions) executions
  FROM v$sql
 WHERE sql_plan_baseline IS NOT NULL
   AND con_id > 2 -- exclude CDB$ROOT and PDB$SEED
   AND parsing_user_id > 0 -- exclude SYS
   AND parsing_schema_id > 0 -- exclude SYS
   AND parsing_schema_name NOT LIKE 'C##'||CHR(37)
   AND plan_hash_value > 0
   AND executions > 0
   AND elapsed_time > 0
 GROUP BY
       con_id,
       sql_id,
       SUBSTR(sql_text, 1, 100),
       plan_hash_value,
       exact_matching_signature,
       sql_plan_baseline
)
SELECT c.con_id,
       ROUND(c.elapsed_time/c.executions/1e3, 1) c_ms_per_exec,
       ROUND(b.elapsed_time/b.executions/1e3, 1) b_ms_per_exec,
       ROUND((c.elapsed_time/c.executions)/(b.elapsed_time/b.executions), 1) ratio,
       c.executions c_executions,
       c.sql_id,
       c.plan_hash_value phv,
       b.plan_name,
       TO_CHAR(b.created, 'YYYY-MM-DD"T"HH24:MI:SS') created,
       SUBSTR(c.sql_text_100, 1, INSTR(c.sql_text_100, '*/') + 1) kiev_api
  FROM cached_plans_with_spb c,
       cdb_sql_plan_baselines b
 WHERE b.con_id = c.con_id
   AND b.signature = c.exact_matching_signature
   AND b.plan_name = c.sql_plan_baseline
   AND b.executions > 0
 ORDER BY
       c.con_id,
       c.elapsed_time/c.executions DESC,
       b.elapsed_time/b.executions DESC,
       (c.elapsed_time/c.executions)/(b.elapsed_time/b.executions) DESC,
       c.sql_id,
       c.plan_hash_value
/

SPO OFF;
