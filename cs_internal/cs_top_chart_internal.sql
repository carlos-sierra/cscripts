DEF computed_metric = '&1.';
UNDEF 1;
--
COL file_name NEW_V file_name NOPRI;
SELECT CASE LOWER(TRIM('&&computed_metric.'))
       WHEN 'db_time_exec'               THEN '1_Latency_1_Elapsed_Time_per_Execution'
       WHEN 'db_time_aas'                THEN '2_DB_Time_1_Elapsed_Time_AAS'
       WHEN 'cpu_time_exec'              THEN '1_Latency_2_CPU_Time_per_Execution'
       WHEN 'cpu_time_aas'               THEN '2_DB_Time_2_CPU_Time_AAS'
       WHEN 'io_time_exec'               THEN '1_Latency_3_IO_Wait_Time_per_Execution'
       WHEN 'io_time_aas'                THEN '2_DB_Time_3_IO_Wait_Time_AAS'
       WHEN 'appl_time_exec'             THEN '1_Latency_4_Application_Wait_Time_per_Execution'
       WHEN 'appl_time_aas'              THEN '2_DB_Time_4_Application_Wait_Time_AAS'
       WHEN 'conc_time_exec'             THEN '1_Latency_5_Concurrency_Wait_Time_per_Execution'
       WHEN 'conc_time_aas'              THEN '2_DB_Time_5_Concurrency_Wait_Time_AAS'
       WHEN 'parses_sec'                 THEN '3_DB_Calls_3_Parses_per_Second'
       WHEN 'executions_sec'             THEN '3_DB_Calls_1_Executions_per_Second'
       WHEN 'fetches_sec'                THEN '3_DB_Calls_2_Fetches_per_Second'
       WHEN 'loads'                      THEN '6_Cursors_4_Loads'
       WHEN 'invalidations'              THEN '6_Cursors_3_Invalidations'
       WHEN 'version_count'              THEN '6_Cursors_2_Versions'
       WHEN 'sharable_mem_mb'            THEN '6_Cursors_1_Sharable Memory'
       WHEN 'rows_processed_sec'         THEN '5_Resources_per_Second_1_Rows_Processed'
       WHEN 'rows_processed_exec'        THEN '4_Resources_per_Exec_1_Rows_Processed'
       WHEN 'buffer_gets_sec'            THEN '5_Resources_per_Second_2_Buffer_Gets'
       WHEN 'buffer_gets_exec'           THEN '4_Resources_per_Exec_2_Buffer_Gets'
       WHEN 'disk_reads_sec'             THEN '5_Resources_per_Second_3_Disk_Reads'
       WHEN 'disk_reads_exec'            THEN '4_Resources_per_Exec_3_Disk_Reads'
       WHEN 'physical_read_bytes_sec'    THEN '5_Resources_per_Second_4_Physical_Read_Bytes'
       WHEN 'physical_read_bytes_exec'   THEN '4_Resources_per_Exec_4_Physical_Read_Bytes'
       WHEN 'physical_write_bytes_sec'   THEN '5_Resources_per_Second_5_Physical_Write_Bytes'
       WHEN 'physical_write_bytes_exec'  THEN '4_Resources_per_Exec_5_Physical_Write_Bytes'
       ELSE '1_Latency_1_Elapsed_Time_per_Execution'
       END file_name
  FROM DUAL
