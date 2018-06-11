SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET FEED ON;

COL date_time_from NEW_V date_time_from;
COL date_time_to NEW_V date_time_to;
SELECT TO_CHAR(MIN(sample_time),'YYYY-MM-DD"T"HH24:MI:SS') date_time_from, TO_CHAR(MAX(sample_time),'YYYY-MM-DD"T"HH24:MI:SS') date_time_to FROM v$active_session_history;
PRO KIEV Transaction: [{CBSGU}|C|B|S|G|U|CB|SG] (C=CommitTx B=BeginTx S=Scan G=GC U=Unknown)
ACC kiev_tx PROMPT 'KIEV Transaction (opt): ';
ACC sql_id PROMPT 'SQL_ID (opt): ';

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

SPO sql_execution_outliers_mem_&&kiev_tx._&&sql_id._&&current_time..txt;
PRO sql_execution_outliers_mem_&&kiev_tx._&&sql_id._&&current_time..txt
PRO
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO DATE_TIME_FROM: &&date_time_from.
PRO DATE_TIME_TO: &&date_time_to.
PRO KIEV_TX: &&kiev_tx.
PRO SQL_ID: &&sql_id.

COL session_id FOR 99999 HEA 'SID';
COL session_serial# FOR 999999 HEA 'SERIAL';
COL sql_plan_hash_value FOR 9999999999 HEA 'PHV';
COL sql_exec_id FOR 999999999 HEA 'SQL|EXEC_ID';
COL sql_exec_start FOR A19;
COL machine FOR A60;
COL con_id FOR 999999;
COL approx_execution_secs FOR 99,990.0 HEA 'APPROX|EXEC|SECS';
COL samples FOR 9999 HEA 'ASH|SMPL';
COL approx_start_time FOR A19;
COL approx_end_time FOR A19;
COL max_pga_allocated FOR 990.000 HEA 'PGA|ALLOC|GB';
COL max_temp_space_allocated FOR 9,990.000 HEA 'TEMP|SPACE|ALLOC';
COL sql_text_100 FOR A100 HEA 'SQL TEXT';
COL application_module FOR A8 HEA 'KIEV|TX';
COL sql_id FOR A13;
COL pdb_name FOR A30;

