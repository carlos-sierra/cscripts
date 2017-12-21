PRO KIEV Transaction: C=commitTx | B=beginTx | R=read | G=GC | O=Other | CB=commitTx+beginTx | <null>=commitTx+beginTx+read+GC
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
COL kiev_api FOR A100;
COL command_name FOR A8 HEA 'COMMAND';
COL plans FOR 99999;
COL spbs FOR 9999;
COL first_load_time FOR A19;
COL avg_et_ms_per_exec FOR 999,990.000 HEA 'AVG_ET_MS|PER_EXEC';
COL avg_cpu_ms_per_exec FOR 999,990.000 HEA 'AVG_CPU_MS|PER_EXEC';
COL avg_iowait_ms_per_exec FOR 999,990.000 HEA 'AVG_IO_WAIT|MS_PER_EXEC';
COL avg_apwait_ms_per_exec FOR 999,990.000 HEA 'AVG_APPL_WAIT|MS_PER_EXEC';
BREAK ON kiev_tx SKIP PAGE;
SPO v_sql_kiev_sql_perf_report_&&kiev_tx._&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO KIEV_TX: &&kiev_tx.
PRO
/****************************************************************************************/
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
         ELSE 'OTHER'
        END application_module
  FROM all_sql
),
my_tx_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, MAX(sql_text) sql_text, MAX(application_module) application_module
  FROM all_sql_with_type
 WHERE application_module IS NOT NULL
  AND (  
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%C%' AND application_module = 'COMMIT') OR
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%B%' AND application_module = 'BEGIN') OR
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%R%' AND application_module = 'READ') OR
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%G%' AND application_module = 'GC') OR
         (NVL('&&kiev_tx.', 'CBRGO') LIKE '%O%' AND application_module = 'OTHER')
      )
 GROUP BY
       sql_id
),
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       t.application_module kiev_tx,
       ROUND(SUM(s.elapsed_time)/SUM(s.executions)/1e3, 3) avg_et_ms_per_exec,
       ROUND(SUM(s.cpu_time)/SUM(s.executions)/1e3, 3) avg_cpu_ms_per_exec,
       ROUND(SUM(s.user_io_wait_time)/SUM(s.executions)/1e3, 3) avg_iowait_ms_per_exec,
       ROUND(SUM(s.application_wait_time)/SUM(s.executions)/1e3, 3) avg_apwait_ms_per_exec,
       SUM(s.executions) executions,
       s.sql_id,
       COUNT(DISTINCT s.plan_hash_value) plans,
       MIN(s.plan_hash_value) min_phv,
       MAX(s.plan_hash_value) max_phv,
       CASE WHEN t.sql_text LIKE 'LOCK TABLE%' THEN t.sql_text ELSE SUBSTR(t.sql_text, 1, INSTR(t.sql_text, '*/') + 1) END kiev_api,
       (SELECT COUNT(DISTINCT c.sql_plan_baseline) FROM v$sql c WHERE c.sql_id = s.sql_id AND c.sql_plan_baseline IS NOT NULL) spbs,
       a.name command_name,
       MIN(s.first_load_time) first_load_time
  FROM gv$sql s,
       my_tx_sql t,
       audit_actions a
 WHERE s.executions > 0
   AND s.elapsed_time > 0
   AND t.sql_id = s.sql_id
   AND a.action = s.command_type
 GROUP BY
       s.sql_id,
       t.application_module,
       CASE WHEN t.sql_text LIKE 'LOCK TABLE%' THEN t.sql_text ELSE SUBSTR(t.sql_text, 1, INSTR(t.sql_text, '*/') + 1) END,
       a.name
)
SELECT q.kiev_tx,
       q.avg_et_ms_per_exec,
       q.avg_cpu_ms_per_exec,
       q.avg_iowait_ms_per_exec,
       q.avg_apwait_ms_per_exec,
       q.executions,
       q.sql_id,
       q.command_name,
       q.plans,
       q.min_phv,
       q.max_phv,
       q.first_load_time,
       q.spbs,
       q.kiev_api
  FROM my_query q
 ORDER BY
       CASE q.kiev_tx WHEN 'COMMIT' THEN 1 WHEN 'BEGIN' THEN 2 WHEN 'READ' THEN 3 WHEN 'GC' THEN 4 ELSE 5 END,
       q.avg_et_ms_per_exec DESC,
       q.avg_cpu_ms_per_exec DESC,
       q.sql_id
/
/****************************************************************************************/
SPO OFF;
