PRO 1. Enter KIEV Transaction: [{CBSGU}|C|B|S|G|U|CB|SG] (C=CommitTx B=BeginTx S=Scan G=GC U=Unknown)
DEF kiev_tx = '&1.';
PRO 2. Date and Time (i.e. 2017-10-30T18:00:07) (opt)
DEF sample_time = '&2.'
SET LIN 500 PAGES 100 HEA ON TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL dbid NEW_V dbid;
SELECT dbid FROM v$database;
DEF max_snap_id = '0';
COL max_snap_id NEW_V max_snap_id;
SELECT NVL(MAX(snap_id), &&max_snap_id.) max_snap_id FROM dba_hist_snapshot WHERE TO_DATE('&&sample_time.', 'YYYY-MM-DD"T"HH24:MI:SS') BETWEEN begin_interval_time AND end_interval_time AND dbid = &&dbid. AND CAST(end_interval_time AS DATE) - CAST(begin_interval_time AS DATE) < 1;
SELECT NVL(MAX(snap_id), &&max_snap_id.) max_snap_id FROM dba_hist_snapshot WHERE '&&sample_time.' IS NULL AND dbid = &&dbid.;
COL begin_time NEW_V begin_time;
COL end_time NEW_V end_time;
SELECT TO_CHAR(begin_interval_time, 'YYYY-MM-DD"T"HH24:MI:SS') begin_time, TO_CHAR(end_interval_time, 'YYYY-MM-DD"T"HH24:MI:SS') end_time FROM dba_hist_snapshot WHERE snap_id = &&max_snap_id. AND dbid = &&dbid.;
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
COL et_ms FOR 999,999,990.000 HEA 'ELAPSED_TIME|MS';
COL cpu_ms FOR 999,999,990.000 HEA 'CPU_TIME|MS';
COL avg_et_ms_per_exec FOR 999,990.000 HEA 'AVG_ET_MS|PER_EXEC';
COL avg_cpu_ms_per_exec FOR 999,990.000 HEA 'AVG_CPU_MS|PER_EXEC';
COL avg_iowait_ms_per_exec FOR 999,990.000 HEA 'AVG_IO_WAIT|MS_PER_EXEC';
COL avg_apwait_ms_per_exec FOR 999,990.000 HEA 'AVG_APPL_WAIT|MS_PER_EXEC';
COL rr FOR 990.000 HEA 'WEIGHT|%';
COL sql_text_100 FOR A100;
COL kiev_tx FOR A8;
BREAK ON kiev_tx SKIP PAGE;
SPO dba_hist_sqlstat_kiev_sql_perf_&&current_time..txt;
PRO dba_hist_sqlstat_kiev_sql_perf_&&current_time..txt
PRO
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO SAMPLE_TIME: &&sample_time.
PRO SNAP_ID: &&max_snap_id.
PRO BEGIN_TIME: &&begin_time.
PRO END_TIME: &&end_time.
PRO
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
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       t.application_module kiev_tx,
       ROUND(SUM(h.elapsed_time_delta)/1e3, 3) et_ms,
       ROUND(SUM(h.cpu_time_delta)/1e3, 3) cpu_ms,
       ROUND(SUM(h.elapsed_time_delta)/SUM(h.executions_delta)/1e3, 3) avg_et_ms_per_exec,
       ROUND(SUM(h.cpu_time_delta)/SUM(h.executions_delta)/1e3, 3) avg_cpu_ms_per_exec,
       ROUND(SUM(h.iowait_delta)/SUM(h.executions_delta)/1e3, 3) avg_iowait_ms_per_exec,
       ROUND(SUM(h.apwait_delta)/SUM(h.executions_delta)/1e3, 3) avg_apwait_ms_per_exec,
       SUM(h.executions_delta) executions,
       h.sql_id,
       COUNT(DISTINCT h.plan_hash_value) plans,
       MIN(h.plan_hash_value) min_phv,
       MAX(h.plan_hash_value) max_phv,
       t.sql_text_100,
       (SELECT COUNT(DISTINCT c.sql_plan_baseline) FROM gv$sql c WHERE c.sql_id = h.sql_id AND c.sql_plan_baseline IS NOT NULL) spbs
  FROM dba_hist_sqlstat h,
       my_tx_sql t
 WHERE h.dbid = &&dbid.
   AND h.snap_id = &&max_snap_id.
   AND h.executions_delta > 0
   AND h.elapsed_time_delta > 0
   AND t.sql_id = h.sql_id
 GROUP BY
       h.sql_id,
       t.application_module,
       t.sql_text_100
)
SELECT q.kiev_tx,
       ROUND(100 * RATIO_TO_REPORT(q.et_ms) OVER (PARTITION BY q.kiev_tx), 3) rr,
       q.et_ms,
       q.cpu_ms,
       q.avg_et_ms_per_exec,
       q.avg_cpu_ms_per_exec,
       q.avg_iowait_ms_per_exec,
       q.avg_apwait_ms_per_exec,
       q.executions,
       q.sql_id,
       q.plans,
       q.min_phv,
       q.max_phv,
       q.spbs,
       q.sql_text_100
  FROM my_query q
 ORDER BY
       CASE q.kiev_tx WHEN 'CommitTx' THEN 1 WHEN 'BeginTx' THEN 2 WHEN 'Scan' THEN 3 WHEN 'GC' THEN 4 WHEN 'Unknown' THEN 5 ELSE 6 END,
       q.executions DESC,
       q.et_ms DESC,
       q.cpu_ms DESC,
       q.avg_et_ms_per_exec DESC,
       q.avg_cpu_ms_per_exec DESC,
       q.sql_id
/
/****************************************************************************************/

PRO 
PRO dba_hist_sqlstat_kiev_sql_perf_&&current_time..txt
SPO OFF;
UNDEF 1 2
