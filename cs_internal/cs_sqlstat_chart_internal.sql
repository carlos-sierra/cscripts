DEF metric_group = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&metric_group.' cs_file_name FROM DUAL;
--
COL report_title NEW_V report_title NOPRI;
COL vaxis_title NEW_V vaxis_title NOPRI;
SELECT CASE '&&metric_group.'
       WHEN 'db_time' THEN 'Database Time (avg)'
       WHEN 'latency' THEN 'Database Latency (avg)'
       WHEN 'time_per_row' THEN 'Time per Row Returned (avg)'
       WHEN 'calls' THEN 'Database Calls per Second (avg)'
       WHEN 'rows_sec' THEN 'Rows Processed per Second (avg)'
       WHEN 'rows_exec' THEN 'Rows Processed per Execution (avg)'
       WHEN 'reads_sec' THEN 'Logical and Physical Reads per Second (avg)'
       WHEN 'reads_exec' THEN 'Logical and Physical Reads per Execution (avg)'
       WHEN 'reads_per_row' THEN 'Logical and Physical Reads per Row Returned (avg)'
       WHEN 'cursors' THEN 'Loads, Invalidations and Version Count (avg)'
       WHEN 'memory' THEN 'Sharable Memory (avg)'
       END report_title,
       CASE '&&metric_group.'
       WHEN 'db_time' THEN 'Average Active Sessions (AAS)'
       WHEN 'latency' THEN 'ms (per Execution)'
       WHEN 'time_per_row' THEN 'us (per Row Returned)'
       WHEN 'calls' THEN 'Calls Count per Second'
       WHEN 'rows_sec' THEN 'Rows Processed'
       WHEN 'rows_exec' THEN 'Rows Processed'
       WHEN 'reads_sec' THEN 'Reads per Second'
       WHEN 'reads_exec' THEN 'Reads per Execution'
       WHEN 'reads_per_row' THEN 'Reads per Row Returned'
       WHEN 'cursors' THEN 'Count'
       WHEN 'memory' THEN 'MBs'
       END vaxis_title
  FROM DUAL
