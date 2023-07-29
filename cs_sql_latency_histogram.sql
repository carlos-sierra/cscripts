----------------------------------------------------------------------------------------
--
-- File name:   cs_sql_latency_histogram.sql
--
-- Purpose:     SQL Latency Histogram (elapsed time over executions)
--
-- Author:      Carlos Sierra
--
-- Version:     2022/02/14
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sql_latency_histogram.sql
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
DEF cs_script_name = 'cs_sql_latency_histogram';
DEF cs_hours_range_default = '168';
DEF cs_include_sys = 'N';
DEF cs_include_iod = 'N';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--@@cs_internal/&&cs_set_container_to_cdb_root.
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
PRO 4. SQL Text piece (e.g.: ScanQuery, getValues, TableName, IndexName):
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
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&kiev_tx." "&&sql_text_piece." "&&cs_sql_id." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO SQL_TYPE     : "&&kiev_tx." [{*}|TP|RO|BG|IG|UN|TP,RO|TP,RO,BG]
PRO SQL_TEXT     : "&&sql_text_piece."
PRO SQL_ID       : "&&cs_sql_id."
--
COL sql_type FOR A4 HEA 'SQL|Type';
COL sql_plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL less_than_1s FOR 999,999,990 HEA 'Less than|1 sec';
COL less_than_2s FOR 999,999,990 HEA 'Less than|2 secs';
COL less_than_4s FOR 999,999,990 HEA 'Less than|4 secs';
COL less_than_8s FOR 999,999,990 HEA 'Less than|8 secs';
COL less_than_16s FOR 999,999,990 HEA 'Less than|16 secs';
COL less_than_32s FOR 999,999,990 HEA 'Less than|32 secs';
COL less_than_64s FOR 999,999,990 HEA 'Less than|64 secs';
COL less_than_128s FOR 999,999,990 HEA 'Less than|128 secs';
COL less_than_256s FOR 999,999,990 HEA 'Less than|256 secs';
COL less_than_512s FOR 999,999,990 HEA 'Less than|512 secs';
COL less_than_1024s FOR 999,999,990 HEA 'Less than|1024 secs';
COL more_than_1024s FOR 999,999,990 HEA 'More than|1024 secs';
COL avg_seconds FOR 99,990.000 HEA 'Avg|secs';
COL pctl_50_secs FOR 99,990.000 HEA 'Pctl 50th|secs';
COL pctl_95_secs FOR 99,990.000 HEA 'Pctl 95th|secs';
COL pctl_97_secs FOR 99,990.000 HEA 'Pctl 97th|secs';
COL pctl_99_secs FOR 99,990.000 HEA 'Pctl 99th|secs';
COL max_seconds FOR 99,990.000 HEA 'Max|secs';
COL sql_text FOR A100 HEA 'SQL Text' TRUNC;
COL username FOR A30 HEA 'Username' TRUNC;
COL pdb_name FOR A30 HEA 'PDB Name' TRUNC;
COL sqlid FOR A5 HEA 'SQLHV';
--
BREAK ON pdb_name SKIP PAGE DUP;
--
PRO
PRO SQL Performance Histogram
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
FUNCTION application_category (p_sql_text IN VARCHAR2)
RETURN VARCHAR2
IS
  k_appl_handle_prefix CONSTANT VARCHAR2(30) := CHR(37)||'/*'||CHR(37);
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
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'Set ddl lock timeout for session'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.step_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'delete.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getForUpdate.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'insert.step_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'update.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Drop partition'||k_appl_handle_suffix 
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
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'getFutureWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getPriorWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateLeases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'enumerateLeaseTypes'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getHistoricalAssignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getAllWorkflowDefinitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getVersionHistory'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Find interval partitions for schema'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getStepInstances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getOldestGcWorkflowInstance'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getNextRecordID'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.dataplane_alias'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLeaseNonce'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.leases_types'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.leases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getByKey.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getRecordId.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLast.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.historical_assignments'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'isPartitionDropDisabled'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'Check if there are active rows for partition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getRunningInstancesCount'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_definitions'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLatestWorkflowDefinition'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLast.step_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.workflow_instances'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'get.step_instances'||k_appl_handle_suffix 
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
    --
    OR  p_sql_text LIKE k_appl_handle_prefix||'getUnownedLeases'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getFutureWorks'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getMinorVersionsAtAndAfter'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getLeaseDecorators'||k_appl_handle_suffix 
    OR  p_sql_text LIKE k_appl_handle_prefix||'getUnownedLeasesByFiFo'||k_appl_handle_suffix 
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
    OR  p_sql_text LIKE k_appl_handle_prefix||'OPT_DYN_SAMP'||k_appl_handle_suffix 
  THEN RETURN 'IG'; /* Ignore */
  --
  ELSE RETURN 'UN'; /* Unknown */
  END IF;