/
SELECT (CASE WHEN '&&sql_id' IS NOT NULL THEN '&&sql_id._' END)||'&&file_name.' file_name FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&file_name.' cs_file_name FROM DUAL;
--
COL metric_display NEW_V metric_display NOPRI;
SELECT CASE LOWER(TRIM('&&computed_metric.'))
       WHEN 'db_time_exec'               THEN 'Latency "Elapsed Time per Execution"'
       WHEN 'db_time_aas'                THEN 'DB Time "Elapsed Time AAS"'
       WHEN 'cpu_time_exec'              THEN 'Latency "CPU Time per Execution"'
       WHEN 'cpu_time_aas'               THEN 'DB Time "CPU Time AAS"'
       WHEN 'io_time_exec'               THEN 'Latency "IO Wait Time per Execution"'
       WHEN 'io_time_aas'                THEN 'DB Time "IO Wait Time AAS"'
       WHEN 'appl_time_exec'             THEN 'Latency "Application Wait Time per Execution"'
       WHEN 'appl_time_aas'              THEN 'DB Time "Application Wait Time AAS"'
       WHEN 'conc_time_exec'             THEN 'Latency "Concurrency Wait Time per Execution"'
       WHEN 'conc_time_aas'              THEN 'DB Time "Concurrency Wait Time AAS"'
       WHEN 'parses_sec'                 THEN 'DB Calls "Parses per Second"'
       WHEN 'executions_sec'             THEN 'DB Calls "Executions per Second"'
       WHEN 'fetches_sec'                THEN 'DB Calls "Fetches per Second"'
       WHEN 'loads'                      THEN 'Cursors "Loads"'
       WHEN 'invalidations'              THEN 'Cursors "Invalidations"'
       WHEN 'version_count'              THEN 'Cursors "Versions"'
       WHEN 'sharable_mem_mb'            THEN 'Cursors "Sharable Memory"'
       WHEN 'rows_processed_sec'         THEN 'Resources "Rows Processed per Second"'
       WHEN 'rows_processed_exec'        THEN 'Resources "Rows Processed per Execution"'
       WHEN 'buffer_gets_sec'            THEN 'Resources "Buffer Gets per Second"'
       WHEN 'buffer_gets_exec'           THEN 'Resources "Buffer Gets per Execution"'
       WHEN 'disk_reads_sec'             THEN 'Resources "Disk Reads per Second"'
       WHEN 'disk_reads_exec'            THEN 'Resources "Disk Reads per Execution"'
       WHEN 'physical_read_bytes_sec'    THEN 'Resources "Physical Read Bytes per Second"'
       WHEN 'physical_read_bytes_exec'   THEN 'Resources "Physical Read Bytes per Execution"'
       WHEN 'physical_write_bytes_sec'   THEN 'Resources "Physical Write Bytes per Second"'
       WHEN 'physical_write_bytes_exec'  THEN 'Resources "Physical Write Bytes per Execution"'
       ELSE 'Latency "Elapsed Time per Execution"'
       END metric_display
  FROM DUAL
/
--
COL top_what NEW_V top_what NOPRI;
SELECT CASE WHEN '&&sql_id.' IS NULL THEN 'SQL' ELSE 'Plans' END top_what FROM DUAL
/
--
DEF chart_title = 'Top &&top_what. as per &&metric_display. between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF report_title = 'Top &&top_what. as per &&metric_display. between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF xaxis_title = '';
DEF vaxis_title = 'vaxis_title';
--
COL vaxis_title NEW_V vaxis_title NOPRI;
SELECT CASE LOWER(TRIM('&&computed_metric.'))
       WHEN 'db_time_exec'               THEN 'Milliseconds per Exec'
       WHEN 'db_time_aas'                THEN 'Average Active Sessions (AAS)'
       WHEN 'cpu_time_exec'              THEN 'Milliseconds per Exec'
       WHEN 'cpu_time_aas'               THEN 'Average Active Sessions (AAS)'
       WHEN 'io_time_exec'               THEN 'Milliseconds per Exec'
       WHEN 'io_time_aas'                THEN 'Average Active Sessions (AAS)'
       WHEN 'appl_time_exec'             THEN 'Milliseconds per Exec'
       WHEN 'appl_time_aas'              THEN 'Average Active Sessions (AAS)'
       WHEN 'conc_time_exec'             THEN 'Milliseconds per Exec'
       WHEN 'conc_time_aas'              THEN 'Average Active Sessions (AAS)'
       WHEN 'parses_sec'                 THEN 'Parses (DB Calls) per Second'
       WHEN 'executions_sec'             THEN 'Executions (DB Calls) per Second'
       WHEN 'fetches_sec'                THEN 'Fetches (DB Calls) per Second'
       WHEN 'loads'                      THEN 'Cursor Loads Count'
       WHEN 'invalidations'              THEN 'Cursor Invalidations Count'
       WHEN 'version_count'              THEN 'Cursor Version Count'
       WHEN 'sharable_mem_mb'            THEN 'Cursor Sharable Memory (MBs)'
       WHEN 'rows_processed_sec'         THEN 'Rows Processed per Second'
       WHEN 'rows_processed_exec'        THEN 'Rows Processed per Exec'
       WHEN 'buffer_gets_sec'            THEN 'Buffer Gets per Second'
       WHEN 'buffer_gets_exec'           THEN 'Buffer Gets per Exec'
       WHEN 'disk_reads_sec'             THEN 'Disk Reads per Second'
       WHEN 'disk_reads_exec'            THEN 'Disk Reads per Exec'
       WHEN 'physical_read_bytes_sec'    THEN 'Physical Read Bytes per Second'
       WHEN 'physical_read_bytes_exec'   THEN 'Physical Read Bytes per Exec'
       WHEN 'physical_write_bytes_sec'   THEN 'Physical Write Bytes per Second'
       WHEN 'physical_write_bytes_exec'  THEN 'Physical Write Bytes per Exec'
       ELSE 'Milliseconds (MS)'
       END vaxis_title
  FROM DUAL