PRO 
PRO MEM SQL Executions lasting over ~2s
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
--UNION
--SELECT DISTINCT sql_id, DBMS_LOB.SUBSTR(sql_text, 1000) FROM dba_hist_sqltext
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
       h.sql_exec_start,
       h.sql_exec_id,
       MIN(h.sample_time) approx_start_time,
       MAX(h.sample_time) approx_end_time,
       ROUND(((CAST(MAX(h.sample_time) AS DATE) - h.sql_exec_start) * 24 * 60 * 60) + 0.5, 1) approx_execution_secs,
       COUNT(*) samples,
       h.sql_id,
       h.sql_plan_hash_value,
       h.con_id,       
       h.session_id,
       h.session_serial#,
       h.machine,
       ROUND(MAX(h.pga_allocated)/POWER(2,30),3) max_pga_allocated,
       ROUND(MAX(h.temp_space_allocated)/POWER(10,9),3) max_temp_space_allocated
  FROM v$active_session_history h,
       cdb_users u
 WHERE h.sql_exec_start BETWEEN TO_DATE('&&date_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&date_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND h.session_type = 'FOREGROUND'
   AND h.user_id > 0
   AND h.is_sqlid_current = 'Y'
   AND h.in_sql_execution = 'Y'
   AND h.sql_id IS NOT NULL
   AND h.sql_plan_hash_value > 0
   AND h.sql_exec_id IS NOT NULL
   AND h.sql_exec_start IS NOT NULL
   AND ('&&sql_id.' IS NULL OR h.sql_id = '&&sql_id.')
   AND u.user_id = h.user_id
   AND u.con_id = h.con_id
   AND u.oracle_maintained = 'N'
 GROUP BY
       h.session_id,
       h.session_serial#,
       h.sql_id,
       h.sql_plan_hash_value,
       h.sql_exec_id,
       h.sql_exec_start,
       h.machine,
       h.con_id
HAVING COUNT(*) > 1
),
v_sql_monitor AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       r.con_id,
       r.sid,
       r.session_serial#,
       r.sql_id,
       r.sql_plan_hash_value,
       r.sql_exec_id,
       r.sql_exec_start,
       r.report_id,
       r.first_refresh_time,
       r.last_refresh_time,
       r.status
  FROM v$sql_monitor r
 WHERE r.sql_exec_start BETWEEN TO_DATE('&&date_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&date_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS')
)
SELECT TO_CHAR(h.sql_exec_start, 'YYYY-MM-DD"T"HH24:MI:SS') sql_exec_start,
       h.sql_exec_id,
       r.report_id,
       r.status,
       h.samples,
       CASE 
         WHEN r.report_id IS NULL THEN h.approx_execution_secs 
         ELSE ROUND((r.last_refresh_time - r.sql_exec_start) * 24 * 60 * 60)
       END approx_execution_secs,
       TO_CHAR(h.approx_start_time, 'YYYY-MM-DD"T"HH24:MI:SS') approx_start_time,
       TO_CHAR(h.approx_end_time, 'YYYY-MM-DD"T"HH24:MI:SS') approx_end_time,
       h.sql_id,
       h.sql_plan_hash_value,
       h.con_id,  
       p.name pdb_name,     
       h.session_id,
       h.session_serial#,
       t.application_module,
       t.sql_text_100,
       h.machine,
       h.max_pga_allocated,
       h.max_temp_space_allocated
  FROM my_query h,
       my_tx_sql t,
       v_sql_monitor r,
       v$containers p
 WHERE t.sql_id = h.sql_id
   AND r.con_id(+) = h.con_id
   AND r.sid(+) = h.session_id
   AND r.session_serial#(+) = h.session_serial#
   AND r.sql_id(+) = h.sql_id
   AND r.sql_exec_id(+) = h.sql_exec_id
   AND r.sql_exec_start(+) = h.sql_exec_start
   AND p.con_id = h.con_id
 UNION ALL   
SELECT TO_CHAR(r.sql_exec_start, 'YYYY-MM-DD"T"HH24:MI:SS') sql_exec_start,
       r.sql_exec_id,
       r.report_id,
       r.status,
       TO_NUMBER(NULL) samples,
       ROUND((r.last_refresh_time - r.sql_exec_start) * 24 * 60 * 60) approx_execution_secs,
       TO_CHAR(r.sql_exec_start, 'YYYY-MM-DD"T"HH24:MI:SS') approx_start_time,
       TO_CHAR(r.last_refresh_time, 'YYYY-MM-DD"T"HH24:MI:SS') approx_end_time,
       r.sql_id,
       r.sql_plan_hash_value,
       r.con_id,
       p.name pdb_name,     
       r.sid session_id,
       r.session_serial#,
       t.application_module,
       t.sql_text_100,
       NULL machine,
       TO_NUMBER(NULL) max_pga_allocated,
       TO_NUMBER(NULL) max_temp_space_allocated
  FROM v_sql_monitor r,
       my_tx_sql t,
       v$containers p
 WHERE t.sql_id = r.sql_id
   AND (r.sql_id, r.sql_exec_id, r.sql_exec_start) NOT IN 
       ( SELECT sql_id,
                sql_exec_id,
                sql_exec_start
           FROM my_query
       )
   AND p.con_id = r.con_id
 ORDER BY
       1, 2
/
/****************************************************************************************/

PRO
PRO Use sql_monitor_report_mem.sql passing SQL_ID and SQL_EXEC_ID (when REPORT_ID is not null)
PRO
PRO sql_execution_outliers_mem_&&kiev_tx._&&sql_id._&&current_time..txt
SPO OFF;