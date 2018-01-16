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
COL executions FOR 999,999,999,990;
COL et_secs FOR 999,999,990 HEA 'ET_SECS';
COL avg_avg_et FOR 9999,990.000 HEA 'AVG|ET_MS';
COL med_avg_et FOR 9999,990.000 HEA 'MED|ET_MS';
COL p90_avg_et FOR 9999,990.000 HEA '90th Pctl|ET_MS';
COL p95_avg_et FOR 9999,990.000 HEA '95th Pctl|ET_MS';
COL p97_avg_et FOR 9999,990.000 HEA '97th Pctl|ET_MS';
COL p99_avg_et FOR 9999,990.000 HEA '99th Pctl|ET_MS';
SPO dba_hist_sqlstat_kiev_tx_perf_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO
PRO KIEV Tx Performance in milliseconds (ms)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
/****************************************************************************************/
WITH
all_sql AS (
SELECT DISTINCT sql_id, sql_text FROM v$sql
UNION
SELECT DISTINCT sql_id, DBMS_LOB.SUBSTR(sql_text, 1000) FROM dba_hist_sqltext
),
all_sql_with_type AS (
SELECT sql_id, sql_text, 
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
SELECT sql_id, MAX(application_module) application_module
  FROM all_sql_with_type
 WHERE application_module IS NOT NULL
 GROUP BY
       sql_id
),
awr_query AS (
SELECT t.application_module,
       h.snap_id,
       ROUND(SUM(h.elapsed_time_delta)/SUM(h.executions_delta)) avg_et_per_exec,
       SUM(h.elapsed_time_delta) elapsed_time,
       SUM(h.executions_delta) executions
  FROM dba_hist_sqlstat h, my_tx_sql t
 WHERE h.con_id > 2 -- exclude CDB$ROOT and PDB$SEED
   AND h.parsing_user_id > 0 -- exclude SYS
   AND h.parsing_schema_id > 0 -- exclude SYS
   AND h.parsing_schema_name NOT LIKE 'C##'||CHR(37)
   AND h.plan_hash_value > 0
   AND h.executions_total > 0
   AND h.elapsed_time_total > 0
   AND h.executions_delta > 0
   AND t.sql_id = h.sql_id
 GROUP BY
       t.application_module,
       h.snap_id
),
mem_query AS (
SELECT t.application_module,
       h.inst_id,
       h.sql_id,
       h.child_number,
       ROUND(SUM(h.elapsed_time)/SUM(h.executions)) avg_et_per_exec,
       SUM(h.elapsed_time) elapsed_time,
       SUM(h.executions) executions
  FROM gv$sql h, my_tx_sql t
 WHERE h.con_id > 2 -- exclude CDB$ROOT and PDB$SEED
   AND h.parsing_user_id > 0 -- exclude SYS
   AND h.parsing_schema_id > 0 -- exclude SYS
   AND h.parsing_schema_name NOT LIKE 'C##'||CHR(37)
   AND h.plan_hash_value > 0
   AND h.executions > 0
   AND h.elapsed_time > 0
   AND t.sql_id = h.sql_id
 GROUP BY
       t.application_module,
       h.inst_id,
       h.sql_id,
       h.child_number
)
SELECT application_module appl,
       'AWR' src,
       ROUND(SUM(elapsed_time)/1e6) et_secs,
       ROUND(SUM(executions)) executions,
       ROUND(AVG(avg_et_per_exec)/1e3, 3) avg_avg_et,
       ROUND(MEDIAN(avg_et_per_exec)/1e3, 3) med_avg_et,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY avg_et_per_exec)/1e3, 3) p90_avg_et,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY avg_et_per_exec)/1e3, 3) p95_avg_et,
       ROUND(PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY avg_et_per_exec)/1e3, 3) p97_avg_et,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY avg_et_per_exec)/1e3, 3) p99_avg_et,
       ROUND(MAX(avg_et_per_exec)/1e3, 3) max_avg_et
  FROM awr_query q
 GROUP BY
       application_module
 UNION ALL
SELECT application_module appl,
       'MEM' src,
       ROUND(SUM(elapsed_time)/1e6) et_secs,
       ROUND(SUM(executions)) executions,
       ROUND(AVG(avg_et_per_exec)/1e3, 3) avg_avg_et,
       ROUND(MEDIAN(avg_et_per_exec)/1e3, 3) med_avg_et,
       ROUND(PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY avg_et_per_exec)/1e3, 3) p90_avg_et,
       ROUND(PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY avg_et_per_exec)/1e3, 3) p95_avg_et,
       ROUND(PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY avg_et_per_exec)/1e3, 3) p97_avg_et,
       ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY avg_et_per_exec)/1e3, 3) p99_avg_et,
       ROUND(MAX(avg_et_per_exec)/1e3, 3) max_avg_et
  FROM mem_query q
 GROUP BY
       application_module
 ORDER BY
       1, 2
/
/****************************************************************************************/
SPO OFF;
