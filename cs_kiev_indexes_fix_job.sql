REM Dummy line to avoid "usage: r_sql_exec" when executed using iodcli
----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_indexes_fix_job.sql
--
-- Purpose:     KIEV Indexes Inventory Fix Script (stand-alone)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/09/23
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Specify search scope when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_indexes_fix_job.sql
--
-- Notes:       cs_kiev_indexes_metadata.sql (former OEM JOB IOD_IMMEDIATE_KIEV_INDEXES.sql) should be executed in advance
--
---------------------------------------------------------------------------------------
--
WHENEVER OSERROR CONTINUE;
WHENEVER SQLERROR EXIT FAILURE;
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_is_primary VARCHAR2(5);
BEGIN
  SELECT CASE WHEN open_mode = 'READ WRITE' AND database_role = 'PRIMARY' THEN 'TRUE' ELSE 'FALSE' END AS is_primary INTO l_is_primary FROM v$database;
  IF l_is_primary = 'FALSE' THEN raise_application_error(-20000, 'Not PRIMARY'); END IF;
END;
/
-- exit not graciously if any error
WHENEVER SQLERROR EXIT FAILURE;
--
COL cs_con_name NEW_V cs_con_name FOR A30 NOPRI;
COL cs_con_id NEW_V cs_con_id FOR A4 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name, SYS_CONTEXT('USERENV', 'CON_ID') AS cs_con_id FROM DUAL
/
--
ALTER SESSION SET container = CDB$ROOT;
--
---------------------------------------------------------------------------------------
-- cs_top_activity_internal
DEF cs_minutes = '1';
DEF cs_top = '30';
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET PAGES 300 LONGC 120;
--
COL type FOR A4 HEA 'Type';
COL row_number NOPRI;
COL sql_plan_hash_value FOR 9999999999 HEA 'Plan Hash';
COL aas FOR 990.000 HEA 'AAS';
COL sessions FOR 9990 HEA 'Sess';
COL sql_text FOR A60 TRUNC HEA 'SQL Text';
COL timed_event FOR A35 TRUNC HEA 'Timed Event';
COL pdb_name FOR A30 TRUNC HEA 'PDB Name';
COL module FOR A25 TRUNC HEA 'Module';
COL version_count FOR 9990 HEA 'VC';
COL has_baseline FOR A2 HEA 'BL';
COL has_profile FOR A2 HEA 'PR';
COL has_patch FOR A2 HEA 'PA';
COL sqlid FOR A5 HEA 'SQLHV';
--
BREAK ON REPORT ON type SKIP 1 DUPL;
COMPUTE SUM LABEL "TOT:" OF aas ON REPORT;
COMPUTE SUM LABEL "AAS:" OF aas ON type;
--
PRO 
PRO TOP &&cs_top. Active SQL as per Average Active Sessions (AAS) on Timed Event for last &&cs_minutes. minute(s)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
FUNCTION application_category (
  p_sql_text     IN VARCHAR2, 
  p_command_name IN VARCHAR2 DEFAULT NULL
)
RETURN VARCHAR2 DETERMINISTIC
IS
  k_appl_handle_prefix CONSTANT VARCHAR2(30) := '/*'||CHR(37);
  k_appl_handle_suffix CONSTANT VARCHAR2(30) := CHR(37)||'*/'||CHR(37);
