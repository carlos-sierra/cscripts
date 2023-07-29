----------------------------------------------------------------------------------------
--
-- File name:   cs_sql_perf_high_aas.sql
--
-- Purpose:     SQL with AAS per hour for a given Timed Event higher than N (time series text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/11/30
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sql_perf_high_aas.sql
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
DEF cs_script_name = 'cs_sql_perf_high_aas';
DEF cs_hours_range_default = '168';
DEF cs_include_sys = 'N';
DEF cs_include_iod = 'N';
--DEF cs_time_group_by = 'DD';
--DEF cs_time_format = 'YYYY-MM-DD';
--DEF cs_secs_on_group = '86400';
DEF cs_time_group_by = 'HH24';
DEF cs_time_format = 'YYYY-MM-DD"T"HH24';
DEF cs_secs_on_group = '3600';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--@@cs_internal/&&cs_set_container_to_cdb_root.
--
PRO
PRO 3. Average Active Sessions Timed Event: 
PRO [{total}|on_cpu,user_io,system_io,cluster,commit,concurrency,application,administrative,configuration,network,queueing,scheduler,other]
DEF wait_class = '&3.';
UNDEF 3;
COL wait_class NEW_V wait_class NOPRI;
SELECT LOWER(NVL(TRIM('&&wait_class.'), 'total')) wait_class FROM DUAL
/
PRO
PRO 4. More than Average Active Sessions (AAS) per &&cs_time_group_by.: [{1}|1-36]
DEF more_than_aas = '&4.';
UNDEF 4;
COL more_than_aas NEW_V more_than_aas NOPRI;
SELECT NVL(TRIM('&&more_than_aas.'), '1') more_than_aas FROM DUAL
/
PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO *=All, TP=Transaction Processing, RO=Read Only, BG=Background, IG=Ignore, UN=Unknown
PRO
PRO 5. SQL Type: [{*}|TP|RO|BG|IG|UN|TP,RO|TP,RO,BG] 
DEF kiev_tx = '&5.';
UNDEF 5;
COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT UPPER(NVL(TRIM('&&kiev_tx.'), '*')) kiev_tx FROM DUAL
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Enter additional SQL Text filtering, such as Table name or SQL Text piece
PRO
PRO 6. SQL Text piece (e.g.: ScanQuery, getValues, TableName, IndexName):
DEF sql_text_piece = '&6.';
UNDEF 6;
--
PRO
PRO Filtering SQL to reduce search space.
PRO By entering an optional SQL_ID, scope is further reduced
PRO
PRO 7. SQL_ID (optional):
DEF cs_sql_id = '&7.';
UNDEF 7;
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "wait_class" "&&more_than_aas." "&&kiev_tx." "&&sql_text_piece." "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO WAIT_CLASS   : "&&wait_class." [{on_cpu}|total,user_io,system_io,cluster,commit,concurrency,application,administrative,configuration,network,queueing,scheduler,other]
PRO MORE_THAN_AAS: "&&more_than_aas." [{1}|1-36]
PRO SQL_TYPE     : "&&kiev_tx." [{*}|TP|RO|BG|IG|UN|TP,RO|TP,RO,BG]
PRO SQL_TEXT     : "&&sql_text_piece."
PRO SQL_ID       : "&&cs_sql_id."
--
COL total FOR 9,990.0 HEA 'Total';
COL on_cpu FOR 9,990.0 HEA 'ON CPU';
COL usr_io FOR 9,990.0 HEA 'Usr IO';
COL sys_io FOR 9,990.0 HEA 'Sys IO';
COL clustr FOR 9,990.0 HEA 'Clustr';
COL comit FOR 9,990.0 HEA 'Commit';
COL concur FOR 9,990.0 HEA 'Concur';
COL appl FOR 9,990.0 HEA 'Appl';
COL admin FOR 9,990.0 HEA 'Admin';
COL config FOR 9,990.0 HEA 'Config';
COL netwrk FOR 9,990.0 HEA 'Netwrk';
COL queue FOR 9,990.0 HEA 'Queue';
COL sched FOR 9,990.0 HEA 'Sched';
COL other FOR 9,990.0 HEA 'Other';
--
COL time FOR A13 HEA 'Time';
COL sql_type FOR A4 HEA 'Type';
COL sql_decoration_or_text FOR A100 HEA 'SQL Decoration or Text' TRUNC;
COL username FOR A30 HEA 'Username' TRUNC;
COL pdb_name FOR A30 HEA 'PDB Name' TRUNC;
--
BREAK ON pdb_name SKIP PAGE DUP;
--
PRO
PRO SQL with high Average Active Sessions (more than "&&more_than_aas." AAS per per &&cs_time_group_by. on Timed Event "&&wait_class.")
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
--
FUNCTION get_kiev_token (
  p_sqltext    IN VARCHAR2,
  p_token_type IN VARCHAR2 DEFAULT 'o' -- [{o}|t|i] operation(o), table(t) or index(i)
)
RETURN VARCHAR2 DETERMINISTIC
IS
  l_sqltext CLOB := REGEXP_REPLACE(p_sqltext, '/\* REPO_[A-Z0-9]{1,25} \*/ '); -- removes "/* REPO_IFCDEXZQGAYDAMBQHAYQ */ " DBPERF-8819
  l_operation VARCHAR2(1000);
  l_table VARCHAR2(1000);
  l_index VARCHAR2(1000);
  l_sql_type VARCHAR2(2) := application_category(l_sqltext, 'UNKNOWN');
BEGIN
  IF l_sql_type IN ('SYS', 'IG', 'UN') THEN
    RETURN 'UN';
  END IF;
  --
  IF l_sqltext LIKE '%/* % */%' THEN
    l_operation := NVL(TRIM(SUBSTR(l_sqltext, 3, LEAST(INSTR(l_sqltext||'(', '('), INSTR(l_sqltext||'*/', '*/')) - 3)), 'null');
    IF l_sqltext LIKE '%/* %(%) %*/%' THEN
      l_table := NVL(SUBSTR(l_sqltext, INSTR(l_sqltext, '(') + 1, LEAST(INSTR(l_sqltext||',', ','), INSTR(l_sqltext||')', ')')) - INSTR(l_sqltext, '(') - 1), 'null');
      IF l_sqltext LIKE '%/* %(%,%) %*/%' THEN
        l_index := NVL(SUBSTR(l_sqltext, INSTR(l_sqltext, ',') + 1, LEAST(INSTR(l_sqltext||')', ')', INSTR(l_sqltext, ',')), INSTR(l_sqltext||'(', '(', INSTR(l_sqltext, ','))) - INSTR(l_sqltext, ',') - 1), 'null');
        IF l_index = 'HashRangeIndex' THEN l_index := l_table||'_PK'; END IF;
      ELSE
        l_index := 'null';
      END IF;
    ELSE
      l_table := 'null';
      l_index := 'null';
    END IF;
  ELSE
    l_operation := 'null';
    l_table := 'null';
    l_index := 'null';
  END IF;
  --
  IF p_token_type = 'o' THEN RETURN l_operation; END IF;
  IF p_token_type = 't' THEN RETURN l_table; END IF;
  IF p_token_type = 'i' THEN RETURN l_index; END IF;
  RETURN 'null';
END get_kiev_token;
--
FUNCTION sql_decoration (p_sql_text IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
  RETURN get_kiev_token(p_sql_text, 'o');
  -- IF p_sql_text LIKE '/*'||CHR(37) AND application_category(p_sql_text) <> 'UN' THEN
  --   RETURN SUBSTR(p_sql_text, 1, INSTR(p_sql_text, '*/') + 1);
  -- ELSE
  --   RETURN NULL;
  -- END IF;
END sql_decoration;
/****************************************************************************************/
ash_raw AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.con_id,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id,
       h.session_state,
       h.wait_class
  FROM dba_hist_active_sess_history h
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND ('&&cs_sql_id.' IS NULL OR h.sql_id = '&&cs_sql_id.')
),
ash_per_hour AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       TRUNC(CAST(h.sample_time AS DATE), '&&cs_time_group_by.') sample_hour,
       h.con_id,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id,
       COUNT(*) * 10 / &&cs_secs_on_group. aas_total,
       SUM(CASE h.session_state WHEN 'ON CPU'         THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_on_cpu,
       SUM(CASE h.wait_class    WHEN 'User I/O'       THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_user_io,
       SUM(CASE h.wait_class    WHEN 'System I/O'     THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_system_io,
       SUM(CASE h.wait_class    WHEN 'Cluster'        THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_cluster,
       SUM(CASE h.wait_class    WHEN 'Commit'         THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_commit,
       SUM(CASE h.wait_class    WHEN 'Concurrency'    THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_concurrency,
       SUM(CASE h.wait_class    WHEN 'Application'    THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_application,
       SUM(CASE h.wait_class    WHEN 'Administrative' THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_administrative,
       SUM(CASE h.wait_class    WHEN 'Configuration'  THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_configuration,
       SUM(CASE h.wait_class    WHEN 'Network'        THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_network,
       SUM(CASE h.wait_class    WHEN 'Queueing'       THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_queueing,
       SUM(CASE h.wait_class    WHEN 'Scheduler'      THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_scheduler,
       SUM(CASE h.wait_class    WHEN 'Other'          THEN 10 / &&cs_secs_on_group. ELSE 0 END) aas_other
  FROM ash_raw h
 GROUP BY
       TRUNC(CAST(h.sample_time AS DATE), '&&cs_time_group_by.'),
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
       sql_decoration(s.sql_text) sql_decoration,
       s.sql_text
  FROM v$sql s
 WHERE sql_id IS NOT NULL
   AND ('&&cs_sql_id.' IS NULL OR s.sql_id = '&&cs_sql_id.')
   AND ('&&sql_text_piece.' IS NULL OR UPPER(s.sql_text) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
  --  AND ('&&kiev_tx.' = '*' OR '&&kiev_tx.' LIKE CHR(37)||application_category(s.sql_text)||CHR(37))-- does not seem to work on 19c
   AND CASE WHEN '&&kiev_tx.' = '*' THEN 1 WHEN '&&kiev_tx.' LIKE CHR(37)||application_category(s.sql_text)||CHR(37) THEN 1 ELSE 0 END = 1 
 GROUP BY
       s.con_id,
       s.sql_id,
       application_category(s.sql_text),
       sql_decoration(s.sql_text),
       s.sql_text
),
hsql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.con_id,
       h.sql_id,
       application_category(DBMS_LOB.substr(h.sql_text, 1000)) sql_type,
       sql_decoration(DBMS_LOB.substr(h.sql_text, 1000)) sql_decoration,
       DBMS_LOB.substr(h.sql_text, 1000) sql_text
  FROM dba_hist_sqltext h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND ('&&cs_sql_id.' IS NULL OR h.sql_id = '&&cs_sql_id.')
   AND ('&&sql_text_piece.' IS NULL OR UPPER(DBMS_LOB.substr(h.sql_text, 1000)) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
  --  AND ('&&kiev_tx.' = '*' OR '&&kiev_tx.' LIKE CHR(37)||application_category(DBMS_LOB.substr(h.sql_text, 1000))||CHR(37)) -- does not seem to work on 19c
   AND CASE WHEN '&&kiev_tx.' = '*' THEN 1 WHEN '&&kiev_tx.' LIKE CHR(37)||application_category(DBMS_LOB.SUBSTR(h.sql_text, 1000))||CHR(37) THEN 1 ELSE 0 END = 1
),
ash_per_hour_extended AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_hour,
       h.con_id,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id,
       h.aas_total,
       h.aas_on_cpu,
       h.aas_user_io,
       h.aas_system_io,
       h.aas_cluster,
       h.aas_commit,
       h.aas_concurrency,
       h.aas_application,
       h.aas_administrative,
       h.aas_configuration,
       h.aas_network,
       h.aas_queueing,
       h.aas_scheduler,
       h.aas_other,
       COALESCE(s.sql_type, hs.sql_type) sql_type,
       COALESCE(s.sql_decoration, hs.sql_decoration) sql_decoration,
       COALESCE(s.sql_text, hs.sql_text) sql_text,
       u.username,
       c.name pdb_name
  FROM ash_per_hour h,
       vsql s,
       hsql hs,
       v$containers c,
       cdb_users u
 WHERE s.con_id(+) = h.con_id
   AND s.sql_id(+) = h.sql_id
   AND hs.con_id(+) = h.con_id
   AND hs.sql_id(+) = h.sql_id
   AND COALESCE(s.sql_type, hs.sql_type) IS NOT NULL
   AND c.con_id = h.con_id
   AND c.open_mode = 'READ WRITE'
   AND u.con_id = h.con_id
   AND u.user_id = h.user_id
   AND ('&&cs_include_sys.' = 'Y' OR ('&&cs_include_sys.' = 'N' AND u.username <> 'SYS'))
   AND ('&&cs_include_iod.' = 'Y' OR ('&&cs_include_iod.' = 'N' AND u.username <> '&&cs_tools_schema.'))
)
SELECT sql_type,
       COALESCE(sql_decoration, sql_id||' '||sql_plan_hash_value||' '||sql_text) sql_decoration_or_text,
       TO_CHAR(sample_hour, '&&cs_time_format.') time,
       SUM(aas_total) total,
       SUM(aas_on_cpu) on_cpu,
       SUM(aas_user_io) usr_io,
       SUM(aas_system_io) sys_io,
       SUM(aas_cluster) clustr,
       SUM(aas_commit) comit,
       SUM(aas_concurrency) concur,
       SUM(aas_application) appl,
       SUM(aas_administrative) admin,
       SUM(aas_configuration) config,
       SUM(aas_network) netwrk,
       SUM(aas_queueing) queue,
       SUM(aas_scheduler) sched,
       SUM(aas_other) other,
       pdb_name
  FROM ash_per_hour_extended
 GROUP BY
       sample_hour,
       sql_type,
       COALESCE(sql_decoration, sql_id||' '||sql_plan_hash_value||' '||sql_text),
       pdb_name
HAVING SUM(aas_&&wait_class.) > TO_NUMBER('&&more_than_aas.')
 ORDER BY 
       sql_type,
       COALESCE(sql_decoration, sql_id||' '||sql_plan_hash_value||' '||sql_text),
       sample_hour,
       pdb_name,
       SUM(aas_total) DESC
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "wait_class" "&&more_than_aas." "&&kiev_tx." "&&sql_text_piece." "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
--
--@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--