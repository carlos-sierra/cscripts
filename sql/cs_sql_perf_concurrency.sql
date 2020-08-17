----------------------------------------------------------------------------------------
--
-- File name:   cs_sql_perf_concurrency.sql
--
-- Purpose:     SQL Performance - Concurrency larger than N
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/14
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sql_perf_concurrency.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sql_perf_concurrency';
DEF cs_hours_range_default = '168';
DEF cs_include_sys = 'N';
DEF cs_include_iod = 'N';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--ALTER SESSION SET container = CDB$ROOT;
--
PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO *=All, TP=Transaction Processing, RO=Read Only, BG=Background, IG=Ignore, UN=Unknown
PRO
PRO 3. SQL Type: [{*}|TP|RO|BG|IG|UN|TP,RO|TP,RO,BG] 
DEF kiev_tx = '&3.';
UNDEF 3;
COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT UPPER(NVL(TRIM('&&kiev_tx.'), '*')) kiev_tx FROM DUAL
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Enter additional SQL Text filtering, such as Table name or SQL Text piece
PRO
PRO 4. SQL Text piece (optional):
DEF sql_text_piece = '&4.';
UNDEF 4;
--
PRO
PRO Filtering SQL to reduce search space.
PRO By entering an optional SQL_ID, scope is further reduced
PRO
PRO 5. SQL_ID (optional):
DEF cs_sql_id = '&5.';
UNDEF 5;
/
PRO
PRO 6. Concurrency greater than or equal (GTE) : [{2}|2-36]
DEF concurrency_gte = '&6.';
UNDEF 6;
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&kiev_tx." "&&sql_text_piece." "&&cs_sql_id." "&&concurrency_gte."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO SQL_TYPE     : "&&kiev_tx." [{*}|TP|RO|BG|IG|UN|TP,RO|TP,RO,BG]
PRO SQL_TEXT     : "&&sql_text_piece."
PRO SQL_ID       : "&&cs_sql_id."
PRO CONCURRENCY  : "&&concurrency_gte." [{2}|2-36]
--
COL concurrency FOR 990 HEA 'Conc|GTE';
COL samples FOR 999,990 HEA 'Samples';
COL f_sample_time FOR A19 HEA 'First Sample Time';
COL l_sample_time FOR A19 HEA 'Last Sample Time';
COL sql_type FOR A4 HEA 'SQL|Type';
COL sql_plan_hash_value HEA 'Plan|Hash Value';
COL sql_text FOR A100 HEA 'SQL Text' TRUNC;
COL username FOR A30 HEA 'Username' TRUNC;
COL pdb_name FOR A30 HEA 'PDB Name' TRUNC;
--
BREAK ON pdb_name SKIP PAGE DUP ON sql_id SKIP 1 DUP;
--
PRO
PRO SQL Concurrency (>= "&&concurrency_gte." [{2}|2-36])
PRO ~~~~~~~~~~~~~~~
WITH
FUNCTION application_category (p_sql_text IN VARCHAR2)
RETURN VARCHAR2
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
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch max sequence for KIEVMUTATIONLOG'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch max sequence for KievTransactionKeys'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch partition interval for KIEVMUTATIONLOG'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find High value for table KIEVMUTATIONLOG partition'||k_appl_handle_suffix -- streaming
    OR  p_sql_text LIKE k_appl_handle_prefix||'Init lock name for snapshot'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'List snapshot tables.'||k_appl_handle_suffix -- snapshot
    OR  p_sql_text LIKE k_appl_handle_prefix||'Tail read bucket'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'performSegmentedScanQuery'||k_appl_handle_suffix 
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
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find High value for KT partition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find High value for KTK partition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find partitions for KIEVMUTATIONLOG'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find partitions for KT'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find partitions for KTK'||k_appl_handle_suffix 
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
    OR  p_sql_text LIKE CHR(37)||k_appl_handle_prefix||'OPT_DYN_SAMP'||k_appl_handle_suffix 
  THEN RETURN 'IG'; /* Ignore */
  --
  ELSE RETURN 'UN'; /* Unknown */
  END IF;
