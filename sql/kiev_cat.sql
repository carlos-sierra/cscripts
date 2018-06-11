DEF kiev_category = 'GC';

-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;

COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

COL output_file_name NEW_V output_file_name NOPRI;
SELECT '/tmp/kiev_cat_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||REPLACE(LOWER(SYS_CONTEXT('USERENV','CON_NAME')),'$')||'_'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM v$database, v$instance;

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';

COL pdb_name FOR A30;
COL application_module FOR A4 HEA 'TYPE';
COL et_secs_per_exec FOR 999,999 HEA 'ELASPED|SECS PER|EXEC';
COL cpu_secs_per_exec FOR 999,999 HEA 'CPU|SECS PER|EXEC';
COL io_secs_per_exec FOR 999,999 HEA 'IO|SECS PER|EXEC';
COL buffers_per_exec FOR 999,999,999,990.0 HEA 'BUFFERS GETS|PER EXEC';
COL reads_per_exec FOR 999,999,990.0 HEA 'READS|PER EXEC';
COL rows_per_exec FOR 999,999,990.000 HEA 'ROWS PROCESSED|PER EXEC';
COL executions FOR 99,999,990;
COL last_active_time FOR A19;
COL min_plan_hash_value FOR 9999999999 HEA 'MIN_PHV';
COL max_plan_hash_value FOR 9999999999 HEA 'MAX_PHV';
COL plans FOR 99990;
COL sql_text_100 FOR A100;

BREAK ON pdb_name SKIP PAGE ON application_module;

SPO &&output_file_name..txt
PRO
PRO SQL> @kiev_cat.sql
PRO
PRO &&output_file_name..txt
PRO

PRO DATABASE: &&x_db_name.
PRO PDB: &&x_container.
PRO HOST: &&x_host_name.
PRO

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
sqlstats AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.con_id,
       s.sql_id,
       s.sql_text,
       COUNT(DISTINCT s.plan_hash_value) plans,
       MIN(s.plan_hash_value) min_plan_hash_value,
       MAX(s.plan_hash_value) max_plan_hash_value,
       MAX(s.last_active_time) last_active_time,
       SUM(s.buffer_gets) buffer_gets,
       SUM(s.disk_reads) disk_reads,
       SUM(s.rows_processed) rows_processed,
       SUM(s.executions) executions,
       SUM(s.elapsed_time) elapsed_time,
       SUM(s.cpu_time) cpu_time,
       SUM(s.user_io_wait_time) user_io_wait_time,
       application_category(s.sql_text) application_module
  FROM v$sql s
 WHERE 1 = 1
   AND s.sql_text NOT LIKE '/* SQL Analyze'||CHR(37)
 GROUP BY
       s.con_id,
       s.sql_id,
       s.sql_text
),
containers AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       name pdb_name
  FROM v$containers
 WHERE open_mode = 'READ WRITE'
)
SELECT c.pdb_name,
       s.application_module,
       s.last_active_time,
       s.sql_id,
       ROUND(s.elapsed_time      / GREATEST(s.executions, 1) / 1e6) et_secs_per_exec,
       ROUND(s.cpu_time          / GREATEST(s.executions, 1) / 1e6) cpu_secs_per_exec,
       ROUND(s.user_io_wait_time / GREATEST(s.executions, 1) / 1e6) io_secs_per_exec,
       ROUND(s.buffer_gets       / GREATEST(s.executions, 1), 1) buffers_per_exec,
       ROUND(s.disk_reads        / GREATEST(s.executions, 1), 1) reads_per_exec,
       ROUND(s.rows_processed    / GREATEST(s.executions, 1), 3) rows_per_exec,
       s.executions,
       s.plans,
       s.min_plan_hash_value,
       s.max_plan_hash_value,
       SUBSTR(CASE WHEN s.sql_text LIKE '/*'||CHR(37) THEN SUBSTR(s.sql_text, 1, INSTR(s.sql_text, '*/') + 1) ELSE s.sql_text END, 1, 100) sql_text_100
  FROM sqlstats s,
       containers c
 WHERE 1 = 1
   AND application_category(s.sql_text) = '&&kiev_category.' -- only one KIEV catagory
   AND c.con_id = s.con_id
 ORDER BY
       c.pdb_name,
       s.application_module,
       s.last_active_time,
       s.sql_id
/

PRO
PRO &&output_file_name..txt
PRO
SPO OFF;
CLEAR BREAK COLUMNS