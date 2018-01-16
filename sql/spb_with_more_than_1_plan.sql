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

COL pdb_name FOR A30;
COL sql_text_100 FOR A100;

CL BRE;
BRE ON pdb_name SKIP PAGE ON con_id ON appl ON sql_id SKIP 1 ON sql_text_100;

SPO spb_with_more_than_1_plan_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

WITH 
all_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, sql_id, exact_matching_signature, plan_hash_value, sql_plan_baseline, sql_text, 
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
       END application_module,
       COUNT(*) OVER (PARTITION BY con_id, sql_id, exact_matching_signature) plans,
       SUM(executions) executions, SUM(elapsed_time) elapsed_time, SUM(buffer_gets) buffer_gets, SUM(rows_processed) rows_processed
  FROM v$sql
 WHERE 1 = 1
   AND sql_plan_baseline IS NOT NULL
   AND con_id > 2 -- exclude CDB$ROOT and PDB$SEED
   AND parsing_user_id > 0 -- exclude SYS
   AND parsing_schema_id > 0 -- exclude SYS
   AND parsing_schema_name NOT LIKE 'C##'||CHR(37)
   AND plan_hash_value > 0
   AND executions > 0
   AND elapsed_time > 0
   AND sql_text NOT LIKE '/* SQL Analyze(%'
   AND SUBSTR(object_status, 1, 5) = 'VALID'
   AND is_obsolete = 'N'
   AND is_shareable = 'Y'
 GROUP BY
       con_id, sql_id, exact_matching_signature, plan_hash_value, sql_plan_baseline, sql_text
),
cdb_pdbs_m AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       con_id,
       pdb_name
  FROM cdb_pdbs
)
SELECT s.con_id,
       p.pdb_name,
       s.application_module appl, 
       s.sql_id,
       s.plan_hash_value,
       s.sql_plan_baseline plan_name,
       s.executions,
       ROUND(s.elapsed_time / s.executions) us_per_exec,
       ROUND(s.buffer_gets / s.executions) bg_per_exec,
       ROUND(s.rows_processed / s.executions) rows_per_exec,
       SUBSTR(s.sql_text, 1, 100) sql_text_100
  FROM all_sql s,
       cdb_pdbs_m p
 WHERE 1 = 1
   AND s.application_module IS NOT NULL
   AND s.plans > 1
   AND p.con_id = s.con_id
 ORDER BY
       s.con_id, 
       s.application_module, 
       s.sql_id,
       s.plan_hash_value
/

SPO OFF;