BEGIN
  IF    p_sql_text LIKE k_appl_handle_prefix||'Transaction Processing'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'addTransactionRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkEndRowValid'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkStartRowValid'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'exists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch commit by idempotency token'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest transactions for cache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find lower commit id for transaction cache warm up'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'findMatchingRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionCommitID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNewTransactionID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getTransactionProgress'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockForCommit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockKievTransactor'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'putBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readTransactionsSince'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'recordTransactionState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'setValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SPM:CP'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateNextKievTransID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'upsert_transactor_state'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'writeTransactionKeys'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'QueryTransactorHosts'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'WriteBucketValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'batch commit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'batch mutation log'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetchAllIdentities'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_epoch'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readFromTxorStateBeginTxn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyBeginTxn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDataStoreMaxTransaction'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'legacyGetDataStoreMaxTransaction'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitionDropDisabled'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getWithVersionOffsetSql'||k_appl_handle_suffix 
    OR  LOWER(p_sql_text) LIKE CHR(37)||'lock table kievtransactions'||CHR(37) 
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Read Only'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIndexSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketKeySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketValueSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countTransactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch snapshots'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get system time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAutoSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Lock row Bucket_Snapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'longFromDual'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performContinuedScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performFirstRowsScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performScanQuery'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSnapshotScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performStartScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest revisions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch max sequence for'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find High value for'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find partitions for'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Init lock name for snapshot'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'List snapshot tables.'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'Tail read bucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSegmentedScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listArchiveStatusByIndexName'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listAssignmentsByIndexName'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listHosts'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateHost'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateArchiveStatus'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateOperationLock'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KIEVWORKFLOWS table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'GetOldestLsn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'GetStreamRecords'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Check if another workflow is running'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete old workflows from'||k_appl_handle_suffix 
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Background'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Bootstrap snapshot table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIdentitySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkMissingTables'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKievTransactionRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKtkRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete rows from'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteBucketGarbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_leader_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventMaxId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventTryInsert'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get txn at time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getCurEndTime'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDBSchemaVersion'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getEndTimeOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getGCLogEntries'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSchemaMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSupportedLibVersions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashSnapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Populate workspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'populateBucketGCWorkspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'primeTxCache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyRoleExists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Row count between transactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'secondsSinceLastGcEvent'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'sync_leadership'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Test if table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Update snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateIfWorkspaceEmpty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'verify_is_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checking existence of Mutation Log Table'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checks if KIEVTRANSACTIONKEYS table is empty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checks if KIEVTRANSACTIONS table is empty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KT'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KTK'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Insert dynamic config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'createProxyUser'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'createSequence'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deregister_host'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropAutoSequenceMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropBucketFromMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropSequenceMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KievTransactionKeys table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KievTransactions table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get session count'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'initializeMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isKtPartitioned'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitioned'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'log'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'register_host'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateSchemaVersionInDB'||k_appl_handle_suffix 
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Ignore'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateKievPdbs'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getJDBCSuffix'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'MV_REFRESH'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'null'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectColumnsForTable'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectDatastoreMd'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SQL Analyze('||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateDataStoreId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countSequenceInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'iod-telemetry'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE CHR(37)||k_appl_handle_prefix||'OPT_DYN_SAMP'||k_appl_handle_suffix 
  THEN RETURN 'IG'; /* Ignore */
  --
  ELSIF p_command_name IN ('INSERT', 'UPDATE')
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_command_name = 'DELETE'
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_command_name = 'SELECT'
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSE RETURN 'UN'; /* Unknown */
  END IF;
