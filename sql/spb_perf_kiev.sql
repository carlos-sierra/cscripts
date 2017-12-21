PRO KIEV Transaction: C=commitTx | B=beginTx | R=read | G=GC | CB=commitTx+beginTx | <null>=commitTx+beginTx+read+GC
ACC kiev_tx PROMPT 'KIEV Transaction (opt): ';
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

SPO spb_perf_&&kiev_tx._&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO KIEV_TX: &&kiev_tx.

WITH
all_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT sql_id, sql_text FROM v$sql
UNION
SELECT DISTINCT sql_id, DBMS_LOB.SUBSTR(sql_text, 1000) FROM dba_hist_sqltext
),
all_sql_with_type AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, sql_text, 
       CASE 
         WHEN sql_text LIKE '/* addTransactionRow('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* checkStartRowValid('||CHR(37)||') */'||CHR(37) 
         THEN 'BEGIN'
         WHEN sql_text LIKE '/* findMatchingRows('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* readTransactionsSince('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* writeTransactionKeys('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* setValueByUpdate('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* setValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* deleteValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* exists('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* existsUnique('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* updateIdentityValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE 'LOCK TABLE '||CHR(37)||'KievTransactions IN EXCLUSIVE MODE'||CHR(37) 
           OR sql_text LIKE '/* getTransactionProgress('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* recordTransactionState('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* checkEndRowValid('||CHR(37)||') */'||CHR(37)
         THEN 'COMMIT'
         WHEN sql_text LIKE '/* getValues('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* getNextIdentityValue('||CHR(37)||') */'||CHR(37) 
           OR sql_text LIKE '/* performScanQuery('||CHR(37)||') */'||CHR(37)
         THEN 'READ'
         WHEN sql_text LIKE '/* populateBucketGCWorkspace */'||CHR(37) 
           OR sql_text LIKE '/* deleteBucketGarbage */'||CHR(37) 
           OR sql_text LIKE '/* Populate workspace for transaction GC */'||CHR(37) 
           OR sql_text LIKE '/* Delete garbage for transaction GC */'||CHR(37) 
           OR sql_text LIKE '/* Populate workspace in KTK GC */'||CHR(37) 
           OR sql_text LIKE '/* Delete garbage in KTK GC */'||CHR(37) 
           OR sql_text LIKE '/* hashBucket */'||CHR(37) 
         THEN 'GC'
        END application_module
  FROM all_sql
),
my_tx_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, MAX(sql_text) sql_text, MAX(application_module) application_module
  FROM all_sql_with_type
 WHERE application_module IS NOT NULL
  AND (  
         (NVL('&&kiev_tx.', 'CBRG') LIKE '%C%' AND application_module = 'COMMIT') OR
         (NVL('&&kiev_tx.', 'CBRG') LIKE '%B%' AND application_module = 'BEGIN') OR
         (NVL('&&kiev_tx.', 'CBRG') LIKE '%R%' AND application_module = 'READ') OR
         (NVL('&&kiev_tx.', 'CBRG') LIKE '%G%' AND application_module = 'GC')
      )
 GROUP BY
       sql_id
),
cached_plans_with_spb AS (
SELECT s.con_id,
       s.sql_id,
       SUBSTR(s.sql_text, 1, 100) sql_text_100,
       s.plan_hash_value,
       s.exact_matching_signature,
       s.sql_plan_baseline,
       SUM(s.elapsed_time) elapsed_time,
       SUM(s.executions) executions
  FROM v$sql s,
       my_tx_sql t
 WHERE s.sql_plan_baseline IS NOT NULL
   AND s.con_id > 2 -- exclude CDB$ROOT and PDB$SEED
   AND s.parsing_user_id > 0 -- exclude SYS
   AND s.parsing_schema_id > 0 -- exclude SYS
   AND s.parsing_schema_name NOT LIKE 'C##'||CHR(37)
   AND s.plan_hash_value > 0
   AND s.executions > 0
   AND s.elapsed_time > 0
   AND t.sql_id = s.sql_id
 GROUP BY
       s.con_id,
       s.sql_id,
       SUBSTR(s.sql_text, 1, 100),
       s.plan_hash_value,
       s.exact_matching_signature,
       s.sql_plan_baseline
)
SELECT c.con_id,
       ROUND(c.elapsed_time/c.executions/1e3, 1) c_ms_per_exec,
       ROUND(b.elapsed_time/b.executions/1e3, 1) b_ms_per_exec,
       ROUND((c.elapsed_time/c.executions)/(b.elapsed_time/b.executions), 1) ratio,
       --c.elapsed_time c_elapsed_time,
       c.executions c_executions,
       --b.elapsed_time b_elapsed_time,
       --b.executions b_executions,
       c.sql_id,
       c.plan_hash_value phv,
       b.plan_name,
       TO_CHAR(b.created, 'YYYY-MM-DD"T"HH24:MI:SS') created,
       --c.sql_text_100
       SUBSTR(c.sql_text_100, 1, INSTR(c.sql_text_100, '*/') + 1) kiev_api
  FROM cached_plans_with_spb c,
       cdb_sql_plan_baselines b
 WHERE b.con_id = c.con_id
   AND b.signature = c.exact_matching_signature
   AND b.plan_name = c.sql_plan_baseline
 ORDER BY
       c.con_id,
       c.elapsed_time/c.executions DESC,
       b.elapsed_time/b.executions DESC,
       (c.elapsed_time/c.executions)/(b.elapsed_time/b.executions) DESC,
       c.sql_id,
       c.plan_hash_value
/

SPO OFF;
