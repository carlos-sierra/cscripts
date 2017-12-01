ACC sample_time PROMPT 'Date and Time (i.e. 2017-10-30T18:00:07) (opt): ';
PRO KIEV Transaction: C=commitTx | B=beginTx | R=read | G=GC | CB=commitTx+beginTx | <null>=commitTx+beginTx+read+GC
ACC kiev_tx PROMPT 'KIEV Transaction (opt): ';
SET LIN 300 PAGES 100 TAB OFF HEA ON VER OFF FEED ON ECHO OFF TRIMS ON;
COL dbid NEW_V dbid;
SELECT dbid FROM v$database;
DEF max_snap_id = '0';
COL max_snap_id NEW_V max_snap_id;
SELECT NVL(MAX(snap_id), &&max_snap_id.) max_snap_id FROM dba_hist_snapshot WHERE TO_DATE('&&sample_time.', 'YYYY-MM-DD"T"HH24:MI:SS') BETWEEN begin_interval_time AND end_interval_time AND dbid = &&dbid.;
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
COL avg_et_ms_per_exec FOR 999,990.000 HEA 'AVG_ET_MS|PER_EXEC';
COL avg_cpu_ms_per_exec FOR 999,990.000 HEA 'AVG_CPU_MS|PER_EXEC';
COL avg_iowait_ms_per_exec FOR 999,990.000 HEA 'AVG_IO_WAIT|MS_PER_EXEC';
COL avg_apwait_ms_per_exec FOR 999,990.000 HEA 'AVG_APPL_WAIT|MS_PER_EXEC';
BREAK ON kiev_tx SKIP PAGE;
SPO dba_hist_sqlstat_kiev_sql_perf_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO SNAP_ID: &&max_snap_id.
PRO BEGIN_TIME: &&begin_time.
PRO END_TIME: &&end_time.
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
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       t.application_module kiev_tx,
       ROUND(SUM(h.elapsed_time_delta)/SUM(h.executions_delta)/1e3, 3) avg_et_ms_per_exec,
       ROUND(SUM(h.cpu_time_delta)/SUM(h.executions_delta)/1e3, 3) avg_cpu_ms_per_exec,
       ROUND(SUM(h.iowait_delta)/SUM(h.executions_delta)/1e3, 3) avg_iowait_ms_per_exec,
       ROUND(SUM(h.apwait_delta)/SUM(h.executions_delta)/1e3, 3) avg_apwait_ms_per_exec,
       SUM(h.executions_delta) executions,
       h.sql_id,
       COUNT(DISTINCT h.plan_hash_value) plans,
       MIN(h.plan_hash_value) min_phv,
       MAX(h.plan_hash_value) max_phv,
       CASE WHEN t.sql_text LIKE 'LOCK TABLE%' THEN t.sql_text ELSE SUBSTR(t.sql_text, 1, INSTR(t.sql_text, '*/') + 1) END kiev_api,
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
       CASE WHEN t.sql_text LIKE 'LOCK TABLE%' THEN t.sql_text ELSE SUBSTR(t.sql_text, 1, INSTR(t.sql_text, '*/') + 1) END
)
SELECT q.kiev_tx,
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
SET LIN 80 PAGES 14 VER ON FEED ON ECHO ON;
