SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
DEF kiev_tx = '';
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;
COL appl FOR A8;
COL executions FOR 999,999,999,990;
COL et_secs FOR 999,999,990 HEA 'ET_SECS';
COL avg_avg_et FOR 9999,990.000 HEA 'AVG|ET_MS';
COL med_avg_et FOR 9999,990.000 HEA 'MED|ET_MS';
COL p90_avg_et FOR 9999,990.000 HEA '90th Pctl|ET_MS';
COL p95_avg_et FOR 9999,990.000 HEA '95th Pctl|ET_MS';
COL p97_avg_et FOR 9999,990.000 HEA '97th Pctl|ET_MS';
COL p99_avg_et FOR 9999,990.000 HEA '99th Pctl|ET_MS';
COL max_avg_et FOR 9999,990.000 HEA 'MAX AVG|ET_MS';
COL kiev_tx FOR A8;
SPO dba_hist_sqlstat_kiev_tx_perf_&&current_time..txt;
PRO dba_hist_sqlstat_kiev_tx_perf_&&current_time..txt
PRO
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO
PRO KIEV Tx Performance in milliseconds (ms)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/****************************************************************************************/
WITH 
  FUNCTION application_category (p_sql_text IN VARCHAR2)
  RETURN VARCHAR2
  IS
    gk_appl_cat_1                  CONSTANT VARCHAR2(10) := 'BeginTx'; -- 1st application category
    gk_appl_cat_2                  CONSTANT VARCHAR2(10) := 'CommitTx'; -- 2nd application category
    gk_appl_cat_3                  CONSTANT VARCHAR2(10) := 'Scan'; -- 3rd application category
    gk_appl_cat_4                  CONSTANT VARCHAR2(10) := 'GC'; -- 4th application category
    k_appl_handle_prefix           CONSTANT VARCHAR2(30) := '/*'||CHR(37);
    k_appl_handle_suffix           CONSTANT VARCHAR2(30) := CHR(37)||'*/'||CHR(37);
  BEGIN
    IF   p_sql_text LIKE k_appl_handle_prefix||'addTransactionRow'||k_appl_handle_suffix 
      OR p_sql_text LIKE k_appl_handle_prefix||'checkStartRowValid'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_1;
    ELSIF p_sql_text LIKE k_appl_handle_prefix||'SPM:CP'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'findMatchingRow'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'readTransactionsSince'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'writeTransactionKeys'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'setValueByUpdate'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'setValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'deleteValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'exists'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'existsUnique'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'updateIdentityValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE 'LOCK TABLE'||CHR(37) 
      OR  p_sql_text LIKE '/* null */ LOCK TABLE'||CHR(37)
      OR  p_sql_text LIKE k_appl_handle_prefix||'getTransactionProgress'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'recordTransactionState'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'checkEndRowValid'||k_appl_handle_suffix
      OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionCommitID'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_2;
    ELSIF p_sql_text LIKE k_appl_handle_prefix||'getValues'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getNextIdentityValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performScanQuery'||k_appl_handle_suffix
      OR  p_sql_text LIKE k_appl_handle_prefix||'performSnapshotScanQuery'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performFirstRowsScanQuery'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performStartScanValues'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performContinuedScanValues'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIndexSelect'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'bucketKeySelect'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'selectBuckets'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getAutoSequences'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'bucketValueSelect'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'countTransactions'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch snapshots'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_3;
    ELSIF p_sql_text LIKE k_appl_handle_prefix||'populateBucketGCWorkspace'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'deleteBucketGarbage'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Populate workspace'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage fOR  transaction GC'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage in KTK GC'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'hashBucket'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'validateIfWorkspaceEmpty'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getGCLogEntries'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventTryInsert'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'countAllRows'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Delete rows from'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'hashSnapshot'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'countKtkRows'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventMaxId'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'secondsSinceLastGcEvent'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionOlderThan'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_4;
    ELSE RETURN 'Unknown';
    END IF;
  END application_category;
all_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT sql_id, sql_text FROM v$sql
UNION
SELECT DISTINCT sql_id, DBMS_LOB.SUBSTR(sql_text, 1000) FROM dba_hist_sqltext
),
all_sql_with_type AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, sql_text, 
       SUBSTR(CASE WHEN sql_text LIKE '/*'||CHR(37) THEN SUBSTR(sql_text, 1, INSTR(sql_text, '*/') + 1) ELSE sql_text END, 1, 100) sql_text_100,
       application_category(sql_text) application_module
  FROM all_sql
),
my_tx_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, MAX(sql_text) sql_text, MAX(sql_text_100) sql_text_100, MAX(application_module) application_module
  FROM all_sql_with_type
 WHERE application_module IS NOT NULL
  AND (  
         (NVL('&&kiev_tx.', 'CBSGU') LIKE CHR(37)||'C'||CHR(37) AND application_module = 'CommitTx') OR
         (NVL('&&kiev_tx.', 'CBSGU') LIKE CHR(37)||'B'||CHR(37) AND application_module = 'BeginTx') OR
         (NVL('&&kiev_tx.', 'CBSGU') LIKE CHR(37)||'S'||CHR(37) AND application_module = 'Scan') OR
         (NVL('&&kiev_tx.', 'CBSGU') LIKE CHR(37)||'G'||CHR(37) AND application_module = 'GC') OR
         (NVL('&&kiev_tx.', 'CBSGU') LIKE CHR(37)||'U'||CHR(37) AND application_module = 'Unknown')
      )
 GROUP BY
       sql_id
),
/****************************************************************************************/
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

PRO
PRO dba_hist_sqlstat_kiev_tx_perf_&&current_time..txt
SPO OFF;
