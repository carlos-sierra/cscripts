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
  -- --
  -- ELSIF p_command_name IN ('INSERT', 'UPDATE')
  -- THEN RETURN 'TP'; /* Transaction Processing */
  -- --
  -- ELSIF p_command_name = 'DELETE'
  -- THEN RETURN 'BG'; /* Background */
  -- --
  -- ELSIF p_command_name = 'SELECT'
  -- THEN RETURN 'RO'; /* Read Only */
  -- --
  ELSE RETURN 'UN'; /* Unknown */
  END IF;
END application_category;
-- bl AS (SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */ con_id, signature, COUNT(*) AS bl FROM cdb_sql_plan_baselines WHERE enabled = 'YES' AND accepted = 'YES' AND ROWNUM >= 1 GROUP BY con_id, signature),
-- pr AS (SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */ con_id, signature, COUNT(*) AS pr FROM cdb_sql_profiles WHERE status = 'ENABLED' AND ROWNUM >= 1 GROUP BY con_id, signature),
-- pa AS (SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */ con_id, signature, COUNT(*) AS pa FROM cdb_sql_patches WHERE status = 'ENABLED' AND ROWNUM >= 1 GROUP BY con_id, signature),
cs_begin_end AS (
    SELECT /*+ MATERIALIZE NO_MERGE */ NULLIF((SYSDATE - CAST(MAX(end_interval_time) AS DATE)) * 24 * 3600, 0) AS seconds
    FROM dba_hist_snapshot
    WHERE dbid = TO_NUMBER('&&cs_dbid.')
    AND instance_number = TO_NUMBER('&&cs_instance_number.')
),
sqlstat1 AS (
      SELECT /*+ MATERIALIZE NO_MERGE */
            h.force_matching_signature,
            h.sql_id,
            h.plan_hash_value,
            h.last_active_child_address,
            h.con_id,
            h.total_sharable_mem AS sharable_mem,
            h.version_count AS version_count,
            h.delta_fetch_count AS fetches_delta,
            h.delta_execution_count AS executions_delta,
            h.delta_parse_calls AS parse_calls_delta,
            h.delta_disk_reads AS disk_reads_delta,
            h.delta_buffer_gets AS buffer_gets_delta,
            h.delta_rows_processed AS rows_processed_delta,
            h.delta_cpu_time AS cpu_time_delta,
            h.delta_elapsed_time AS elapsed_time_delta,
            h.delta_user_io_wait_time AS iowait_delta,
            h.delta_cluster_wait_time AS clwait_delta,
            h.delta_application_wait_time AS apwait_delta,
            h.delta_concurrency_time AS ccwait_delta,
            h.delta_plsql_exec_time AS plsexec_time_delta,
            h.delta_java_exec_time AS javexec_time_delta,
            h.sql_text
      FROM  v$sqlstats h
      WHERE ('&&sql_id.' IS NULL OR h.sql_id = '&&sql_id.')
      AND   ('&&sql_text_piece.' IS NULL OR UPPER(h.sql_text) LIKE UPPER('%&&sql_text_piece.%'))
),
sqlstat2 AS (
      SELECT /*+ MATERIALIZE NO_MERGE */
            h.force_matching_signature AS signature,
            h.sql_id,
            h.plan_hash_value,
            h.last_active_child_address,
            h.con_id,
            h.sharable_mem,
            h.version_count,
            h.fetches_delta AS fetches,
            h.executions_delta AS executions,
            h.parse_calls_delta AS parse_calls,
            h.disk_reads_delta AS disk_reads,
            h.buffer_gets_delta AS buffer_gets,
            h.rows_processed_delta AS rows_processed,
            h.fetches_delta / cs_begin_end.seconds AS fetches_ps,
            h.executions_delta / cs_begin_end.seconds AS executions_ps,
            h.parse_calls_delta / cs_begin_end.seconds AS parse_calls_ps,
            h.cpu_time_delta / POWER(10, 6) AS cpu_secs,
            h.elapsed_time_delta / POWER(10, 6) AS db_secs,
            h.iowait_delta / POWER(10, 6) AS io_secs,
            h.clwait_delta / POWER(10, 6) AS cl_secs,
            h.apwait_delta / POWER(10, 6) AS ap_secs,
            h.ccwait_delta / POWER(10, 6) AS cc_secs,
            h.plsexec_time_delta / POWER(10, 6) AS pl_secs,
            h.javexec_time_delta / POWER(10, 6) AS ja_secs,
            h.rows_processed_delta / GREATEST(h.executions_delta, 1) AS rows_processed_pe,
            h.buffer_gets_delta / GREATEST(h.executions_delta, 1) AS buffer_gets_pe,
            h.disk_reads_delta / GREATEST(h.executions_delta, 1) AS disk_reads_pe,
            h.elapsed_time_delta / GREATEST(h.executions_delta, 1) / POWER(10, 3) AS db_ms_pe,
            h.cpu_time_delta / GREATEST(h.executions_delta, 1) / POWER(10, 3) AS cpu_ms_pe,
            h.iowait_delta / GREATEST(h.executions_delta, 1) / POWER(10, 3) AS io_ms_pe,
            h.apwait_delta / GREATEST(h.executions_delta, 1) / POWER(10, 3) AS ap_ms_pe,
            h.ccwait_delta / GREATEST(h.executions_delta, 1) / POWER(10, 3) AS cc_ms_pe,
            h.clwait_delta / GREATEST(h.executions_delta, 1) / POWER(10, 3) AS cl_ms_pe,
            h.plsexec_time_delta / GREATEST(h.executions_delta, 1) / POWER(10, 3) AS pl_ms_pe,
            h.javexec_time_delta / GREATEST(h.executions_delta, 1) / POWER(10, 3) AS ja_ms_pe,
            h.elapsed_time_delta / GREATEST(h.rows_processed_delta, 1) / POWER(10, 3) AS db_ms_prp,
            h.cpu_time_delta / GREATEST(h.rows_processed_delta, 1) / POWER(10, 3) AS cpu_ms_prp,
            h.buffer_gets_delta / GREATEST(h.rows_processed_delta, 1) AS buffer_gets_prp,
            h.disk_reads_delta / GREATEST(h.rows_processed_delta, 1) AS disk_reads_prp,
            h.elapsed_time_delta / POWER(10, 6) / cs_begin_end.seconds AS db_aas,
            h.cpu_time_delta / POWER(10, 6) / cs_begin_end.seconds AS cpu_aas,
            h.iowait_delta / POWER(10, 6) / cs_begin_end.seconds AS io_aas,
            h.apwait_delta / POWER(10, 6) / cs_begin_end.seconds AS ap_aas,
            h.ccwait_delta / POWER(10, 6) / cs_begin_end.seconds AS cc_aas,
            h.clwait_delta / POWER(10, 6) / cs_begin_end.seconds AS cl_aas,
            h.plsexec_time_delta / POWER(10, 6) / cs_begin_end.seconds AS pl_aas,
            h.javexec_time_delta / POWER(10, 6) / cs_begin_end.seconds AS ja_aas,
            h.sql_text,
            application_category(h.sql_text, 'UN') AS sql_type,
            c.name AS pdb_name
      FROM  sqlstat1 h,
            v$containers c,
            cs_begin_end
      --  CROSS APPLY (
      --    SELECT a.name AS command_name
      --      FROM v$sql v, audit_actions a
      --     WHERE v.sql_id = h.sql_id
      --       AND v.con_id = h.con_id
      --       AND v.plan_hash_value = h.plan_hash_value
      --       AND a.action = v.command_type
      --     ORDER BY v.last_active_time DESC
      --     FETCH FIRST 1 ROW ONLY
      --  ) v
     WHERE  c.con_id = h.con_id
       AND  cs_begin_end.seconds > 0
),
sqlstat3 AS (
      SELECT /*+ MATERIALIZE NO_MERGE */
            s.sql_id,
            s.plan_hash_value,
            v.has_baseline,
            v.has_profile,
            v.has_patch,
            --
            s.db_secs,
            s.cpu_secs,
            s.io_secs,
            s.cl_secs,
            s.ap_secs,
            s.cc_secs,
            s.pl_secs,
            s.ja_secs,
            s.db_ms_pe,
            s.cpu_ms_pe,
            s.io_ms_pe,
            s.ap_ms_pe,
            s.cc_ms_pe,
            s.cl_ms_pe,
            s.pl_ms_pe,
            s.ja_ms_pe,
            s.db_aas,
            s.cpu_aas,
            s.io_aas,
            s.ap_aas,
            s.cc_aas,
            s.cl_aas,
            s.pl_aas,
            s.ja_aas,
            s.parse_calls,
            s.executions,
            s.fetches,
            s.parse_calls_ps,
            s.executions_ps,
            s.fetches_ps,
            s.db_ms_prp,
            s.cpu_ms_prp,
            s.rows_processed,
            s.buffer_gets,
            s.rows_processed_pe,
            s.buffer_gets_pe,
            s.buffer_gets_prp,
            s.disk_reads,
            s.disk_reads_pe,
            s.disk_reads_prp,
            s.sharable_mem,
            s.version_count,
            --
            s.sql_type,
            s.sql_text,
            s.pdb_name
      FROM sqlstat2 s
      CROSS APPLY (
            SELECT  CASE WHEN v.sql_plan_baseline IS NULL THEN 'N' ELSE 'Y' END AS has_baseline, 
                    CASE WHEN v.sql_profile IS NULL THEN 'N' ELSE 'Y' END AS has_profile, 
                    CASE WHEN v.sql_patch IS NULL THEN 'N' ELSE 'Y' END AS has_patch 
              FROM  v$sql v
              WHERE s.plan_hash_value > 0
                AND v.sql_id = s.sql_id
                AND v.con_id = s.con_id
                AND v.plan_hash_value = s.plan_hash_value
                AND v.child_address = s.last_active_child_address
              ORDER BY 
                    v.last_active_time DESC
              FETCH FIRST 1 ROW ONLY
          ) v
    --  WHERE  (     '&&kiev_tx.' = '*' 
    --           OR  '&&kiev_tx.' LIKE '%'||s.sql_type||'%' -- does not seem to work on 19c
    --         ) 
      WHERE CASE WHEN '&&kiev_tx.' = '*' THEN 1 WHEN '&&kiev_tx.' LIKE '%'||s.sql_type||'%' THEN 1 ELSE 0 END = 1
ORDER BY &&cs_order_by.
FETCH FIRST &&top_n. ROWS ONLY
)