/
--
COL xaxis_title NEW_V xaxis_title NOPRI;
SELECT
CASE WHEN NVL('&&kiev_tx.', '*') <> '*' THEN 'Type:"&&kiev_tx." ' END||
CASE WHEN '&&sql_text_piece.' IS NOT NULL THEN 'Text:"%&&sql_text_piece.%" ' END||
CASE WHEN '&&sql_id.' IS NOT NULL THEN 'SQL_ID:"&&sql_id." ' END||
CASE WHEN '&&computed_metric.' IS NOT NULL THEN 'Metric:"&&computed_metric." ' END AS xaxis_title
FROM DUAL;
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2) Expect lower values than OEM Top Activity since only a subset of SQL is captured into dba_hist_sqlstat.";
DEF chart_foot_note_3 = "<br>3) PL/SQL executions are excluded since they distort charts.";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&computed_metric." "&&kiev_tx." "&&sql_text_piece." "&&sql_id."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO // please wait... getting &&metric_display....
--
COL dummy_type NOPRI;
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
FUNCTION num_format (p_number IN NUMBER, p_round IN NUMBER DEFAULT 0) 
RETURN VARCHAR2 IS
BEGIN
  IF p_number IS NULL OR ROUND(p_number, p_round) <= 0 THEN
    RETURN 'null';
  ELSE
    RETURN TO_CHAR(ROUND(p_number, p_round));
  END IF;
END num_format;
/****************************************************************************************/
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
  ELSE RETURN 'UN'; /* Unknown */
  END IF;