END application_category;
/****************************************************************************************/
ash AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ROUND(COUNT(*) / (&&cs_minutes. * 60), 3) AS aas,
       COUNT(DISTINCT a.session_id||','||a.session_serial#) AS sessions,
       a.sql_id,
       a.sql_plan_hash_value,
       SUBSTR(CASE a.session_state WHEN 'ON CPU' THEN a.session_state ELSE a.wait_class||' - '||a.event END, 1, 35) AS timed_event,
       SUBSTR(a.module, 1, 25) AS module,
       c.con_id,
       c.name AS pdb_name,
       a.sql_opname,
       a.user_id,
       ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS row_number
  FROM v$active_session_history a,
       v$containers c
 WHERE a.sql_id IS NOT NULL
   --AND a.sample_time > SYSTIMESTAMP - INTERVAL '&&cs_minutes.' MINUTE
   AND a.sample_time > SYSDATE - (&&cs_minutes. / 24 / 60)
   AND c.con_id = a.con_id
 GROUP BY
       a.sql_id,
       a.sql_plan_hash_value,
       SUBSTR(CASE a.session_state WHEN 'ON CPU' THEN a.session_state ELSE a.wait_class||' - '||a.event END, 1, 35),
       SUBSTR(a.module, 1, 25),
       c.con_id,
       c.name,
       a.sql_opname,
       a.user_id
),
ash_extended AS (
SELECT a.row_number,
       a.aas,
       a.sessions,
       a.sql_id,
       a.sql_plan_hash_value,
       s.has_baseline,
       s.has_profile,
       s.has_patch,
       s.sql_text,
       s.sql_fulltext,
       a.module,
       a.con_id,
       a.timed_event,
       a.pdb_name,
       a.sql_opname,
       a.user_id
  FROM ash a
       CROSS APPLY (
         SELECT REPLACE(REPLACE(s.sql_text, CHR(10), ' '), CHR(9), ' ') AS sql_text, sql_fulltext,
                CASE WHEN s.sql_plan_baseline IS NULL THEN 'N' ELSE 'Y' END AS has_baseline, 
                CASE WHEN s.sql_profile IS NULL THEN 'N' ELSE 'Y' END AS has_profile, 
                CASE WHEN s.sql_patch IS NULL THEN 'N' ELSE 'Y' END AS has_patch 
           FROM v$sql s
          WHERE a.sql_plan_hash_value > 0 
            AND s.sql_id = a.sql_id
            AND s.con_id = a.con_id
            AND s.plan_hash_value = a.sql_plan_hash_value
          ORDER BY 
                s.last_active_time DESC
          FETCH FIRST 1 ROW ONLY
       ) s
 WHERE a.row_number <= &&cs_top.
),
ash_extended2 AS (
SELECT CASE a.user_id WHEN 0 THEN 'SYS' ELSE application_category(a.sql_text, a.sql_opname) END AS type,
       a.row_number,
       a.aas,
       a.sessions,
       a.sql_id,
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN a.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(a.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE a.sql_fulltext END),100000),5,'0') AS sqlid,
       a.sql_plan_hash_value,
       s.version_count,
       a.has_baseline,
       a.has_profile,
       a.has_patch,
       a.sql_text,
       a.module,
       a.con_id,
       a.timed_event,
       a.pdb_name,
       a.sql_opname,
       a.user_id
  FROM ash_extended a,
       v$sqlstats s
 WHERE s.sql_id(+) = a.sql_id
   AND s.con_id(+) = a.con_id
)
SELECT a.type,
       a.row_number,
       a.aas,
       a.sessions,
       a.sql_id,
       a.sqlid,
       a.sql_plan_hash_value,
       a.version_count,
       a.has_baseline,
       a.has_profile,
       a.has_patch,
       a.sql_text,
       a.timed_event,
       a.pdb_name,
       a.module
  FROM ash_extended2 a
 ORDER BY
       CASE a.type WHEN 'TP' THEN 1 WHEN 'RO' THEN 2 WHEN 'BG' THEN 3 WHEN 'UN' THEN 4 WHEN 'SYS' THEN 5 ELSE 6 END,
       a.row_number
/
--
-- CLEAR BREAK COMPUTE;
---------------------------------------------------------------------------------------
--
-- constants
DEF cs_tools_schema = 'C##IOD';
DEF cs_file_name = '/tmp/cs_kiev_indexes_fix_job';
DEF table_name = '';
DEF index_name = '';
DEF include_ddl = 'Y';
DEF include_index_drop = 'Y';
-- constants when executing as script
DEF sleep_seconds = '2';
DEF auto_execute_script = '&&cs_file_name._DUMMY';
DEF pause_or_prompt = 'PAUSE';
DEF deprecate_index = 'Y';
DEF rename_index = 'Y';
DEF missing_index = 'Y';
DEF extra_index = 'Y';
DEF missing_colums = 'Y';
DEF extra_colums = 'Y';
DEF misaligned_colums = 'Y';
-- constants when executing as job, uncomment this section below
DEF sleep_seconds = '5';
DEF auto_execute_script = '&&cs_file_name._IMPLEMENTATION';
DEF pause_or_prompt = 'PROMPT';
DEF deprecate_index = 'N';
DEF rename_index = 'N';
DEF extra_index = 'N';
DEF missing_colums = 'N';
DEF extra_colums = 'N';
DEF misaligned_colums = 'N';
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0 SERVEROUT ON;
SPO &&cs_file_name._DUMMY.sql;
PRO REM I am a dummy!
SPO OFF;
PRO
PRO generating &&cs_file_name._IMPLEMENTATION.sql
PRO
SPO &&cs_file_name._IMPLEMENTATION.sql;
DECLARE
  l_created DATE;
  l_prior_pdb_name VARCHAR2(128) := '-666';
  l_statement VARCHAR2(528);
  l_count INTEGER := 0;
  l_count2 INTEGER := 0;
