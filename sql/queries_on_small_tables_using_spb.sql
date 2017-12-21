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
COL owner FOR A30;
COL table_name FOR A30;
COL last_analyzed FOR A19;
COL sql_text_100 FOR A100;

CL BRE;
BRE ON pdb_name SKIP PAGE ON con_id ON appl SKIP 1;

SPO queries_on_small_tables_using_spb_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

WITH
queries_using_spb AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, sql_id, hash_value, plan_hash_value, exact_matching_signature, sql_plan_baseline, sql_text, 
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
       SUM(executions) executions, SUM(elapsed_time) elapsed_time, SUM(buffer_gets) buffer_gets
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
       con_id, sql_id, hash_value, plan_hash_value, exact_matching_signature, sql_plan_baseline, sql_text
),
queries_hash_value AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, sql_id, hash_value, exact_matching_signature,
       SUBSTR(MAX(sql_text), 1, 100) sql_text_100,
       MAX(application_module) application_module,
       SUM(executions) executions, SUM(elapsed_time) elapsed_time, SUM(buffer_gets) buffer_gets
  FROM queries_using_spb
 GROUP BY
       con_id, sql_id, hash_value, exact_matching_signature
),
v_object_dependency_m AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       m.con_id, m.sql_id, v.to_hash, v.to_address
  FROM v$object_dependency v,
       queries_hash_value m
 WHERE v.con_id = m.con_id 
   AND v.from_hash = m.hash_value 
),
v_db_object_cache_m AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       m.con_id, m.sql_id,
       SUBSTR(v.owner,1,30) object_owner, 
       SUBSTR(v.name,1,30) object_name 
  FROM v$db_object_cache v,
       v_object_dependency_m m
 WHERE v.con_id = m.con_id 
   AND v.type IN ('TABLE','VIEW') 
   AND v.hash_value = m.to_hash 
   AND v.addr = m.to_address
),
cdb_tables_m AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       m.con_id, m.sql_id,
       v.owner, 
       v.table_name, 
       v.temporary,
       v.num_rows, 
       v.last_analyzed, 
       ROW_NUMBER() OVER (PARTITION BY m.con_id, m.sql_id ORDER BY v.num_rows DESC NULLS LAST) row_number 
  FROM cdb_tables v,
       v_db_object_cache_m m
 WHERE v.con_id = m.con_id 
   AND v.owner = m.object_owner
   AND v.table_name = m.object_name
),
cdb_pdbs_m AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       con_id,
       pdb_name
  FROM cdb_pdbs
)
SELECT q.con_id, 
       p.pdb_name,
       q.application_module appl, 
       q.sql_id, 
       q.executions,
       ROUND(q.elapsed_time / q.executions) us_per_exec,
       ROUND(q.buffer_gets / q.executions) bg_per_exec,
       t.owner, 
       t.table_name, 
       --t.temporary,
       t.num_rows, 
       TO_CHAR(t.last_analyzed, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed, 
       q.sql_text_100
  FROM queries_hash_value q,
       cdb_tables_m t,
       cdb_pdbs_m p
 WHERE t.con_id = q.con_id
   AND t.sql_id = q.sql_id
   AND t.row_number = 1
   AND t.temporary = 'N'
   AND NVL(t.num_rows, 0) < 1000
   AND p.con_id = q.con_id
 ORDER BY
       q.con_id, 
       q.application_module, 
       t.owner,
       t.table_name,
       q.sql_id
/

SPO OFF;
CL BRE;