END application_category;
/****************************************************************************************/
FUNCTION get_sql_hv (p_sqltext IN CLOB)
RETURN VARCHAR2
IS
  l_sqltext CLOB := REGEXP_REPLACE(p_sqltext, '/\* REPO_[A-Z0-9]{1,25} \*/ '); -- removes "/* REPO_IFCDEXZQGAYDAMBQHAYQ */ " DBPERF-8819
BEGIN
  IF l_sqltext LIKE '%/* %(%,%)% [%] */%' THEN l_sqltext := REGEXP_REPLACE(l_sqltext, '\[([[:digit:]]{4,5})\] '); END IF; -- removes bucket_id "[1001] "
  RETURN LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(l_sqltext),100000),5,'0');
END get_sql_hv;
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
   AND ROWNUM >= 1
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
   AND ROWNUM >= 1
),
ash_enum AS (
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
       h.user_id,
       ROW_NUMBER() OVER (PARTITION BY h.con_id, h.session_id, h.session_serial#, h.xid, h.sql_exec_id, h.sql_exec_start, h.sql_id, h.sql_plan_hash_value ORDER BY h.sample_time ASC NULLS LAST) row_num_asc,
       ROW_NUMBER() OVER (PARTITION BY h.con_id, h.session_id, h.session_serial#, h.xid, h.sql_exec_id, h.sql_exec_start, h.sql_id, h.sql_plan_hash_value ORDER BY h.sample_time DESC NULLS LAST) row_num_desc
  FROM ash_raw h
 WHERE ROWNUM >= 1
),
ash_secs AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       f.con_id,
       f.session_id,
       f.session_serial#,
       f.xid,
       f.sql_exec_id,
       f.sql_exec_start,
       f.sql_id,
       f.sql_plan_hash_value,
       f.user_id,
       NVL((86400 * EXTRACT(DAY FROM (l.sample_time - f.sql_exec_start))) + (3600 * EXTRACT(HOUR FROM (l.sample_time - f.sql_exec_start))) + (60 * EXTRACT(MINUTE FROM (l.sample_time - f.sql_exec_start))) + EXTRACT(SECOND FROM (l.sample_time - f.sql_exec_start)), 0) seconds,
       f.sample_time f_sample_time,
       l.sample_time l_sample_time
  FROM ash_enum f,
       ash_enum l
 WHERE f.row_num_asc = 1
   AND l.row_num_desc = 1
   AND l.con_id = f.con_id
   AND l.session_id = f.session_id
   AND l.session_serial# = f.session_serial#
   AND NVL(l.xid, UTL_RAW.CAST_TO_RAW('-666')) = NVL(f.xid, UTL_RAW.CAST_TO_RAW('-666'))
   AND l.sql_exec_id = f.sql_exec_id
   AND l.sql_exec_start = f.sql_exec_start
   AND l.sql_id = f.sql_id
   AND l.sql_plan_hash_value = f.sql_plan_hash_value
   AND l.user_id = f.user_id
   AND ROWNUM >= 1
),
ash_grp AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.con_id,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id,
       SUM(CASE WHEN h.seconds < 1 THEN 1 ELSE 0 END) less_than_1s,
       SUM(CASE WHEN h.seconds >= 1 AND h.seconds < 2 THEN 1 ELSE 0 END) less_than_2s,
       SUM(CASE WHEN h.seconds >= 2 AND h.seconds < 4 THEN 1 ELSE 0 END) less_than_4s,
       SUM(CASE WHEN h.seconds >= 4 AND h.seconds < 8 THEN 1 ELSE 0 END) less_than_8s,
       SUM(CASE WHEN h.seconds >= 8 AND h.seconds < 16 THEN 1 ELSE 0 END) less_than_16s,
       SUM(CASE WHEN h.seconds >= 16 AND h.seconds < 32 THEN 1 ELSE 0 END) less_than_32s,
       SUM(CASE WHEN h.seconds >= 32 AND h.seconds < 64 THEN 1 ELSE 0 END) less_than_64s,
       SUM(CASE WHEN h.seconds >= 64 AND h.seconds < 128 THEN 1 ELSE 0 END) less_than_128s,
       SUM(CASE WHEN h.seconds >= 128 AND h.seconds < 256 THEN 1 ELSE 0 END) less_than_256s,
       SUM(CASE WHEN h.seconds >= 256 AND h.seconds < 512 THEN 1 ELSE 0 END) less_than_512s,
       SUM(CASE WHEN h.seconds >= 512 AND h.seconds < 1024 THEN 1 ELSE 0 END) less_than_1024s,
       SUM(CASE WHEN h.seconds >= 1024 THEN 1 ELSE 0 END) more_than_1024s,
       AVG(h.seconds) avg_seconds,
       PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY h.seconds) pctl_50_secs,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY h.seconds) pctl_95_secs,
       PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY h.seconds) pctl_97_secs,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY h.seconds) pctl_99_secs,
       MAX(h.seconds) max_seconds
  FROM ash_secs h
 WHERE ROWNUM >= 1
 GROUP BY
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
       s.sql_text,
      --  LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(REPLACE(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END,s.parsing_schema_name)),100000),5,'0') AS sqlid
       get_sql_hv(s.sql_fulltext) AS sqlid
  FROM v$sql s
 WHERE sql_id IS NOT NULL
   AND ('&&cs_sql_id.' IS NULL OR s.sql_id = '&&cs_sql_id.')
   AND ('&&sql_text_piece.' IS NULL OR UPPER(s.sql_text) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
  --  AND ('&&kiev_tx.' = '*' OR '&&kiev_tx.' LIKE CHR(37)||application_category(s.sql_text)||CHR(37)) -- does not seem to work on 19c
   AND CASE WHEN '&&kiev_tx.' = '*' THEN 1 WHEN '&&kiev_tx.' LIKE CHR(37)||application_category(s.sql_text)||CHR(37) THEN 1 ELSE 0 END = 1
   AND ROWNUM >= 1
 GROUP BY
       s.con_id,
       s.sql_id,
       application_category(s.sql_text),
       s.sql_text,
      --  LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(REPLACE(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END,s.parsing_schema_name)),100000),5,'0')
       get_sql_hv(s.sql_fulltext)
),
hsql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.con_id,
       h.sql_id,
       application_category(DBMS_LOB.substr(h.sql_text, 1000)) sql_type,
       DBMS_LOB.substr(h.sql_text, 1000) sql_text,
      --  LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN h.sql_text LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(h.sql_text, '\[([[:digit:]]{4})\] ') ELSE h.sql_text END),100000),5,'0') AS sqlid
       get_sql_hv(h.sql_text) AS sqlid
  FROM dba_hist_sqltext h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND ('&&cs_sql_id.' IS NULL OR h.sql_id = '&&cs_sql_id.')
   AND ('&&sql_text_piece.' IS NULL OR UPPER(DBMS_LOB.substr(h.sql_text, 1000)) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
  --  AND ('&&kiev_tx.' = '*' OR '&&kiev_tx.' LIKE CHR(37)||application_category(DBMS_LOB.substr(h.sql_text, 1000))||CHR(37)) -- does not seem to work on 19c
   AND CASE WHEN '&&kiev_tx.' = '*' THEN 1 WHEN '&&kiev_tx.' LIKE CHR(37)||application_category(DBMS_LOB.SUBSTR(h.sql_text, 1000))||CHR(37) THEN 1 ELSE 0 END = 1
   AND ROWNUM >= 1
)
SELECT NVL(s.sql_type, hs.sql_type) AS sql_type,
       h.sql_id,
       NVL(s.sqlid, hs.sqlid) AS sqlid,
       h.sql_plan_hash_value,
       h.less_than_1s,
       h.less_than_2s,
       h.less_than_4s,
       h.less_than_8s,
       h.less_than_16s,
       h.less_than_32s,
       h.less_than_64s,
       h.less_than_128s,
       h.less_than_256s,
       h.less_than_512s,
       h.less_than_1024s,
       h.more_than_1024s,
       h.avg_seconds,
       h.pctl_50_secs,
       h.pctl_95_secs,
       h.pctl_97_secs,
       h.pctl_99_secs,
       h.max_seconds,
       NVL(s.sql_text, hs.sql_text) sql_text,
       u.username,
       c.name pdb_name
  FROM ash_grp h,
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
   AND ('&&cs_include_iod.' = 'Y' OR ('&&cs_include_iod.' = 'N' AND u.username <> '&&cs_tools_schema.'))
 ORDER BY 
       c.name,
       u.username,
       CASE s.sql_type WHEN 'TP' THEN 1 WHEN 'RO' THEN 2 WHEN 'BG' THEN 3 WHEN 'UN' THEN 4 WHEN 'IG' THEN 5 ELSE 9 END,
       h.sql_id, 
       h.sql_plan_hash_value
/
--
CLEAR BREAK;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&kiev_tx." "&&sql_text_piece." "&&cs_sql_id." 
--
@@cs_internal/cs_spool_tail.sql
--
--@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--