BEGIN
  SELECT created INTO l_created FROM dba_objects WHERE owner = UPPER('&&cs_tools_schema.') AND object_name = 'KIEV_IND_COLUMNS' AND object_type = 'TABLE';
  IF SYSDATE - l_created > 3 THEN
    raise_application_error(-20000, '*** KIEV_IND_COLUMNS is '||ROUND(SYSDATE - l_created, 1)||' days old! ***');
  END IF;
  --
  DBMS_OUTPUT.put_line('PRO 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< ');
  DBMS_OUTPUT.put_line('SPO &&cs_file_name._IMPLEMENTATION.log;');
  DBMS_OUTPUT.put_line('PRO');
  --
  FOR i IN (SELECT pdb_name, owner, table_name, index_name, validation, fat_index,
                  NULLIF(MAX(uniqueness), 'NONUNIQUE') AS uniqueness,
                  MAX(rename_as) AS rename_as, 
                  MAX(visibility) AS visibility,
                  MAX(leaf_blocks) AS leaf_blocks,
                  MAX(tablespace_name) AS tablespace_name, 
                  LISTAGG(UPPER(column_name), ', ') WITHIN GROUP (ORDER BY k_column_position) AS columns_list
              FROM &&cs_tools_schema..kiev_ind_columns_v
            WHERE &&cs_con_id. IN (1, con_id)
              AND '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
              AND UPPER(table_name) = UPPER(COALESCE('&&table_name.', table_name))
              AND UPPER(index_name) = UPPER(COALESCE('&&index_name.', index_name))
              AND '&&include_ddl.' = 'Y'
              --AND validation IN ('REDUNDANT INDEX', 'DEPRECATE INDEX', 'RENAME INDEX', 'MISING INDEX', 'EXTRA INDEX', 'MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)')
              AND validation IN ('DEPRECATE INDEX', 'RENAME INDEX', 'MISING INDEX', 'EXTRA INDEX', 'MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)')
              AND (
                      ('&&deprecate_index.' = 'Y'     AND validation  = 'DEPRECATE INDEX')      OR
                      ('&&rename_index.' = 'Y'        AND validation  = 'RENAME INDEX')         OR
                      ('&&missing_index.' = 'Y'       AND validation  = 'MISING INDEX')         OR
                      ('&&extra_index.' = 'Y'         AND validation  = 'EXTRA INDEX')          OR
                      ('&&missing_colums.' = 'Y'      AND validation  = 'MISING COLUMN(S)')     OR
                      ('&&extra_colums.' = 'Y'        AND validation  = 'EXTRA COLUMN(S)')      OR
                      ('&&misaligned_colums.' = 'Y'   AND validation  = 'MISALIGNED COLUMN(S)')
              )
              AND fat_index IN ('NO', 'LITTLE')
              AND NVL(partitioned, 'NO') = 'NO'
              AND NOT (pdb_name LIKE 'KAASCANARY%' AND table_name IN ('canary_complexBucket', 'canary_simpleBucket'))
            GROUP BY
                  pdb_name, owner, table_name, index_name, validation, fat_index
            ORDER BY
                  UPPER(pdb_name),
                  UPPER(owner),
                  UPPER(table_name),
                  CASE validation
                  WHEN 'EXTRA INDEX'          THEN 1
                  WHEN 'REDUNDANT INDEX'      THEN 2
                  WHEN 'DEPRECATE INDEX'      THEN 3
                  WHEN 'RENAME INDEX'         THEN 4
                  WHEN 'MISING COLUMN(S)'     THEN 5
                  WHEN 'EXTRA COLUMN(S)'      THEN 6
                  WHEN 'MISALIGNED COLUMN(S)' THEN 7
                  WHEN 'MISING INDEX'         THEN 8
                  END,
                  UPPER(index_name))
  LOOP
    l_count2 := l_count2 + 1;
    DBMS_OUTPUT.put_line('PRO');
    DBMS_OUTPUT.put_line('PRO');
    --
    IF i.pdb_name <> l_prior_pdb_name THEN
      l_count := 1;
      DBMS_OUTPUT.put_line('PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      DBMS_OUTPUT.put_line('PRO');
      DBMS_OUTPUT.put_line('PRO PDB NAME: '||i.pdb_name);
      DBMS_OUTPUT.put_line('PRO');
      DBMS_OUTPUT.put_line('PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      DBMS_OUTPUT.put_line('PRO');
      DBMS_OUTPUT.put_line('&&pause_or_prompt. hit "return" to continue');
      DBMS_OUTPUT.put_line('PRO');
      l_prior_pdb_name := i.pdb_name;
    ELSE
      l_count := l_count + 1;
      DBMS_OUTPUT.put_line('PRO sleep for &&sleep_seconds. seconds...');
      DBMS_OUTPUT.put_line('EXEC DBMS_LOCK.sleep(&&sleep_seconds.);');
    END IF;
    --
    DBMS_OUTPUT.put_line('PRO');
    DBMS_OUTPUT.put_line('PRO INDEX #'||l_count2||' (CDB). INDEX #'||l_count||' (PDB).'||i.pdb_name||' '||i.owner||' '||i.table_name||' '||i.index_name||' '||i.validation||' '||i.visibility||' BLOCKS:'||i.leaf_blocks||' FAT:'||i.fat_index||' '||i.rename_as||' ('||i.columns_list||')');
    DBMS_OUTPUT.put_line('PRO');
    DBMS_OUTPUT.put_line('ALTER SESSION SET CONTAINER = '||i.pdb_name||';');
    DBMS_OUTPUT.put_line('ALTER SESSION SET DDL_LOCK_TIMEOUT = 10;');
    DBMS_OUTPUT.put_line('SET ECHO ON FEED ON VER ON TIM ON TIMI ON SERVEROUT ON;');
    DBMS_OUTPUT.put_line('WHENEVER SQLERROR EXIT FAILURE;');
    DBMS_OUTPUT.put_line('DECLARE');
    DBMS_OUTPUT.put_line('already_indexed      EXCEPTION; PRAGMA EXCEPTION_INIT(already_indexed,      -01408); -- ORA-01408: ORA-01408: such column list already indexed'); -- expected when index is actually redundant (e.g. SEA KIEV01 IPAM idxSubnetParentId)
    DBMS_OUTPUT.put_line('table_does_not_exist EXCEPTION; PRAGMA EXCEPTION_INIT(table_does_not_exist, -00942); -- ORA-00942: table or view does not exist'); -- expected when pdb creates and drops table very often (e.g. ZRH KIEV02RG KMS_CP_SHARD1 esmpmdapyrqaa_hsmkeysKI1)
    DBMS_OUTPUT.put_line('BEGIN');
    --
    IF i.validation IN ('MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)', 'MISING INDEX') THEN
      IF i.fat_index = 'LITTLE' THEN DBMS_OUTPUT.put_line('--'); DBMS_OUTPUT.put_line('-- *** FAT INDEX TO BE CREATED WITH TABLE LOCK ***'); END IF;
      l_statement := 'CREATE '||i.uniqueness||' INDEX '||i.owner||'.'||SUBSTR(i.index_name, 1, 29)||'# ON '||i.owner||'.'||i.table_name||'('||i.columns_list||') ';
      IF i.tablespace_name IS NOT NULL THEN l_statement := l_statement||'TABLESPACE '||i.tablespace_name; END IF;
      IF NOT i.fat_index = 'LITTLE' THEN l_statement := l_statement||' ONLINE'; END IF;
      DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';'); -- create new as <index_name>#
    END IF;
    --
    IF i.validation IN ('MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)') THEN
      l_statement := 'ALTER INDEX '||i.owner||'.'||i.index_name||' RENAME TO '||SUBSTR(i.index_name, 1, 29)||'$'; -- rename old to <index_name>$
      DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      IF i.uniqueness = 'UNIQUE' AND i.index_name LIKE '%PK' THEN
        l_statement := 'ALTER TABLE '||i.owner||'.'||i.table_name||' DROP PRIMARY KEY';
        DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      END IF;
    END IF;
    --
    IF i.validation IN ('MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)', 'MISING INDEX') THEN
      l_statement := 'ALTER INDEX '||i.owner||'.'||SUBSTR(i.index_name, 1, 29)||'#'||' RENAME TO '||i.index_name; -- rename new from <index_name># to <index_name>
      DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      IF i.uniqueness = 'UNIQUE' AND i.index_name LIKE '%PK' THEN
        l_statement := 'ALTER TABLE '||i.owner||'.'||i.table_name||' ADD PRIMARY KEY ('||i.columns_list||') USING INDEX '||i.owner||'.'||i.index_name;
        DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      END IF;
    END IF;
    --
    IF i.validation IN ('MISING COLUMN(S)', 'EXTRA COLUMN(S)', 'MISALIGNED COLUMN(S)') THEN
      IF '&&include_index_drop.' = 'Y' THEN
        l_statement := 'DROP INDEX '||i.owner||'.'||SUBSTR(i.index_name, 1, 29)||'$'; -- drop old <index_name>$
        DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      ELSE
        IF i.visibility = 'VISIBLE' THEN
          l_statement := 'ALTER INDEX '||i.owner||'.'||SUBSTR(i.index_name, 1, 29)||'$ INVISIBLE'; -- invisible old <index_name>$
          DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
        END IF;
      END IF;
    END IF;
    --
    IF i.validation = 'RENAME INDEX' THEN
      l_statement := 'ALTER INDEX '||i.owner||'.'||i.index_name||' RENAME TO '||i.rename_as;
      DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      IF i.visibility = 'INVISIBLE' THEN
        l_statement := 'ALTER INDEX '||i.owner||'.'||i.rename_as||' VISIBLE';
        DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      END IF;
    END IF;
    --
    IF i.validation IN ('REDUNDANT INDEX', 'DEPRECATE INDEX', 'EXTRA INDEX') THEN
      IF '&&include_index_drop.' = 'Y' THEN
        l_statement := 'DROP INDEX '||i.owner||'.'||i.index_name;
        DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      ELSE
        IF i.visibility = 'VISIBLE' THEN
          l_statement := 'ALTER INDEX '||i.owner||'.'||i.index_name||' INVISIBLE';
          DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
        END IF;
        l_statement := 'ALTER INDEX '||i.owner||'.'||i.index_name||' RENAME TO '||SUBSTR(i.index_name, 1, 29)||'_';
        DBMS_OUTPUT.put_line('EXECUTE IMMEDIATE '''||l_statement||''';');
      END IF;
    END IF;
    --
    DBMS_OUTPUT.put_line('EXCEPTION');
    DBMS_OUTPUT.put_line('WHEN already_indexed OR table_does_not_exist THEN DBMS_OUTPUT.put_line(SQLERRM);');
    DBMS_OUTPUT.put_line('END;');
    DBMS_OUTPUT.put_line('/');
    DBMS_OUTPUT.put_line('WHENEVER SQLERROR CONTINUE;');
  END LOOP;
  --
  DBMS_OUTPUT.put_line('PRO');
  DBMS_OUTPUT.put_line('PRO log: &&cs_file_name._IMPLEMENTATION.log');
  DBMS_OUTPUT.put_line('SPO OFF;');
  --
  IF '&&cs_con_name.' = 'CDB$ROOT' THEN
    DBMS_OUTPUT.put_line('ALTER SESSION SET CONTAINER = CDB$ROOT;');
  END IF;
  --
  DBMS_OUTPUT.put_line('PRO');
  DBMS_OUTPUT.put_line('PRO Done!');
  DBMS_OUTPUT.put_line('PRO');
  DBMS_OUTPUT.put_line('PRO 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< 8< ');
END;
/
SPO OFF;
SET HEA ON PAGES 100 SERVEROUT OFF;
PRO
PRO Review and Execute: &&cs_file_name._IMPLEMENTATION.sql
PRO 
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@&&auto_execute_script..sql
--
ALTER SESSION SET container = CDB$ROOT;
EXEC DBMS_LOCK.sleep(10);
--
---------------------------------------------------------------------------------------
-- cs_top_activity_internal
DEF cs_minutes = '1';
DEF cs_top = '30';
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET PAGES 300 LONGC 120;
--
COL type FOR A4 HEA 'Type';
COL row_number NOPRI;
COL sql_plan_hash_value FOR 9999999999 HEA 'Plan Hash';
COL aas FOR 990.000 HEA 'AAS';
COL sessions FOR 9990 HEA 'Sess';
COL sql_text FOR A60 TRUNC HEA 'SQL Text';
COL timed_event FOR A35 TRUNC HEA 'Timed Event';
COL pdb_name FOR A30 TRUNC HEA 'PDB Name';
COL module FOR A25 TRUNC HEA 'Module';
COL version_count FOR 9990 HEA 'VC';
COL has_baseline FOR A2 HEA 'BL';
COL has_profile FOR A2 HEA 'PR';
COL has_patch FOR A2 HEA 'PA';
COL sqlid FOR A5 HEA 'SQLHV';
--
BREAK ON REPORT ON type SKIP 1 DUPL;
COMPUTE SUM LABEL "TOT:" OF aas ON REPORT;
COMPUTE SUM LABEL "AAS:" OF aas ON type;
--
PRO 
PRO TOP &&cs_top. Active SQL as per Average Active Sessions (AAS) on Timed Event for last &&cs_minutes. minute(s)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
FUNCTION application_category (
  p_sql_text     IN VARCHAR2, 
  p_command_name IN VARCHAR2 DEFAULT NULL
)
RETURN VARCHAR2 DETERMINISTIC
IS
  k_appl_handle_prefix CONSTANT VARCHAR2(30) := '/*'||CHR(37);
  k_appl_handle_suffix CONSTANT VARCHAR2(30) := CHR(37)||'*/'||CHR(37);
BEGIN
  IF    p_sql_text LIKE k_appl_handle_prefix||'Transaction Processing'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'addTransactionRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkEndRowValid'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkStartRowValid'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'exists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch commit by idempotency token'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest transactions for cache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find lower commit id for transaction cache warm up'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'findMatchingRow'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionCommitID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNewTransactionID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getTransactionProgress'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockForCommit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'lockKievTransactor'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'putBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readTransactionsSince'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'recordTransactionState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'setValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SPM:CP'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateNextKievTransID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'upsert_transactor_state'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'writeTransactionKeys'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'QueryTransactorHosts'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'WriteBucketValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'batch commit'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'batch mutation log'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetchAllIdentities'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_epoch'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readFromTxorStateBeginTxn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyBeginTxn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateTransactorState'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDataStoreMaxTransaction'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'legacyGetDataStoreMaxTransaction'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitionDropDisabled'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getWithVersionOffsetSql'||k_appl_handle_suffix 
    OR  LOWER(p_sql_text) LIKE CHR(37)||'lock table kievtransactions'||CHR(37) 
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Read Only'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIndexSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketKeySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketValueSelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countTransactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch snapshots'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get system time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAutoSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextIdentityValue'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Lock row Bucket_Snapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'longFromDual'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performContinuedScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performFirstRowsScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performScanQuery'||k_appl_handle_suffix
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSnapshotScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performStartScanValues'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch latest revisions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch max sequence for'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find High value for'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find partitions for'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Init lock name for snapshot'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'List snapshot tables.'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'Tail read bucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSegmentedScanQuery'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listArchiveStatusByIndexName'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listAssignmentsByIndexName'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'listHosts'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateHost'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateArchiveStatus'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateOperationLock'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KIEVWORKFLOWS table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'GetOldestLsn'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'GetStreamRecords'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Check if another workflow is running'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete old workflows from'||k_appl_handle_suffix 
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Background'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Bootstrap snapshot table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIdentitySelect'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'checkMissingTables'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllBuckets'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countAllRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKievTransactionRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countKtkRows'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Delete rows from'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deleteBucketGarbage'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateSequences'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'fetch_leader_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventMaxId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventTryInsert'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Get txn at time'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getCurEndTime'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getDBSchemaVersion'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getEndTimeOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getGCLogEntries'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionOlderThan'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSchemaMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getSupportedLibVersions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashBucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'hashSnapshot'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Populate workspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'populateBucketGCWorkspace'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'primeTxCache'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'readOnlyRoleExists'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Row count between transactions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'secondsSinceLastGcEvent'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'sync_leadership'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Test if table Kiev_S'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Update snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update_heartbeat'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateIfWorkspaceEmpty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'verify_is_leader'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checking existence of Mutation Log Table'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checks if KIEVTRANSACTIONKEYS table is empty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Checks if KIEVTRANSACTIONS table is empty'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KT'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KTK'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Insert dynamic config'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'createProxyUser'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'createSequence'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'deregister_host'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropAutoSequenceMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropBucketFromMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'dropSequenceMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KievTransactionKeys table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get KievTransactions table indexes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get session count'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'initializeMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isKtPartitioned'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitioned'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'log'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'register_host'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'updateSchemaVersionInDB'||k_appl_handle_suffix 
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_sql_text LIKE k_appl_handle_prefix||'Ignore'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateKievPdbs'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getJDBCSuffix'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'MV_REFRESH'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'null'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectColumnsForTable'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'selectDatastoreMd'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'SQL Analyze('||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'validateDataStoreId'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countMetadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'countSequenceInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'iod-telemetry'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert snapshot metadata'||k_appl_handle_suffix 
    OR  p_sql_text LIKE CHR(37)||k_appl_handle_prefix||'OPT_DYN_SAMP'||k_appl_handle_suffix 
  THEN RETURN 'IG'; /* Ignore */
  --
  ELSIF p_command_name IN ('INSERT', 'UPDATE')
  THEN RETURN 'TP'; /* Transaction Processing */
  --
  ELSIF p_command_name = 'DELETE'
  THEN RETURN 'BG'; /* Background */
  --
  ELSIF p_command_name = 'SELECT'
  THEN RETURN 'RO'; /* Read Only */
  --
  ELSE RETURN 'UN'; /* Unknown */
  END IF;
END application_category;
/****************************************************************************************/
ash AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ROUND(COUNT(*) / (&&cs_minutes. * 60), 3) AS aas,
       COUNT(DISTINCT a.session_id||','||a.session_serial#) AS sessions,
       a.sql_id,
       a.sql_plan_hash_value,
       SUBSTR(CASE a.session_state WHEN 'ON CPU' THEN a.session_state ELSE a.wait_class||' - '||a.event END, 1, 35) AS timed_event,
       SUBSTR(a.module, 1, 25) AS module,
       c.con_id,
       c.name AS pdb_name,
       a.sql_opname,
       a.user_id,
       ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS row_number
  FROM v$active_session_history a,
       v$containers c
 WHERE a.sql_id IS NOT NULL
   --AND a.sample_time > SYSTIMESTAMP - INTERVAL '&&cs_minutes.' MINUTE
   AND a.sample_time > SYSDATE - (&&cs_minutes. / 24 / 60)
   AND c.con_id = a.con_id
 GROUP BY
       a.sql_id,
       a.sql_plan_hash_value,
       SUBSTR(CASE a.session_state WHEN 'ON CPU' THEN a.session_state ELSE a.wait_class||' - '||a.event END, 1, 35),
       SUBSTR(a.module, 1, 25),
       c.con_id,
       c.name,
       a.sql_opname,
       a.user_id
),
ash_extended AS (
SELECT a.row_number,
       a.aas,
       a.sessions,
       a.sql_id,
       a.sql_plan_hash_value,
       s.has_baseline,
       s.has_profile,
       s.has_patch,
       s.sql_text,
       s.sql_fulltext,
       a.module,
       a.con_id,
       a.timed_event,
       a.pdb_name,
       a.sql_opname,
       a.user_id
  FROM ash a
       CROSS APPLY (
         SELECT REPLACE(REPLACE(s.sql_text, CHR(10), ' '), CHR(9), ' ') AS sql_text, sql_fulltext,
                CASE WHEN s.sql_plan_baseline IS NULL THEN 'N' ELSE 'Y' END AS has_baseline, 
                CASE WHEN s.sql_profile IS NULL THEN 'N' ELSE 'Y' END AS has_profile, 
                CASE WHEN s.sql_patch IS NULL THEN 'N' ELSE 'Y' END AS has_patch 
           FROM v$sql s
          WHERE a.sql_plan_hash_value > 0 
            AND s.sql_id = a.sql_id
            AND s.con_id = a.con_id
            AND s.plan_hash_value = a.sql_plan_hash_value
          ORDER BY 
                s.last_active_time DESC
          FETCH FIRST 1 ROW ONLY
       ) s
 WHERE a.row_number <= &&cs_top.
),
ash_extended2 AS (
SELECT CASE a.user_id WHEN 0 THEN 'SYS' ELSE application_category(a.sql_text, a.sql_opname) END AS type,
       a.row_number,
       a.aas,
       a.sessions,
       a.sql_id,
       LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN a.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(a.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE a.sql_fulltext END),100000),5,'0') AS sqlid,
       a.sql_plan_hash_value,
       s.version_count,
       a.has_baseline,
       a.has_profile,
       a.has_patch,
       a.sql_text,
       a.module,
       a.con_id,
       a.timed_event,
       a.pdb_name,
       a.sql_opname,
       a.user_id
  FROM ash_extended a,
       v$sqlstats s
 WHERE s.sql_id(+) = a.sql_id
   AND s.con_id(+) = a.con_id
)
SELECT a.type,
       a.row_number,
       a.aas,
       a.sessions,
       a.sql_id,
       a.sqlid,
       a.sql_plan_hash_value,
       a.version_count,
       a.has_baseline,
       a.has_profile,
       a.has_patch,
       a.sql_text,
       a.timed_event,
       a.pdb_name,
       a.module
  FROM ash_extended2 a
 ORDER BY
       CASE a.type WHEN 'TP' THEN 1 WHEN 'RO' THEN 2 WHEN 'BG' THEN 3 WHEN 'UN' THEN 4 WHEN 'SYS' THEN 5 ELSE 6 END,
       a.row_number
/
--
-- CLEAR BREAK COMPUTE;
---------------------------------------------------------------------------------------
--