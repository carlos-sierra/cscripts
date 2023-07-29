-- cs_latency_hist_internal_2.sql: called by lah.sql and cs_latency_hist.sql
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET PAGES 300 LONGC 120;
--
COL type FOR A2 HEA 'Ty';
COL t_9_cpu_ms_per_exec FOR A10 HEA 'CPU ms p/e|(&&t_9_snap_begin.-|&&t_9_snap_end.)';
COL t_8_cpu_ms_per_exec FOR A10 HEA 'CPU ms p/e|(&&t_8_snap_begin.-|&&t_8_snap_end.)';
COL t_7_cpu_ms_per_exec FOR A10 HEA 'CPU ms p/e|(&&t_7_snap_begin.-|&&t_7_snap_end.)';
COL t_6_cpu_ms_per_exec FOR A10 HEA 'CPU ms p/e|(&&t_6_snap_begin.-|&&t_6_snap_end.)';
COL t_5_cpu_ms_per_exec FOR A10 HEA 'CPU ms p/e|(&&t_5_snap_begin.-|&&t_5_snap_end.)';
COL t_4_cpu_ms_per_exec FOR A10 HEA 'CPU ms p/e|(&&t_4_snap_begin.-|&&t_4_snap_end.)';
COL t_3_cpu_ms_per_exec FOR A10 HEA 'CPU ms p/e|(&&t_3_snap_begin.-|&&t_3_snap_end.)';
COL t_2_cpu_ms_per_exec FOR A10 HEA 'CPU ms p/e|(&&t_2_snap_begin.-|&&t_2_snap_end.)';
COL t_1_cpu_ms_per_exec FOR A10 HEA 'CPU ms p/e|(&&t_1_snap_begin.-|&&t_1_snap_end.)';
COL t_0_cpu_ms_per_exec FOR A10 HEA 'CPU ms p/e|(&&t_0_snap_begin.-|&&t_0_snap_end.)';
COL execs FOR 999,990 HEA 'Executions|(&&t_0_snap_begin.-|&&t_0_snap_end.)';
COL sql_text FOR A60 TRUNC;
COL pdb_name FOR A28 TRUNC;
COL plan_hash_value FOR 9999999999 HEA 'Plan Hash';
COL has_baseline FOR A2 HEA 'BL';
COL has_profile FOR A2 HEA 'PR';
COL has_patch FOR A2 HEA 'PA';
COL regression FOR 999,990 HEA 'Regress|Perc %';
COL sqlid FOR A5 HEA 'SQL|HV';
--
BREAK ON type SKIP PAGE DUPL;
--
PRO 
PRO CPU Latency - TOP &&cs_top. SQL for each Type (as per last &&cs_last_snap_mins. minutes and compared to recent AWR snapshots)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
FUNCTION application_category (
  p_sql_text     IN VARCHAR2, 
  p_command_name IN VARCHAR2 DEFAULT NULL
)
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
FUNCTION get_sql_hv (p_sqltext IN CLOB)
RETURN VARCHAR2
IS
  l_sqltext CLOB := REGEXP_REPLACE(p_sqltext, '/\* REPO_[A-Z0-9]{1,25} \*/ '); -- removes "/* REPO_IFCDEXZQGAYDAMBQHAYQ */ " DBPERF-8819
BEGIN
  IF l_sqltext LIKE '%/* %(%,%)% [%] */%' THEN l_sqltext := REGEXP_REPLACE(l_sqltext, '\[([[:digit:]]{4,5})\] '); END IF; -- removes bucket_id "[1001] "
  RETURN LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(l_sqltext),100000),5,'0');