END application_category;
/****************************************************************************************/
ash_raw AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.con_id,
       h.session_id,
       h.session_serial#,
       h.xid,
       h.sql_exec_id,
       h.sql_exec_start,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id
  FROM v$active_session_history h
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.sql_exec_id IS NOT NULL
   AND h.sql_exec_start IS NOT NULL
   AND h.sql_id IS NOT NULL
   AND ('&&cs_sql_id.' IS NULL OR h.sql_id = '&&cs_sql_id.')
   AND h.sql_plan_hash_value IS NOT NULL
 UNION
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.con_id,
       h.session_id,
       h.session_serial#,
       h.xid,
       h.sql_exec_id,
       h.sql_exec_start,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id
  FROM dba_hist_active_sess_history h
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND h.sql_exec_id IS NOT NULL
   AND h.sql_exec_start IS NOT NULL
   AND h.sql_id IS NOT NULL
   AND ('&&cs_sql_id.' IS NULL OR h.sql_id = '&&cs_sql_id.')
   AND h.sql_plan_hash_value IS NOT NULL
),
ash_enum AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       COUNT(*) concurrency,
       CAST(h.sample_time AS DATE) sample_time,
       h.con_id,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id
  FROM ash_raw h
 GROUP BY
       CAST(h.sample_time AS DATE),
       h.con_id,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id
HAVING COUNT(*) >= NVL(TO_NUMBER('&&concurrency_gte.'), 2)
),
ash_conc AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       MIN(h.sample_time) min_sample_time,
       MAX(h.sample_time) max_sample_time,
       COUNT(*) samples,
       h.concurrency,
       h.con_id,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id
  FROM ash_enum h
 GROUP BY
       h.concurrency,
       h.con_id,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id
),
vsql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.con_id,
       s.sql_id,
       application_category(s.sql_text) sql_type,
       s.sql_text
  FROM v$sql s
 WHERE sql_id IS NOT NULL
   AND ('&&cs_sql_id.' IS NULL OR s.sql_id = '&&cs_sql_id.')
   AND ('&&sql_text_piece.' IS NULL OR UPPER(s.sql_text) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
   AND ('&&kiev_tx.' = '*' OR '&&kiev_tx.' LIKE CHR(37)||application_category(s.sql_text)||CHR(37))
 GROUP BY
       s.con_id,
       s.sql_id,
       application_category(s.sql_text),
       s.sql_text
),
hsql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.con_id,
       h.sql_id,
       application_category(DBMS_LOB.substr(h.sql_text, 1000)) sql_type,
       DBMS_LOB.substr(h.sql_text, 1000) sql_text
  FROM dba_hist_sqltext h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND ('&&cs_sql_id.' IS NULL OR h.sql_id = '&&cs_sql_id.')
   AND ('&&sql_text_piece.' IS NULL OR UPPER(DBMS_LOB.substr(h.sql_text, 1000)) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
   AND ('&&kiev_tx.' = '*' OR '&&kiev_tx.' LIKE CHR(37)||application_category(DBMS_LOB.substr(h.sql_text, 1000))||CHR(37))
)
SELECT NVL(s.sql_type, hs.sql_type) sql_type,
       h.sql_id,
       TO_CHAR(h.min_sample_time, '&&cs_datetime_full_format.') f_sample_time,
       TO_CHAR(h.max_sample_time, '&&cs_datetime_full_format.') l_sample_time,
       h.concurrency,
       h.samples,
       h.sql_plan_hash_value,
       NVL(s.sql_text, hs.sql_text) sql_text,
       u.username,
       c.name pdb_name
  FROM ash_conc h,
       vsql s,
       hsql hs,
       v$containers c,
       cdb_users u
 WHERE s.con_id(+) = h.con_id
   AND s.sql_id(+) = h.sql_id
   AND hs.con_id(+) = h.con_id
   AND hs.sql_id(+) = h.sql_id
   AND NVL(s.sql_type, hs.sql_type) IS NOT NULL
   AND c.con_id = h.con_id
   AND c.open_mode = 'READ WRITE'
   AND u.con_id = h.con_id
   AND u.user_id = h.user_id
   AND ('&&cs_include_sys.' = 'Y' OR ('&&cs_include_sys.' = 'N' AND u.username <> 'SYS'))
   AND ('&&cs_include_iod.' = 'Y' OR ('&&cs_include_iod.' = 'N' AND u.username <> 'C##IOD'))
 ORDER BY 
       c.name,
       NVL(s.sql_type, hs.sql_type),
       h.sql_id,
       h.min_sample_time,
       h.sql_plan_hash_value
/
--
CLEAR BREAK;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&kiev_tx." "&&sql_text_piece." "&&cs_sql_id." "&&concurrency_gte."
--
@@cs_internal/cs_spool_tail.sql
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--