/
--
DEF report_title = '&&report_title. between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF xaxis_title = '';
DEF vaxis_title = '&&vaxis_title.';
--
COL xaxis_title NEW_V xaxis_title NOPRI;
SELECT
CASE WHEN NVL('&&kiev_tx.', '*') <> '*' THEN 'Type:"&&kiev_tx." ' END||
CASE WHEN '&&sql_text_piece.' IS NOT NULL THEN 'Text:"%&&sql_text_piece.%" ' END||
CASE WHEN '&&sql_id.' IS NOT NULL THEN 'SQL_ID:"&&sql_id." ' END||
CASE WHEN '&&phv.' IS NOT NULL THEN 'Plan:"&&phv." ' END||
CASE WHEN '&&parsing_schema_name.' IS NOT NULL THEN 'Schema:"&&parsing_schema_name." ' END AS xaxis_title
FROM DUAL;
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2) Expect lower values than OEM Top Activity since only a subset of SQL is captured into dba_hist_sqlstat.";
DEF chart_foot_note_3 = "<br>3) PL/SQL executions are excluded since they distort charts.";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&metric_group." "&&kiev_tx." "&&sql_text_piece." "&&sql_id." "&&phv." "&&parsing_schema_name."';
--
@@cs_internal/cs_spool_head_chart.sql
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
SELECT 
CASE '&&metric_group.' 
WHEN 'db_time' THEN 
q'[// &&metric_group.
,{label:'DB Time', id:'1', type:'number'}
,{label:'CPU Time', id:'2', type:'number'}
,{label:'User IO Time', id:'3', type:'number'}
,{label:'Application (LOCK)', id:'4', type:'number'}
,{label:'Concurrency Time', id:'5', type:'number'}
]'
WHEN 'latency' THEN 
q'[// &&metric_group.
,{label:'DB Time', id:'1', type:'number'}
,{label:'CPU Time', id:'2', type:'number'}
,{label:'User IO Time', id:'3', type:'number'}
,{label:'Application (LOCK)', id:'4', type:'number'}
,{label:'Concurrency Time', id:'5', type:'number'}
]'
WHEN 'time_per_row' THEN 
q'[// &&metric_group.
,{label:'DB Time', id:'1', type:'number'}
,{label:'CPU Time', id:'2', type:'number'}
,{label:'User IO Time', id:'3', type:'number'}
,{label:'Application (LOCK)', id:'4', type:'number'}
,{label:'Concurrency Time', id:'5', type:'number'}
]'
WHEN 'calls' THEN 
q'[// &&metric_group.
,{label:'Parses', id:'1', type:'number'}
,{label:'Executions', id:'2', type:'number'}
,{label:'Fetches', id:'3', type:'number'}
]'
WHEN 'rows_sec' THEN 
q'[// &&metric_group.
,{label:'Rows Processed', id:'1', type:'number'}
]'
WHEN 'rows_exec' THEN 
q'[// &&metric_group.
,{label:'Rows Processed', id:'1', type:'number'}
]'
WHEN 'reads_sec' THEN 
q'[// &&metric_group.
,{label:'Buffer Gets', id:'1', type:'number'}
,{label:'Disk Reads', id:'2', type:'number'}
]'
WHEN 'reads_exec' THEN 
q'[// &&metric_group.
,{label:'Buffer Gets', id:'1', type:'number'}
,{label:'Disk Reads', id:'2', type:'number'}
]'
WHEN 'reads_per_row' THEN 
q'[// &&metric_group.
,{label:'Buffer Gets', id:'1', type:'number'}
,{label:'Disk Reads', id:'2', type:'number'}
]'
WHEN 'cursors' THEN 
q'[// &&metric_group.
,{label:'Loads', id:'1', type:'number'}
,{label:'Invalidations', id:'2', type:'number'}
,{label:'Version Count', id:'3', type:'number'}
]'
WHEN 'memory' THEN 
q'[// &&metric_group.
,{label:'Sharable Memory', id:'1', type:'number'}
]'
END FROM DUAL
/
PRO // please wait... getting &&metric_group....
PRO ]
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
  FROM v$sql
 WHERE ('&&sql_text_piece.' IS NULL OR UPPER(sql_text) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
   AND ('&&sql_id.' IS NULL OR sql_id = '&&sql_id.') 
  --  AND ('&&kiev_tx.' = '*' OR '&&kiev_tx.' LIKE CHR(37)||application_category(sql_text)||CHR(37))-- does not seem to work on 19c
   AND CASE WHEN '&&kiev_tx.' = '*' THEN 1 WHEN '&&kiev_tx.' LIKE CHR(37)||application_category(sql_text)||CHR(37) THEN 1 ELSE 0 END = 1
   --AND command_type NOT IN (SELECT action FROM audit_actions WHERE name IN ('PL/SQL EXECUTE', 'EXECUTE PROCEDURE'))
 UNION
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT sql_id
  FROM dba_hist_sqltext
 WHERE dbid = &&cs_dbid.
   AND ('&&sql_text_piece.' IS NULL OR UPPER(DBMS_LOB.substr(sql_text, 1000)) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
   AND ('&&sql_id.' IS NULL OR sql_id = '&&sql_id.') 
  --  AND ('&&kiev_tx.' = '*' OR '&&kiev_tx.' LIKE CHR(37)||application_category(DBMS_LOB.substr(sql_text, 1000))||CHR(37)) -- does not seem to work on 19c
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
),
sqlstat_group_by_snap_id AS (
SELECT /*+ MATERIALIZE NO_MERGE */
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
       SUM(h.disk_reads_delta) disk_reads_delta
       --
  FROM dba_hist_sqlstat h /* sys.wrh$_sqlstat */
 WHERE h.dbid = &&cs_dbid.
   AND h.instance_number = &&cs_instance_number.
   AND h.con_dbid > 0
   AND h.snap_id >= &&oldest_snap_id.
   AND h.snap_id BETWEEN &&cs_snap_id_from. AND &&cs_snap_id_to.
   AND ('&&sql_id.' IS NULL OR h.sql_id = '&&sql_id.') 
   AND ('&&phv.' IS NULL OR h.plan_hash_value = TO_NUMBER('&&phv.'))
   AND ('&&parsing_schema_name.' IS NULL OR h.parsing_schema_name = UPPER('&&parsing_schema_name.'))
   AND h.sql_id IN (SELECT t.sql_id FROM all_sql t)
 GROUP BY
       h.snap_id
),
sqlstat_time_series AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.snap_id,
       s.end_date_time,
       --
       NVL(ROUND(SUM(h.elapsed_time_delta)/SUM(s.interval_seconds)/1e6,3), 0) db_time_aas,
       NVL(ROUND(SUM(h.cpu_time_delta)/SUM(s.interval_seconds)/1e6,3), 0) cpu_time_aas,
       NVL(ROUND(SUM(h.iowait_delta)/SUM(s.interval_seconds)/1e6,3), 0) io_time_aas,
       NVL(ROUND(SUM(h.apwait_delta)/SUM(s.interval_seconds)/1e6,3), 0) appl_time_aas,
       NVL(ROUND(SUM(h.ccwait_delta)/SUM(s.interval_seconds)/1e6,3), 0) conc_time_aas,
       --
       NVL(ROUND(SUM(h.elapsed_time_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3), 0) db_time_exec,
       NVL(ROUND(SUM(h.cpu_time_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3), 0) cpu_time_exec,
       NVL(ROUND(SUM(h.iowait_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3), 0) io_time_exec,
       NVL(ROUND(SUM(h.apwait_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3), 0) appl_time_exec,
       NVL(ROUND(SUM(h.ccwait_delta)/1e3/GREATEST(SUM(h.executions_delta),1),3), 0) conc_time_exec,
       --
       NVL(ROUND(SUM(h.elapsed_time_delta)/GREATEST(SUM(h.rows_processed_delta),1),3), 0) db_time_row,
       NVL(ROUND(SUM(h.cpu_time_delta)/GREATEST(SUM(h.rows_processed_delta),1),3), 0) cpu_time_row,
       NVL(ROUND(SUM(h.iowait_delta)/GREATEST(SUM(h.rows_processed_delta),1),3), 0) io_time_row,
       NVL(ROUND(SUM(h.apwait_delta)/GREATEST(SUM(h.rows_processed_delta),1),3), 0) appl_time_row,
       NVL(ROUND(SUM(h.ccwait_delta)/GREATEST(SUM(h.rows_processed_delta),1),3), 0) conc_time_row,
       --
       NVL(ROUND(SUM(h.parse_calls_delta)/SUM(s.interval_seconds),3), 0) parses_sec,
       NVL(ROUND(SUM(h.executions_delta)/SUM(s.interval_seconds),3), 0) executions_sec,
       NVL(ROUND(SUM(h.fetches_delta)/SUM(s.interval_seconds),3), 0) fetches_sec,
       --
       NVL(ROUND(SUM(h.rows_processed_delta)/SUM(s.interval_seconds),3), 0) rows_processed_sec,
       NVL(ROUND(SUM(h.rows_processed_delta)/GREATEST(SUM(h.executions_delta),1),3), 0) rows_processed_exec,
       --
       NVL(ROUND(SUM(h.buffer_gets_delta)/SUM(s.interval_seconds),3), 0) buffer_gets_sec,
       NVL(ROUND(SUM(h.disk_reads_delta)/SUM(s.interval_seconds),3), 0) disk_reads_sec,
       --
       NVL(ROUND(SUM(h.buffer_gets_delta)/GREATEST(SUM(h.executions_delta),1),3), 0) buffer_gets_exec,
       NVL(ROUND(SUM(h.disk_reads_delta)/GREATEST(SUM(h.executions_delta),1),3), 0) disk_reads_exec,
       --
       NVL(ROUND(SUM(h.buffer_gets_delta)/GREATEST(SUM(h.rows_processed_delta),1),3), 0) buffer_gets_row,
       NVL(ROUND(SUM(h.disk_reads_delta)/GREATEST(SUM(h.rows_processed_delta),1),3), 0) disk_reads_row,
       --
       NVL(SUM(h.loads_delta), 0) loads,
       NVL(SUM(h.invalidations_delta), 0) invalidations,
       NVL(MAX(h.version_count), 0) version_count,
       --
       NVL(ROUND(SUM(h.sharable_mem)/POWER(2,20),3), 0) sharable_mem_mb
       --
  FROM sqlstat_group_by_snap_id h, 
       snapshots s /* dba_hist_snapshot */
 WHERE s.snap_id = h.snap_id
 GROUP BY
       s.snap_id,
       s.end_date_time
)
SELECT ', [new Date('||
       TO_CHAR(q.end_date_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.end_date_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.end_date_time, 'DD')|| /* day */
       ','||TO_CHAR(q.end_date_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.end_date_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.end_date_time, 'SS')|| /* second */
       ')'||
       CASE '&&metric_group.' 
         WHEN 'db_time' THEN
           ','||num_format(q.db_time_aas, 3)|| 
           ','||num_format(q.cpu_time_aas, 3)|| 
           ','||num_format(q.io_time_aas, 3)|| 
           ','||num_format(q.appl_time_aas, 3)|| 
           ','||num_format(q.conc_time_aas, 3)
         WHEN 'latency' THEN
           ','||num_format(q.db_time_exec, 3)|| 
           ','||num_format(q.cpu_time_exec, 3)|| 
           ','||num_format(q.io_time_exec, 3)|| 
           ','||num_format(q.appl_time_exec, 3)|| 
           ','||num_format(q.conc_time_exec, 3)
         WHEN 'time_per_row' THEN
           ','||num_format(q.db_time_row, 3)|| 
           ','||num_format(q.cpu_time_row, 3)|| 
           ','||num_format(q.io_time_row, 3)|| 
           ','||num_format(q.appl_time_row, 3)|| 
           ','||num_format(q.conc_time_row, 3)
         WHEN 'calls' THEN
           ','||num_format(q.parses_sec, 3)|| 
           ','||num_format(q.executions_sec, 3)|| 
           ','||num_format(q.fetches_sec, 3)
         WHEN 'rows_sec' THEN
           ','||num_format(q.rows_processed_sec, 3)
         WHEN 'rows_exec' THEN
           ','||num_format(q.rows_processed_exec, 3)
         WHEN 'reads_sec' THEN
           ','||num_format(q.buffer_gets_sec, 3)|| 
           ','||num_format(q.disk_reads_sec, 3)
         WHEN 'reads_exec' THEN
           ','||num_format(q.buffer_gets_exec, 3)|| 
           ','||num_format(q.disk_reads_exec, 3)
         WHEN 'reads_per_row' THEN
           ','||num_format(q.buffer_gets_row, 3)|| 
           ','||num_format(q.disk_reads_row, 3)
         WHEN 'cursors' THEN
           ','||num_format(q.loads)|| 
           ','||num_format(q.invalidations)|| 
           ','||num_format(q.version_count)
         WHEN 'memory' THEN
           ','||num_format(q.sharable_mem_mb, 3)
       END||
       ']'
  FROM sqlstat_time_series q
 ORDER BY
       q.end_date_time
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