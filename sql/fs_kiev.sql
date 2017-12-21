SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
PRO KIEV Transaction: C=commitTx | B=beginTx | R=read | G=GC | CB=commitTx+beginTx | <null>=commitTx+beginTx+read+GC
ACC kiev_tx PROMPT 'KIEV Transaction (opt): ';

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

COL sql_id NEW_V sql_id FOR A13;
COL sql_text_100 FOR A100;

SPO fs_&&kiev_tx._&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO KIEV_TX: &&kiev_tx.

WITH 
kiev_tx_sql AS (
SELECT ROUND(SUM(s.elapsed_time)/SUM(s.executions)/1e3) ms_per_exec,
       s.con_id,
       s.sql_id,
       s.plan_hash_value,
       SUM(s.executions) executions,
       ROUND(SUM(s.elapsed_time)/1e6) et_seconds,
       MAX(s.last_active_time) last_active_time,
       SUBSTR(s.sql_text, 1, 100) sql_text_100,
       ROW_NUMBER() OVER (ORDER BY SUM(s.elapsed_time)/SUM(s.executions) DESC NULLS LAST) row_num
  FROM v$sql s
 WHERE ( CASE 
         WHEN (    s.sql_text LIKE '/* addTransactionRow('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* checkStartRowValid('||CHR(37)||') */'||CHR(37) 
              ) AND NVL('&&kiev_tx.', 'CBRG') LIKE '%B%'
         THEN 1
         WHEN (    s.sql_text LIKE '/* findMatchingRows('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* readTransactionsSince('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* writeTransactionKeys('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* setValueByUpdate('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* setValue('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* deleteValue('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* exists('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* existsUnique('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* updateIdentityValue('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE 'LOCK TABLE '||CHR(37)||'KievTransactions IN EXCLUSIVE MODE'||CHR(37) 
                OR s.sql_text LIKE '/* getTransactionProgress('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* recordTransactionState('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* checkEndRowValid('||CHR(37)||') */'||CHR(37)
              ) AND NVL('&&kiev_tx.', 'CBRG') LIKE '%C%'
         THEN 1
         WHEN (    s.sql_text LIKE '/* getValues('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* getNextIdentityValue('||CHR(37)||') */'||CHR(37) 
                OR s.sql_text LIKE '/* performScanQuery('||CHR(37)||') */'||CHR(37)
              ) AND NVL('&&kiev_tx.', 'CBRG') LIKE '%R%'
         THEN 1
         WHEN (    s.sql_text LIKE '/* populateBucketGCWorkspace */'||CHR(37) 
                OR s.sql_text LIKE '/* deleteBucketGarbage */'||CHR(37) 
                OR s.sql_text LIKE '/* Populate workspace for transaction GC */'||CHR(37) 
                OR s.sql_text LIKE '/* Delete garbage for transaction GC */'||CHR(37) 
                OR s.sql_text LIKE '/* Populate workspace in KTK GC */'||CHR(37) 
                OR s.sql_text LIKE '/* Delete garbage in KTK GC */'||CHR(37) 
                OR s.sql_text LIKE '/* hashBucket */'||CHR(37) 
              ) AND NVL('&&kiev_tx.', 'CBRG') LIKE '%G%'
         THEN 1
        END
       ) = 1
  AND s.con_id > 2 -- exclude CDB$ROOT and PDB$SEED
  AND s.parsing_user_id > 0 -- exclude SYS
  AND s.parsing_schema_id > 0 -- exclude SYS
  AND s.parsing_schema_name NOT LIKE 'C##'||CHR(37)
  AND s.plan_hash_value > 0
  AND s.executions > 0
  AND s.elapsed_time > 0
 GROUP BY
       s.con_id, 
       s.sql_id, 
       s.plan_hash_value,
       SUBSTR(s.sql_text, 1, 100)
)
SELECT ms_per_exec,
       et_seconds,
       executions,
       TO_CHAR(last_active_time, 'YYYY-MM-DD"T"HH24:MI:SS') last_active_time,
       row_num,
       con_id,
       sql_id,
       plan_hash_value,
       sql_text_100
  FROM kiev_tx_sql
 WHERE (ms_per_exec >= 100 OR row_num <= 100 OR et_seconds > 3600)
 ORDER BY
       ms_per_exec DESC, et_seconds DESC
/

SPO OFF;