END get_sql_hv;
/****************************************************************************************/
sqlstats AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.con_id,
       application_category(s.sql_text, /*v.command_name*/ 'UNKNOWN') AS type, -- passing UNKNOWN else KIEV envs would show a lot of unrelated SQL under RO
       s.delta_elapsed_time/GREATEST(s.delta_execution_count,1)/1e3 AS et_ms_per_exec,
       s.delta_cpu_time/GREATEST(s.delta_execution_count,1)/1e3 AS cpu_ms_per_exec,
       s.delta_user_io_wait_time/GREATEST(s.delta_execution_count,1)/1e3 AS io_ms_per_exec,
       s.delta_application_wait_time/GREATEST(s.delta_execution_count,1)/1e3 AS appl_ms_per_exec,
       s.delta_concurrency_time/GREATEST(s.delta_execution_count,1)/1e3 AS conc_ms_per_exec,
       s.delta_execution_count AS execs,
       s.delta_rows_processed/GREATEST(s.delta_execution_count,1) AS rows_per_exec,
       s.delta_buffer_gets/GREATEST(s.delta_execution_count,1) AS gets_per_exec,
       s.delta_disk_reads/GREATEST(s.delta_execution_count,1) AS reads_per_exec,
       s.delta_direct_writes/GREATEST(s.delta_execution_count,1) AS writes_per_exec,
       s.delta_fetch_count/GREATEST(s.delta_execution_count,1) AS fetches_per_exec,
       s.sql_id,
       s.sql_text,
       s.sql_fulltext,
       s.plan_hash_value,
       s.last_active_child_address
  FROM v$sqlstats s
 WHERE s.delta_elapsed_time > 0
   AND ROWNUM >= 1
),
sqlstats_extended AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.type,
       s.et_ms_per_exec,
       s.cpu_ms_per_exec,
       s.io_ms_per_exec,
       s.appl_ms_per_exec,
       s.conc_ms_per_exec,
       s.execs,
       s.rows_per_exec,
       s.gets_per_exec,
       s.reads_per_exec,
       s.writes_per_exec,
       s.fetches_per_exec,
       s.sql_id,
       s.sql_text,
       s.sql_fulltext,
       s.plan_hash_value,
       s.last_active_child_address,
       s.con_id,
       c.name pdb_name,
       ROW_NUMBER() OVER (PARTITION BY s.type ORDER BY s.cpu_ms_per_exec DESC) row_number
  FROM sqlstats s,
       v$containers c
 WHERE s.type IN ('TP', 'RO', 'BG', 'UN')
   AND c.con_id = s.con_id
   AND ROWNUM >= 1
),
sqlstats_current AS (
SELECT CASE s.type WHEN 'TP' THEN 1 WHEN 'RO' THEN 2 WHEN 'BG' THEN 3 WHEN 'UN' THEN 4 ELSE 5 END AS type_order_by,
       s.type,
       s.row_number,
       s.et_ms_per_exec,
       s.cpu_ms_per_exec,
       s.io_ms_per_exec,
       s.appl_ms_per_exec,
       s.conc_ms_per_exec,
       s.execs,
       s.rows_per_exec,
       s.gets_per_exec,
       s.reads_per_exec,
       s.sql_id,
       s.plan_hash_value,
       v.has_baseline,
       v.has_profile,
       v.has_patch,
       s.sql_text,
       s.sql_fulltext,
       s.con_id,
       s.pdb_name
  FROM sqlstats_extended s
  CROSS APPLY (
         SELECT CASE WHEN v.sql_plan_baseline IS NULL THEN 'N' ELSE 'Y' END AS has_baseline, 
                CASE WHEN v.sql_profile IS NULL THEN 'N' ELSE 'Y' END AS has_profile, 
                CASE WHEN v.sql_patch IS NULL THEN 'N' ELSE 'Y' END AS has_patch 
           FROM v$sql v
          WHERE s.plan_hash_value > 0
            AND v.sql_id = s.sql_id
            AND v.con_id = s.con_id
            AND v.plan_hash_value = s.plan_hash_value
            AND v.child_address = s.last_active_child_address
          ORDER BY 
                v.last_active_time DESC
          FETCH FIRST 1 ROW ONLY
       ) v
 WHERE s.row_number <= &&cs_top.
   AND ROWNUM >= 1
),
sqlstats_hist AS (
      SELECT /*+ MATERIALIZE NO_MERGE */
            h.con_id,
            h.sql_id,
            h.snap_id,
            SUM(h.elapsed_time_delta)/GREATEST(SUM(h.executions_delta),1)/1e3 AS et_ms_per_exec,
            SUM(h.cpu_time_delta)/GREATEST(SUM(h.executions_delta),1)/1e3 AS cpu_ms_per_exec,
            SUM(h.iowait_delta)/GREATEST(SUM(h.executions_delta),1)/1e3 AS io_ms_per_exec,
            SUM(h.apwait_delta)/GREATEST(SUM(h.executions_delta),1)/1e3 AS appl_ms_per_exec,
            SUM(h.ccwait_delta)/GREATEST(SUM(h.executions_delta),1)/1e3 AS conc_ms_per_exec,
            SUM(h.executions_delta) AS execs,
            SUM(h.rows_processed_delta)/GREATEST(SUM(h.executions_delta),1) AS rows_per_exec,
            SUM(h.buffer_gets_delta)/GREATEST(SUM(h.executions_delta),1) AS gets_per_exec,
            SUM(h.disk_reads_delta)/GREATEST(SUM(h.executions_delta),1) AS reads_per_exec,
            SUM(h.fetches_delta)/GREATEST(SUM(h.executions_delta),1) AS fetches_per_exec,
            MAX(SUM(h.cpu_time_delta)/GREATEST(SUM(h.executions_delta),1)/1e3) OVER (PARTITION BY h.con_id, h.sql_id) AS max_cpu_ms_per_exec
      FROM  dba_hist_sqlstat h
      WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
      AND   h.instance_number = TO_NUMBER('&&cs_instance_number.')
      AND   h.snap_id BETWEEN TO_NUMBER('&&t_9_snap_id.') AND TO_NUMBER('&&t_1_snap_id.')
      AND   (h.con_id, h.sql_id) IN (SELECT con_id, sql_id FROM sqlstats_current)
      AND   h.optimizer_cost > 0 -- if 0 or null then whole row is suspected bogus
      AND   ROWNUM >= 1
      GROUP BY
            h.con_id,
            h.sql_id,
            h.snap_id
)
SELECT c.type,
       LPAD(CASE WHEN t_9.cpu_ms_per_exec IS NULL THEN '-' ELSE TO_CHAR(t_9.cpu_ms_per_exec, '9,999,990') END, 10, ' ') AS t_9_cpu_ms_per_exec,
       LPAD(CASE WHEN t_8.cpu_ms_per_exec IS NULL THEN '-' ELSE TO_CHAR(t_8.cpu_ms_per_exec, '9,999,990') END, 10, ' ') AS t_8_cpu_ms_per_exec,
       LPAD(CASE WHEN t_7.cpu_ms_per_exec IS NULL THEN '-' ELSE TO_CHAR(t_7.cpu_ms_per_exec, '9,999,990') END, 10, ' ') AS t_7_cpu_ms_per_exec,
       LPAD(CASE WHEN t_6.cpu_ms_per_exec IS NULL THEN '-' ELSE TO_CHAR(t_6.cpu_ms_per_exec, '9,999,990') END, 10, ' ') AS t_6_cpu_ms_per_exec,
       LPAD(CASE WHEN t_5.cpu_ms_per_exec IS NULL THEN '-' ELSE TO_CHAR(t_5.cpu_ms_per_exec, '9,999,990') END, 10, ' ') AS t_5_cpu_ms_per_exec,
       LPAD(CASE WHEN t_4.cpu_ms_per_exec IS NULL THEN '-' ELSE TO_CHAR(t_4.cpu_ms_per_exec, '9,999,990') END, 10, ' ') AS t_4_cpu_ms_per_exec,
       LPAD(CASE WHEN t_3.cpu_ms_per_exec IS NULL THEN '-' ELSE TO_CHAR(t_3.cpu_ms_per_exec, '9,999,990') END, 10, ' ') AS t_3_cpu_ms_per_exec,
       LPAD(CASE WHEN t_2.cpu_ms_per_exec IS NULL THEN '-' ELSE TO_CHAR(t_2.cpu_ms_per_exec, '9,999,990') END, 10, ' ') AS t_2_cpu_ms_per_exec,
       LPAD(CASE WHEN t_1.cpu_ms_per_exec IS NULL THEN '-' ELSE TO_CHAR(t_1.cpu_ms_per_exec, '9,999,990') END, 10, ' ') AS t_1_cpu_ms_per_exec,
       '|' AS "|",
       LPAD(CASE WHEN c.cpu_ms_per_exec IS NULL THEN '-' ELSE TO_CHAR(c.cpu_ms_per_exec, '9,999,990') END, 10, ' ') AS t_0_cpu_ms_per_exec,
       c.execs,
       CASE WHEN c.cpu_ms_per_exec > 1.1 * t_1.max_cpu_ms_per_exec THEN 100 * ((c.cpu_ms_per_exec / t_1.max_cpu_ms_per_exec) - 1)  END AS regression, 
       c.sql_id,
      --  LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN c.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(c.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE c.sql_fulltext END),100000),5,'0') AS sqlid,
       get_sql_hv(c.sql_fulltext) AS sqlid,
       c.plan_hash_value,
       c.has_baseline,
       c.has_profile,
       c.has_patch,
       c.sql_text,
       c.pdb_name
  FROM sqlstats_current c,
       sqlstats_hist t_1,
       sqlstats_hist t_2,
       sqlstats_hist t_3,
       sqlstats_hist t_4,
       sqlstats_hist t_5,
       sqlstats_hist t_6,
       sqlstats_hist t_7,
       sqlstats_hist t_8,
       sqlstats_hist t_9
 WHERE 1 = 1
   AND t_1.con_id(+) = c.con_id AND t_1.sql_id(+) = c.sql_id AND t_1.snap_id(+) = TO_NUMBER('&&t_1_snap_id.')
   AND t_2.con_id(+) = c.con_id AND t_2.sql_id(+) = c.sql_id AND t_2.snap_id(+) = TO_NUMBER('&&t_2_snap_id.')
   AND t_3.con_id(+) = c.con_id AND t_3.sql_id(+) = c.sql_id AND t_3.snap_id(+) = TO_NUMBER('&&t_3_snap_id.')
   AND t_4.con_id(+) = c.con_id AND t_4.sql_id(+) = c.sql_id AND t_4.snap_id(+) = TO_NUMBER('&&t_4_snap_id.')
   AND t_5.con_id(+) = c.con_id AND t_5.sql_id(+) = c.sql_id AND t_5.snap_id(+) = TO_NUMBER('&&t_5_snap_id.')
   AND t_6.con_id(+) = c.con_id AND t_6.sql_id(+) = c.sql_id AND t_6.snap_id(+) = TO_NUMBER('&&t_6_snap_id.')
   AND t_7.con_id(+) = c.con_id AND t_7.sql_id(+) = c.sql_id AND t_7.snap_id(+) = TO_NUMBER('&&t_7_snap_id.')
   AND t_8.con_id(+) = c.con_id AND t_8.sql_id(+) = c.sql_id AND t_8.snap_id(+) = TO_NUMBER('&&t_8_snap_id.')
   AND t_9.con_id(+) = c.con_id AND t_9.sql_id(+) = c.sql_id AND t_9.snap_id(+) = TO_NUMBER('&&t_9_snap_id.')
 ORDER BY
       c.type_order_by,
       c.row_number
/
PRO
PRO Regress Perc %: When current CPU latency versus maximum latency from recent history is over 10% (regressions of < 10% are excluded)
--
-- CLEAR BREAK;