END application_category;
/****************************************************************************************/
all_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       DISTINCT sql_id
  FROM dba_hist_sqltext
 WHERE ('&&sql_text_piece.' IS NULL OR UPPER(DBMS_LOB.SUBSTR(sql_text, 1000)) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
   AND ('&&sql_id.' IS NULL OR sql_id = '&&sql_id.')
  --  AND ('&&kiev_tx.' = '*' OR '&&kiev_tx.' LIKE CHR(37)||application_category(DBMS_LOB.SUBSTR(sql_text, 1000))||CHR(37)) -- does not seem to work on 19c
   AND CASE WHEN '&&kiev_tx.' = '*' THEN 1 WHEN '&&kiev_tx.' LIKE CHR(37)||application_category(DBMS_LOB.SUBSTR(sql_text, 1000))||CHR(37) THEN 1 ELSE 0 END = 1
   --AND command_type NOT IN (SELECT action FROM audit_actions WHERE name IN ('PL/SQL EXECUTE', 'EXECUTE PROCEDURE'))
),
/****************************************************************************************/
snapshots AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.snap_id,
       CAST(s.end_interval_time AS DATE) end_date_time,
       (CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 24 * 60 * 60 interval_seconds
  FROM dba_hist_snapshot s /* sys.wrm$_snapshot */
 WHERE s.dbid = &&cs_dbid.
   AND s.instance_number = &&cs_instance_number.
   AND s.snap_id >= &&oldest_snap_id.
),
sqlstat_group_by_snap_sql_con AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_id,
       h.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END plan_hash_value,
       h.con_id,
       --
       SUM(h.executions_delta) executions_delta,
       SUM(h.elapsed_time_delta) elapsed_time_delta,
       SUM(h.cpu_time_delta) cpu_time_delta,
       SUM(h.iowait_delta) iowait_delta,
       SUM(h.apwait_delta) apwait_delta,
       SUM(h.ccwait_delta) ccwait_delta,
       SUM(h.parse_calls_delta) parse_calls_delta,
       SUM(h.fetches_delta) fetches_delta,
       SUM(h.loads_delta) loads_delta,
       SUM(h.invalidations_delta) invalidations_delta,
       MAX(h.version_count) version_count,
       SUM(h.sharable_mem) sharable_mem,
       SUM(h.rows_processed_delta) rows_processed_delta,
       SUM(h.buffer_gets_delta) buffer_gets_delta,
       SUM(h.disk_reads_delta) disk_reads_delta,
       SUM(h.physical_read_bytes_delta) physical_read_bytes_delta,
       SUM(h.physical_write_bytes_delta) physical_write_bytes_delta
  FROM dba_hist_sqlstat h /* sys.wrh$_sqlstat */
 WHERE h.dbid = &&cs_dbid.
   AND h.instance_number = &&cs_instance_number.
   AND h.snap_id >= &&oldest_snap_id.
   AND h.snap_id BETWEEN &&cs_snap_id_from. AND &&cs_snap_id_to.
   AND h.con_dbid > 0
   AND h.sql_id IN (SELECT t.sql_id FROM all_sql t)
 GROUP BY
       h.snap_id,
       h.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END,
       h.con_id
),
sqlstat_snap_range AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END plan_hash_value,
       h.con_id,
       --
       ROUND(SUM(h.elapsed_time_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3) db_time_exec,
       ROUND(SUM(h.elapsed_time_delta)/SUM(s.interval_seconds)/1e6,3) db_time_aas,
       ROUND(SUM(h.cpu_time_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3) cpu_time_exec,
       ROUND(SUM(h.cpu_time_delta)/SUM(s.interval_seconds)/1e6,3) cpu_time_aas,
       ROUND(SUM(h.iowait_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3) io_time_exec,
       ROUND(SUM(h.iowait_delta)/SUM(s.interval_seconds)/1e6,3) io_time_aas,
       ROUND(SUM(h.apwait_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3) appl_time_exec,
       ROUND(SUM(h.apwait_delta)/SUM(s.interval_seconds)/1e6,3) appl_time_aas,
       ROUND(SUM(h.ccwait_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3) conc_time_exec,
       ROUND(SUM(h.ccwait_delta)/SUM(s.interval_seconds)/1e6,3) conc_time_aas,
       SUM(h.parse_calls_delta) parses,
       ROUND(SUM(h.parse_calls_delta)/SUM(s.interval_seconds),3) parses_sec,
       SUM(h.executions_delta) executions,
       ROUND(SUM(h.executions_delta)/SUM(s.interval_seconds),3) executions_sec,
       SUM(h.fetches_delta) fetches,
       ROUND(SUM(h.fetches_delta)/SUM(s.interval_seconds),3) fetches_sec,
       SUM(h.loads_delta) loads,
       SUM(h.invalidations_delta) invalidations,
       MAX(h.version_count) version_count,
       ROUND(SUM(h.sharable_mem)/POWER(2,20),3) sharable_mem_mb,
       ROUND(SUM(h.rows_processed_delta)/SUM(s.interval_seconds),3) rows_processed_sec,
       ROUND(SUM(h.rows_processed_delta)/GREATEST(SUM(h.executions_delta),1),3) rows_processed_exec,
       ROUND(SUM(h.buffer_gets_delta)/SUM(s.interval_seconds),3) buffer_gets_sec,
       ROUND(SUM(h.buffer_gets_delta)/GREATEST(SUM(h.executions_delta),1),3) buffer_gets_exec,
       ROUND(SUM(h.disk_reads_delta)/SUM(s.interval_seconds),3) disk_reads_sec,
       ROUND(SUM(h.disk_reads_delta)/GREATEST(SUM(h.executions_delta),1),3) disk_reads_exec,
       ROUND(SUM(h.physical_read_bytes_delta)/SUM(s.interval_seconds),3) physical_read_bytes_sec,
       ROUND(SUM(h.physical_read_bytes_delta)/GREATEST(SUM(h.executions_delta),1),3) physical_read_bytes_exec,
       ROUND(SUM(h.physical_write_bytes_delta)/SUM(s.interval_seconds),3) physical_write_bytes_sec,
       ROUND(SUM(h.physical_write_bytes_delta)/GREATEST(SUM(h.executions_delta),1),3) physical_write_bytes_exec
       --
  FROM sqlstat_group_by_snap_sql_con h, 
       snapshots s /* dba_hist_snapshot */
 WHERE s.snap_id = h.snap_id
 GROUP BY
       h.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END,
       h.con_id
),
ranked_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sr.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE sr.plan_hash_value END plan_hash_value,
       sr.con_id,
       sr.&&computed_metric. as metric, sr.db_time_exec, sr.db_time_aas,
       ROW_NUMBER() OVER (ORDER BY sr.&&computed_metric. DESC NULLS LAST, sr.db_time_exec DESC NULLS LAST, sr.db_time_aas DESC NULLS LAST) rank
  FROM sqlstat_snap_range sr
),
sqlstat_ranked_and_grouped AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       CASE WHEN rs.rank <= &&cs_top_n. THEN h.sql_id END sql_id,
       CASE WHEN rs.rank <= &&cs_top_n. THEN (CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END) END plan_hash_value,
       CASE WHEN rs.rank <= &&cs_top_n. THEN rs.rank END rank,
       h.con_id,
       h.snap_id,
       --
       SUM(h.executions_delta) executions_delta,
       SUM(h.elapsed_time_delta) elapsed_time_delta,
       SUM(h.cpu_time_delta) cpu_time_delta,
       SUM(h.iowait_delta) iowait_delta,
       SUM(h.apwait_delta) apwait_delta,
       SUM(h.ccwait_delta) ccwait_delta,
       SUM(h.parse_calls_delta) parse_calls_delta,
       SUM(h.fetches_delta) fetches_delta,
       SUM(h.loads_delta) loads_delta,
       SUM(h.invalidations_delta) invalidations_delta,
       MAX(h.version_count) version_count,
       SUM(h.sharable_mem) sharable_mem,
       SUM(h.rows_processed_delta) rows_processed_delta,
       SUM(h.buffer_gets_delta) buffer_gets_delta,
       SUM(h.disk_reads_delta) disk_reads_delta,
       SUM(h.physical_read_bytes_delta) physical_read_bytes_delta,
       SUM(h.physical_write_bytes_delta) physical_write_bytes_delta
  FROM dba_hist_sqlstat h, /* sys.wrh$_sqlstat */
       ranked_sql rs
 WHERE h.dbid = &&cs_dbid.
   AND h.instance_number = &&cs_instance_number.
   AND h.snap_id >= &&oldest_snap_id.
   AND h.snap_id BETWEEN &&cs_snap_id_from. AND &&cs_snap_id_to. -- limit time series to range specified as parameters
   AND h.con_dbid > 0
   AND h.sql_id IN (SELECT t.sql_id FROM all_sql t)
   AND rs.sql_id(+) = h.sql_id
   AND rs.plan_hash_value(+) = (CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END)
   AND rs.con_id(+) = h.con_id
 GROUP BY
       CASE WHEN rs.rank <= &&cs_top_n. THEN h.sql_id END,
       CASE WHEN rs.rank <= &&cs_top_n. THEN (CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END) END,
       CASE WHEN rs.rank <= &&cs_top_n. THEN rs.rank END,
       h.con_id,
       h.snap_id
),
sqlstat_time_series AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END plan_hash_value,
       h.rank,
       h.con_id,
       h.snap_id,
       --
       ROUND(SUM(h.elapsed_time_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3) db_time_exec,
       ROUND(SUM(h.elapsed_time_delta)/SUM(s.interval_seconds)/1e6,3) db_time_aas,
       ROUND(SUM(h.cpu_time_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3) cpu_time_exec,
       ROUND(SUM(h.cpu_time_delta)/SUM(s.interval_seconds)/1e6,3) cpu_time_aas,
       ROUND(SUM(h.iowait_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3) io_time_exec,
       ROUND(SUM(h.iowait_delta)/SUM(s.interval_seconds)/1e6,3) io_time_aas,
       ROUND(SUM(h.apwait_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3) appl_time_exec,
       ROUND(SUM(h.apwait_delta)/SUM(s.interval_seconds)/1e6,3) appl_time_aas,
       ROUND(SUM(h.ccwait_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3) conc_time_exec,
       ROUND(SUM(h.ccwait_delta)/SUM(s.interval_seconds)/1e6,3) conc_time_aas,
       SUM(h.parse_calls_delta) parses,
       ROUND(SUM(h.parse_calls_delta)/SUM(s.interval_seconds),3) parses_sec,
       SUM(h.executions_delta) executions,
       ROUND(SUM(h.executions_delta)/SUM(s.interval_seconds),3) executions_sec,
       SUM(h.fetches_delta) fetches,
       ROUND(SUM(h.fetches_delta)/SUM(s.interval_seconds),3) fetches_sec,
       SUM(h.loads_delta) loads,
       SUM(h.invalidations_delta) invalidations,
       MAX(h.version_count) version_count,
       ROUND(SUM(h.sharable_mem)/POWER(2,20),3) sharable_mem_mb,
       ROUND(SUM(h.rows_processed_delta)/SUM(s.interval_seconds),3) rows_processed_sec,
       ROUND(SUM(h.rows_processed_delta)/GREATEST(SUM(h.executions_delta),1),3) rows_processed_exec,
       ROUND(SUM(h.buffer_gets_delta)/SUM(s.interval_seconds),3) buffer_gets_sec,
       ROUND(SUM(h.buffer_gets_delta)/GREATEST(SUM(h.executions_delta),1),3) buffer_gets_exec,
       ROUND(SUM(h.disk_reads_delta)/SUM(s.interval_seconds),3) disk_reads_sec,
       ROUND(SUM(h.disk_reads_delta)/GREATEST(SUM(h.executions_delta),1),3) disk_reads_exec,
       ROUND(SUM(h.physical_read_bytes_delta)/SUM(s.interval_seconds),3) physical_read_bytes_sec,
       ROUND(SUM(h.physical_read_bytes_delta)/GREATEST(SUM(h.executions_delta),1),3) physical_read_bytes_exec,
       ROUND(SUM(h.physical_write_bytes_delta)/SUM(s.interval_seconds),3) physical_write_bytes_sec,
       ROUND(SUM(h.physical_write_bytes_delta)/GREATEST(SUM(h.executions_delta),1),3) physical_write_bytes_exec
       --
  FROM sqlstat_ranked_and_grouped h,
       snapshots s /* dba_hist_snapshot */
 WHERE s.snap_id = h.snap_id
 GROUP BY
       h.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END,
       h.rank,
       h.con_id,
       h.snap_id
),
sqlstat_top_and_null AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ts.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE ts.plan_hash_value END plan_hash_value,
       ts.con_id,
       ts.rank,
       ts.snap_id,
       ts.&&computed_metric. value
  FROM sqlstat_time_series ts
),
sqlstat_top AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       tn.snap_id,
       SUM(CASE tn.rank WHEN 01 THEN tn.value ELSE 0 END) top_01,
       SUM(CASE tn.rank WHEN 02 THEN tn.value ELSE 0 END) top_02,
       SUM(CASE tn.rank WHEN 03 THEN tn.value ELSE 0 END) top_03,
       SUM(CASE tn.rank WHEN 04 THEN tn.value ELSE 0 END) top_04,
       SUM(CASE tn.rank WHEN 05 THEN tn.value ELSE 0 END) top_05,
       SUM(CASE tn.rank WHEN 06 THEN tn.value ELSE 0 END) top_06,
       SUM(CASE tn.rank WHEN 07 THEN tn.value ELSE 0 END) top_07,
       SUM(CASE tn.rank WHEN 08 THEN tn.value ELSE 0 END) top_08,
       SUM(CASE tn.rank WHEN 09 THEN tn.value ELSE 0 END) top_09,
       SUM(CASE tn.rank WHEN 10 THEN tn.value ELSE 0 END) top_10,
       SUM(CASE tn.rank WHEN 11 THEN tn.value ELSE 0 END) top_11,
       SUM(CASE tn.rank WHEN 12 THEN tn.value ELSE 0 END) top_12, -- consistent with tn.value on top_n
       /*
       SUM(CASE tn.rank WHEN 13 THEN tn.value ELSE 0 END) top_13,
       SUM(CASE tn.rank WHEN 14 THEN tn.value ELSE 0 END) top_14,
       SUM(CASE tn.rank WHEN 15 THEN tn.value ELSE 0 END) top_15,
       SUM(CASE tn.rank WHEN 16 THEN tn.value ELSE 0 END) top_16,
       SUM(CASE tn.rank WHEN 17 THEN tn.value ELSE 0 END) top_17,
       SUM(CASE tn.rank WHEN 18 THEN tn.value ELSE 0 END) top_18,
       SUM(CASE tn.rank WHEN 19 THEN tn.value ELSE 0 END) top_19,
       SUM(CASE tn.rank WHEN 20 THEN tn.value ELSE 0 END) sql_20, -- consistent with tn.value on top_n
       */
       SUM(CASE WHEN tn.rank IS NULL THEN tn.value ELSE 0 END) top_99 -- all but top
  FROM sqlstat_top_and_null tn
 GROUP BY
       tn.snap_id
),
sql_list AS (
SELECT /*+ MATERIALIZE NO_MERGE FULL(rs) */
       rs.rank,
       ',{label:''#'||LPAD(rs.rank,2,'0')||' '||
       (CASE WHEN '&&sql_id.' IS NULL THEN rs.sql_id ELSE TO_CHAR(rs.plan_hash_value) END)||
       (CASE '&&cs_con_name.' WHEN 'CDB$ROOT' THEN ' '||c.name END)||''''||
       ', id:'''||LPAD(rs.rank,2,'0')||''', type:''number''}' AS line
  FROM ranked_sql rs,
       v$containers c
 WHERE rs.rank <= &&cs_top_n.
   AND c.con_id = rs.con_id
 ORDER BY
       rs.rank
),
sql_list_part_2 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       LEVEL rank,
       ',{label:''#'||LPAD(LEVEL,2,'0')||''' '||
       ', id:'''||LPAD(LEVEL,2,'0')||''', type:''number''}' AS line
  FROM DUAL
 WHERE LEVEL > (SELECT MAX(rank) FROM sql_list)
CONNECT BY LEVEL <= &&cs_top_n.
 ORDER BY
       LEVEL
),
data_list AS (
SELECT /*+ MATERIALIZE NO_MERGE FULL(s) FULL(t) USE_HASH(s t) LEADING(s t) */
       ', [new Date('||
       TO_CHAR(s.end_date_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(s.end_date_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(s.end_date_time, 'DD')|| /* day */
       ','||TO_CHAR(s.end_date_time, 'HH24')|| /* hour */
       ','||TO_CHAR(s.end_date_time, 'MI')|| /* minute */
       ','||TO_CHAR(s.end_date_time, 'SS')|| /* second */
       ')'||
       ','||num_format(t.top_01,1)||
       ','||num_format(t.top_02,1)||
       ','||num_format(t.top_03,1)||
       ','||num_format(t.top_04,1)||
       ','||num_format(t.top_05,1)||
       ','||num_format(t.top_06,1)||
       ','||num_format(t.top_07,1)||
       ','||num_format(t.top_08,1)||
       ','||num_format(t.top_09,1)||
       ','||num_format(t.top_10,1)||
       ','||num_format(t.top_11,1)||
       ','||num_format(t.top_12,1)||
       /*
       ','||num_format(t.top_13,1)||
       ','||num_format(t.top_14,1)||
       ','||num_format(t.top_15,1)||
       ','||num_format(t.top_16,1)||
       ','||num_format(t.top_17,1)||
       ','||num_format(t.top_18,1)||
       ','||num_format(t.top_19,1)||
       ','||num_format(t.sql_20,1)||
       */
       ','||num_format(t.top_99,1)||
       ']' line--,
       --ROW_NUMBER() OVER (ORDER BY s.end_date_time ASC  NULLS LAST) AS head_rn,
       --ROW_NUMBER() OVER (ORDER BY s.end_date_time DESC NULLS LAST) AS tail_rn
  FROM sqlstat_top t,
       snapshots s /* dba_hist_snapshot */
 WHERE s.snap_id = t.snap_id
 ORDER BY
       t.snap_id
)
/****************************************************************************************/
SELECT 1 AS dummy_type, line FROM sql_list
 UNION ALL
SELECT 2 AS dummy_type, line FROM sql_list_part_2
 UNION ALL
SELECT 3 AS dummy_type, ',{label:''#99 all others'', id:''99'', type:''number''}]' AS line FROM DUAL
 UNION ALL
SELECT 4 AS dummy_type, line FROM data_list
 --WHERE head_rn > 1
   --AND tail_rn > 1
ORDER BY dummy_type, line
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = 'Scatter';
-- disable explorer with "//" when using Pie
DEF cs_chart_option_explorer = '';
-- enable pie options with "" when using Pie
DEF cs_chart_option_pie = '//';
-- use oem colors
DEF cs_oem_colors_series = '//';
DEF cs_oem_colors_slices = '//';
-- for line charts
DEF cs_curve_type = '//';
--
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
--
PRO
PRO &&report_foot_note.
--