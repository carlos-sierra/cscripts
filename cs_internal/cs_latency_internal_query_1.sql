-- cs_latency_internal_query_1.sql: called by cs_latency.sql and cs_latency_extended.sql
PRO 
PRO TOP active SQL as per DB Latency (and DB Load) v$sqlstats as per last &&cs_last_snap_mins. minutes
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
FUNCTION application_category (
  p_sql_text     IN VARCHAR2, 
  p_command_name IN VARCHAR2 DEFAULT NULL
)
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
FUNCTION get_sql_hv (p_sqltext IN CLOB)
RETURN VARCHAR2
IS
BEGIN
  RETURN LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN p_sqltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(p_sqltext, '\[([[:digit:]]{4})\] ') ELSE p_sqltext END),100000),5,'0');
END get_sql_hv;
/****************************************************************************************/
sqlstats AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */
       s.con_id,
       application_category(s.sql_text, /*v.command_name*/ 'UNKNOWN') AS sql_type, -- passing UNKNOWN else KIEV envs would show a lot of unrelated SQL under RO
       s.delta_elapsed_time/GREATEST(s.delta_execution_count,1)/1e3 AS et_ms_per_exec,
       s.delta_cpu_time/GREATEST(s.delta_execution_count,1)/1e3 AS cpu_ms_per_exec,
       s.delta_user_io_wait_time/GREATEST(s.delta_execution_count,1)/1e3 AS io_ms_per_exec,
       s.delta_application_wait_time/GREATEST(s.delta_execution_count,1)/1e3 AS appl_ms_per_exec,
       s.delta_concurrency_time/GREATEST(s.delta_execution_count,1)/1e3 AS conc_ms_per_exec,
       s.delta_plsql_exec_time/GREATEST(s.delta_execution_count,1)/1e3 AS plsql_ms_per_exec,
       s.delta_cluster_wait_time/GREATEST(s.delta_execution_count,1)/1e3 AS cluster_ms_per_exec,
       s.delta_java_exec_time/GREATEST(s.delta_execution_count,1)/1e3 AS java_ms_per_exec,
       s.delta_elapsed_time/GREATEST(w.age_seconds,1)/1e6 AS et_aas,
       s.delta_cpu_time/GREATEST(w.age_seconds,1)/1e6 AS cpu_aas,
       s.delta_user_io_wait_time/GREATEST(w.age_seconds,1)/1e6 AS io_aas,
       s.delta_application_wait_time/GREATEST(w.age_seconds,1)/1e6 AS appl_aas,
       s.delta_concurrency_time/GREATEST(w.age_seconds,1)/1e6 AS conc_aas,
       s.delta_plsql_exec_time/GREATEST(w.age_seconds,1)/1e6 AS plsql_aas,
       s.delta_cluster_wait_time/GREATEST(w.age_seconds,1)/1e6 AS cluster_aas,
       s.delta_java_exec_time/GREATEST(w.age_seconds,1)/1e6 AS java_aas,
       s.delta_execution_count AS delta_execution_count,
       s.delta_execution_count/GREATEST(w.age_seconds,1) AS execs_per_sec,
       s.delta_px_servers_executions/GREATEST(w.age_seconds,1) AS px_execs_per_sec,
       s.delta_end_of_fetch_count/GREATEST(w.age_seconds,1) AS end_of_fetch_per_sec,
       s.delta_parse_calls/GREATEST(w.age_seconds,1) AS parses_per_sec,
       s.delta_invalidations/GREATEST(w.age_seconds,1) AS inval_per_sec,
       s.delta_loads/GREATEST(w.age_seconds,1) AS loads_per_sec,
       s.delta_buffer_gets/GREATEST(s.delta_execution_count,1) AS gets_per_exec,
       s.delta_disk_reads/GREATEST(s.delta_execution_count,1) AS reads_per_exec,
       s.delta_direct_reads/GREATEST(s.delta_execution_count,1) AS direct_reads_per_exec,
       s.delta_direct_writes/GREATEST(s.delta_execution_count,1) AS direct_writes_per_exec,
       s.delta_physical_read_requests/GREATEST(s.delta_execution_count,1) AS phy_read_req_per_exec,
       s.delta_physical_read_bytes/GREATEST(s.delta_execution_count,1)/1e6 AS phy_read_mb_per_exec,
       s.delta_physical_write_requests/GREATEST(s.delta_execution_count,1) AS phy_write_req_per_exec,
       s.delta_physical_write_bytes/GREATEST(s.delta_execution_count,1)/1e6 AS phy_write_mb_per_exec,
       s.delta_fetch_count/GREATEST(s.delta_execution_count,1) AS fetches_per_exec,
       s.delta_sorts/GREATEST(s.delta_execution_count,1) AS sorts_per_exec,
       s.delta_rows_processed,
       s.delta_rows_processed/GREATEST(s.delta_execution_count,1) AS rows_per_exec,
       s.delta_elapsed_time/GREATEST(s.delta_rows_processed,s.delta_execution_count,1)/1e3 AS et_ms_per_row,
       s.delta_cpu_time/GREATEST(s.delta_rows_processed,s.delta_execution_count,1)/1e3 AS cpu_ms_per_row,
       s.delta_user_io_wait_time/GREATEST(s.delta_rows_processed,s.delta_execution_count,1)/1e3 AS io_ms_per_row,
       s.delta_buffer_gets/GREATEST(s.delta_rows_processed,s.delta_execution_count,1) AS gets_per_row,
       s.delta_disk_reads/GREATEST(s.delta_rows_processed,s.delta_execution_count,1) AS reads_per_row,
       s.avg_hard_parse_time,
       s.sql_id,
       s.sql_text,
       s.sql_fulltext,
       s.plan_hash_value,
       s.last_active_child_address
  FROM v$sqlstats s, 
       (SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */ 
               ((86400 * EXTRACT(DAY FROM (SYSTIMESTAMP - MAX(end_interval_time))) + (3600 * EXTRACT(HOUR FROM (systimestamp - MAX(end_interval_time)))) + (60 * EXTRACT(MINUTE FROM (systimestamp - MAX(end_interval_time)))) + EXTRACT(SECOND FROM (systimestamp - MAX(end_interval_time))))) AS age_seconds 
          FROM dba_hist_snapshot 
         WHERE end_interval_time < SYSTIMESTAMP) w
 WHERE s.last_active_time > SYSDATE - (1/24/60) -- select only sql that has been active during the last 1 minute
   AND s.delta_elapsed_time > 0 -- select only sql that has reported time since las awr
   AND s.delta_elapsed_time/GREATEST(w.age_seconds,1)/1e6 /*et_aas*/ >= LEAST(&&cs_aas_threshold_latency., &&cs_aas_threshold_load.) -- select only sql that generates some db load
   AND s.delta_elapsed_time/GREATEST(s.delta_execution_count,1)/1e3 /*et_ms_per_exec*/ >= &&cs_ms_threshold_latency.
   AND ROWNUM >= 1 -- materialize
),
sqlstats_extended AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS MONITOR */
       s.sql_type,
       s.et_ms_per_exec,
       s.cpu_ms_per_exec,
       s.io_ms_per_exec,
       s.appl_ms_per_exec,
       s.conc_ms_per_exec,
       s.plsql_ms_per_exec,
       s.cluster_ms_per_exec,
       s.java_ms_per_exec,
       s.et_aas,
       s.cpu_aas,
       s.io_aas,
       s.appl_aas,
       s.conc_aas,
       s.plsql_aas,
       s.cluster_aas,
       s.java_aas,
       s.delta_execution_count,
       s.execs_per_sec,
       s.px_execs_per_sec,
       s.end_of_fetch_per_sec,
       s.parses_per_sec,
       s.avg_hard_parse_time,
       s.inval_per_sec,
       s.loads_per_sec,
       s.gets_per_exec,
       s.reads_per_exec,
      --  s.direct_reads_per_exec,
       s.direct_writes_per_exec,
       s.phy_read_req_per_exec,
       s.phy_read_mb_per_exec,
       s.phy_write_req_per_exec,
       s.phy_write_mb_per_exec,
       s.fetches_per_exec,
       s.sorts_per_exec,
       s.delta_rows_processed,
       s.rows_per_exec,
       s.et_ms_per_row,
       s.cpu_ms_per_row,
       s.io_ms_per_row,
       s.gets_per_row,
       s.reads_per_row,
       s.sql_id,
       s.sql_text,
       s.sql_fulltext,
       s.plan_hash_value,
       s.last_active_child_address,
       s.con_id,
       c.name AS pdb_name,
       ROW_NUMBER() OVER (PARTITION BY s.sql_type ORDER BY s.et_ms_per_exec DESC) AS latency_rn, -- top sql as per db latency
       ROW_NUMBER() OVER (PARTITION BY s.sql_type ORDER BY s.et_aas DESC) AS load_rn -- top sql as per db load
  FROM sqlstats s,
       v$containers c
 WHERE c.con_id = s.con_id
   AND ROWNUM >= 1
)
SELECT CASE WHEN v.parsing_schema_name = 'SYS' THEN 'SYS' ELSE s.sql_type END AS sql_type,
       s.latency_rn,
       s.load_rn,
       s.et_ms_per_exec,
       s.cpu_ms_per_exec,
       s.io_ms_per_exec,
       s.appl_ms_per_exec,
       s.conc_ms_per_exec,
       s.plsql_ms_per_exec,
       s.cluster_ms_per_exec,
       s.java_ms_per_exec,
       '|' AS sep1,
       s.et_aas,
       s.cpu_aas,
       s.io_aas,
       s.appl_aas,
       s.conc_aas,
       s.plsql_aas,
       s.cluster_aas,
       s.java_aas,
       '|' AS sep2,
       s.delta_execution_count,
       s.execs_per_sec,
       s.px_execs_per_sec,
       s.end_of_fetch_per_sec,
       s.parses_per_sec,
       s.avg_hard_parse_time,
       s.inval_per_sec,
       s.loads_per_sec,
       '|' AS sep3,
       s.gets_per_exec,
       s.reads_per_exec,
      --  s.direct_reads_per_exec,
       s.direct_writes_per_exec,
       s.phy_read_req_per_exec,
       s.phy_read_mb_per_exec,
       s.phy_write_req_per_exec,
       s.phy_write_mb_per_exec,
       s.fetches_per_exec,
       s.sorts_per_exec,
       '|' AS sep4,
       s.delta_rows_processed,
       s.rows_per_exec,
       '|' AS sep5,
       s.et_ms_per_row,
       s.cpu_ms_per_row,
       s.io_ms_per_row,
       s.gets_per_row,
       s.reads_per_row,
       '|' AS sep6,
      --  LPAD(MOD(DBMS_SQLTUNE.sqltext_to_signature(CASE WHEN s.sql_fulltext LIKE '/* %(%,%)% [____] */%' THEN REGEXP_REPLACE(s.sql_fulltext, '\[([[:digit:]]{4})\] ') ELSE s.sql_fulltext END),100000),5,'0') AS sqlid,
       get_sql_hv(s.sql_fulltext) AS sqlid,
       s.sql_id,
       s.plan_hash_value,
       v.has_baseline,
       v.has_profile,
       v.has_patch,
       s.sql_text,
       CASE '&&cs_con_name.' WHEN 'CDB$ROOT' THEN s.pdb_name ELSE v.parsing_schema_name END AS pdb_or_parsing_schema_name
  FROM sqlstats_extended s
  OUTER APPLY (
         SELECT CASE WHEN v.sql_plan_baseline IS NULL THEN 'N' ELSE 'Y' END AS has_baseline, 
                CASE WHEN v.sql_profile IS NULL THEN 'N' ELSE 'Y' END AS has_profile, 
                CASE WHEN v.sql_patch IS NULL THEN 'N' ELSE 'Y' END AS has_patch,
                v.parsing_schema_name
           FROM v$sql v
          WHERE v.sql_id = s.sql_id
            AND v.con_id = s.con_id
            AND v.plan_hash_value = s.plan_hash_value
            AND v.child_address = s.last_active_child_address
          ORDER BY 
                v.last_active_time DESC
          FETCH FIRST 1 ROW ONLY
       ) v
 WHERE 1 = 1
   AND ((s.latency_rn <= &&cs_top_latency. AND s.et_aas >= &&cs_aas_threshold_latency.) OR (s.load_rn <= &&cs_top_load. AND s.et_aas >= &&cs_aas_threshold_load.))
   AND s.et_ms_per_exec >= &&cs_ms_threshold_latency.
 ORDER BY
       CASE WHEN v.parsing_schema_name = 'SYS' THEN 6 WHEN s.sql_type = 'TP' THEN 1 WHEN s.sql_type = 'RO' THEN 2 WHEN s.sql_type = 'BG' THEN 3 WHEN s.sql_type = 'UN' THEN 4 WHEN s.sql_type = 'IG' THEN 5 ELSE 9 END,
       --  s.latency_rn
       s.et_ms_per_exec DESC
/
