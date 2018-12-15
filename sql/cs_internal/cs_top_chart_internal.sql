DEF computed_metric = '&1.';
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name._&&computed_metric.' cs_file_name FROM DUAL;
--
COL metric_display NEW_V metric_display NOPRI;
SELECT CASE LOWER(TRIM('&&computed_metric.'))
       WHEN 'db_time_exec' THEN 'Database Time per Execution'
       WHEN 'db_time_aas' THEN 'Database Time'
       WHEN 'cpu_time_exec' THEN 'CPU Time per Execution'
       WHEN 'cpu_time_aas' THEN 'CPU Time'
       WHEN 'io_time_exec' THEN 'IO Wait Time per Execution'
       WHEN 'io_time_aas' THEN 'IO Wait Time'
       WHEN 'appl_time_exec' THEN 'Application Wait Time per Execution'
       WHEN 'appl_time_aas' THEN 'Application Wait Time'
       WHEN 'conc_time_exec' THEN 'Concurrency Wait Time per Execution'
       WHEN 'conc_time_aas' THEN 'Concurrency Wait Time'
       WHEN 'parses_sec' THEN 'Parses per Second'
       WHEN 'executions_sec' THEN 'Executions per Second'
       WHEN 'fetches_sec' THEN 'Fetches per Second'
       WHEN 'loads' THEN 'Loads'
       WHEN 'invalidations' THEN 'Invalidations'
       WHEN 'version_count' THEN 'Versions'
       WHEN 'sharable_mem_mb' THEN 'Sharable Memory'
       WHEN 'rows_processed_sec' THEN 'Rows Processed per Second'
       WHEN 'rows_processed_exec' THEN 'Rows Processed per Execution'
       WHEN 'buffer_gets_sec' THEN 'Buffer Gets per Second'
       WHEN 'buffer_gets_exec' THEN 'Buffer Gets per Execution'
       WHEN 'disk_reads_sec' THEN 'Disk Reads per Second'
       WHEN 'disk_reads_exec' THEN 'Disk Reads per Execution'
       WHEN 'physical_read_bytes_sec' THEN 'Physical Read Bytes per Second'
       WHEN 'physical_read_bytes_exec' THEN 'Physical Read Bytes per Execution'
       WHEN 'physical_write_bytes_sec' THEN 'Physical Write Bytes per Second'
       WHEN 'physical_write_bytes_exec' THEN 'Physical Write Bytes per Execution'
       ELSE 'Database Time per Execution'
       END metric_display
  FROM DUAL
/
--
COL top_what NEW_V top_what NOPRI;
SELECT CASE WHEN '&&sql_id.' IS NULL THEN 'SQL' ELSE 'Plans' END top_what FROM DUAL
/
--
DEF chart_title = "Top &&top_what. as per &&metric_display. between &&cs_sample_time_from. and &&cs_sample_time_to. UTC";
DEF report_title = "Top &&top_what. as per &&metric_display. between &&cs_sample_time_from. and &&cs_sample_time_to. UTC";
DEF xaxis_title = "&&sql_id. &&metric_display. (&&computed_metric.)";
DEF vaxis_title = "vaxis_title";
COL vaxis_title NEW_V vaxis_title NOPRI;
--
SELECT CASE LOWER(TRIM('&&computed_metric.'))
       WHEN 'db_time_exec' THEN 'Milliseconds (MS)'
       WHEN 'db_time_aas' THEN 'Average Active Sessions (AAS)'
       WHEN 'cpu_time_exec' THEN 'Milliseconds (MS)'
       WHEN 'cpu_time_aas' THEN 'Average Active Sessions (AAS)'
       WHEN 'io_time_exec' THEN 'Milliseconds (MS)'
       WHEN 'io_time_aas' THEN 'Average Active Sessions (AAS)'
       WHEN 'appl_time_exec' THEN 'Milliseconds (MS)'
       WHEN 'appl_time_aas' THEN 'Average Active Sessions (AAS)'
       WHEN 'conc_time_exec' THEN 'Milliseconds (MS)'
       WHEN 'conc_time_aas' THEN 'Average Active Sessions (AAS)'
       WHEN 'parses_sec' THEN 'Parse Calls'
       WHEN 'executions_sec' THEN 'Execution Calls'
       WHEN 'fetches_sec' THEN 'Fetch Calls'
       WHEN 'loads' THEN 'Loads'
       WHEN 'invalidations' THEN 'Invalidations'
       WHEN 'version_count' THEN 'Version Count'
       WHEN 'sharable_mem_mb' THEN 'Sharable Memory (MBs)'
       WHEN 'rows_processed_sec' THEN 'Rows Processed'
       WHEN 'rows_processed_exec' THEN 'Rows Processed'
       WHEN 'buffer_gets_sec' THEN 'Buffer Gets'
       WHEN 'buffer_gets_exec' THEN 'Buffer Gets'
       WHEN 'disk_reads_sec' THEN 'Disk Reads'
       WHEN 'disk_reads_exec' THEN 'Disk Reads'
       WHEN 'physical_read_bytes_sec' THEN 'Physical Read Bytes'
       WHEN 'physical_read_bytes_exec' THEN 'Physical Read Bytes'
       WHEN 'physical_write_bytes_sec' THEN 'Physical Write Bytes'
       WHEN 'physical_write_bytes_exec' THEN 'Physical Write Bytes'
       ELSE 'Milliseconds (MS)'
       END vaxis_title
  FROM DUAL
/
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:0";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2) Expect lower values than OEM Top Activity since only a subset of SQL is captured into dba_hist_sqlstat.";
DEF chart_foot_note_3 = "<br>3) PL/SQL executions are excluded since they distort charts.";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "&&cs_script_name..sql";
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'all others'
PRO // please wait... getting &&metric_display....
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
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
    ELSIF p_sql_text LIKE k_appl_handle_prefix||'checkEndRowValid'||k_appl_handle_suffix
      OR  p_sql_text LIKE k_appl_handle_prefix||'deleteValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'exists'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch commit by idempotency token'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'findMatchingRow'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionCommitID'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getTransactionProgress'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'lockForCommit'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'lockKievTransactor'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'putBucket'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'readTransactionsSince'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'recordTransactionState'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'setValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'updateIdentityValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'updateNextKievTransID'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'updateTransactorState'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'upsert_transactor_state'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'writeTransactionKeys'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'SPM:CP'||k_appl_handle_suffix 
      OR  LOWER(p_sql_text) LIKE CHR(37)||'lock table kievtransactions'||CHR(37) 
    THEN RETURN gk_appl_cat_2;
    ELSIF p_sql_text LIKE k_appl_handle_prefix||'bucketIndexSelect'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'bucketKeySelect'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'bucketValueSelect'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'countTransactions'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch snapshots'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getAutoSequences'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getNextIdentityValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getValues'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performContinuedScanValues'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performScanQuery'||k_appl_handle_suffix
      OR  p_sql_text LIKE k_appl_handle_prefix||'performSnapshotScanQuery'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performFirstRowsScanQuery'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performStartScanValues'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'selectBuckets'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_3;
    ELSIF p_sql_text LIKE k_appl_handle_prefix||'countAllRows'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'countKtkRows'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Delete rows from'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'deleteBucketGarbage'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventMaxId'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventTryInsert'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getGCLogEntries'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionOlderThan'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'hashBucket'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'hashSnapshot'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Populate workspace'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'populateBucketGCWorkspace'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'secondsSinceLastGcEvent'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'validateIfWorkspaceEmpty'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_4;
    ELSE RETURN 'Unknown';
    END IF;
END application_category;
all_sql AS (
--SELECT /*+ MATERIALIZE NO_MERGE */
--      DISTINCT sql_id, command_type, sql_text FROM v$sql
--UNION
SELECT /*+ MATERIALIZE NO_MERGE */ 
       DISTINCT sql_id, DBMS_LOB.SUBSTR(sql_text, 1000) sql_text 
  FROM dba_hist_sqltext
 WHERE 1 = 1
   AND ('&&sql_text_piece.' IS NULL OR UPPER(DBMS_LOB.SUBSTR(sql_text, 1000)) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
   AND ('&&sql_id.' IS NULL OR sql_id = '&&sql_id.')
   AND command_type NOT IN (SELECT action FROM audit_actions WHERE name IN ('PL/SQL EXECUTE', 'EXECUTE PROCEDURE'))
),
all_sql_with_type AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, sql_text, 
       SUBSTR(CASE WHEN sql_text LIKE '/*'||CHR(37) THEN SUBSTR(sql_text, 1, INSTR(sql_text, '*/') + 1) ELSE sql_text END, 1, 100) sql_text_100,
       application_category(sql_text) application_module
  FROM all_sql
),
my_tx_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, MAX(sql_text) sql_text, MAX(sql_text_100) sql_text_100, MAX(application_module) application_module
  FROM all_sql_with_type
 WHERE application_module IS NOT NULL
   AND (  
         (NVL('&&kiev_tx.', 'CBSGU') LIKE CHR(37)||'C'||CHR(37) AND application_module = 'CommitTx') OR
         (NVL('&&kiev_tx.', 'CBSGU') LIKE CHR(37)||'B'||CHR(37) AND application_module = 'BeginTx') OR
         (NVL('&&kiev_tx.', 'CBSGU') LIKE CHR(37)||'S'||CHR(37) AND application_module = 'Scan') OR
         (NVL('&&kiev_tx.', 'CBSGU') LIKE CHR(37)||'G'||CHR(37) AND application_module = 'GC') OR
         (NVL('&&kiev_tx.', 'CBSGU') LIKE CHR(37)||'U'||CHR(37) AND application_module = 'Unknown')
       )
 GROUP BY
       sql_id
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
   AND h.sql_id IN (SELECT t.sql_id FROM my_tx_sql t)
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
   AND h.con_dbid > 0
   AND h.sql_id IN (SELECT t.sql_id FROM my_tx_sql t)
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
       SUM(CASE WHEN tn.rank IS NULL THEN tn.value ELSE 0 END) top_00, -- all but top
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
       SUM(CASE tn.rank WHEN 12 THEN tn.value ELSE 0 END) top_12 -- consistent with tn.value on top_n
       /*
       SUM(CASE tn.rank WHEN 13 THEN tn.value ELSE 0 END) top_13,
       SUM(CASE tn.rank WHEN 14 THEN tn.value ELSE 0 END) top_14,
       SUM(CASE tn.rank WHEN 15 THEN tn.value ELSE 0 END) top_15,
       SUM(CASE tn.rank WHEN 16 THEN tn.value ELSE 0 END) top_16,
       SUM(CASE tn.rank WHEN 17 THEN tn.value ELSE 0 END) top_17,
       SUM(CASE tn.rank WHEN 18 THEN tn.value ELSE 0 END) top_18,
       SUM(CASE tn.rank WHEN 19 THEN tn.value ELSE 0 END) top_19,
       SUM(CASE tn.rank WHEN 20 THEN tn.value ELSE 0 END) sql_20 -- consistent with tn.value on top_n
       */
  FROM sqlstat_top_and_null tn
 GROUP BY
       tn.snap_id
),
sql_list AS (
SELECT /*+ MATERIALIZE NO_MERGE FULL(rs) */
       rs.rank,
       ',''#'||LPAD(rs.rank,2,'0')||' '||
       (CASE WHEN '&&sql_id.' IS NULL THEN rs.sql_id ELSE TO_CHAR(rs.plan_hash_value) END)||
       (CASE '&&cs_con_name.' WHEN 'CDB$ROOT' THEN ' '||c.name END)||'''' line
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
       ',''#'||LPAD(LEVEL,2,'0')||'''' line
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
       ','||ROUND(t.top_00,3)||
       ','||ROUND(t.top_01,3)||
       ','||ROUND(t.top_02,3)||
       ','||ROUND(t.top_03,3)||
       ','||ROUND(t.top_04,3)||
       ','||ROUND(t.top_05,3)||
       ','||ROUND(t.top_06,3)||
       ','||ROUND(t.top_07,3)||
       ','||ROUND(t.top_08,3)||
       ','||ROUND(t.top_09,3)||
       ','||ROUND(t.top_10,3)||
       ','||ROUND(t.top_11,3)||
       ','||ROUND(t.top_12,3)||
       /*
       ','||ROUND(t.top_13,3)||
       ','||ROUND(t.top_14,3)||
       ','||ROUND(t.top_15,3)||
       ','||ROUND(t.top_16,3)||
       ','||ROUND(t.top_17,3)||
       ','||ROUND(t.top_18,3)||
       ','||ROUND(t.top_19,3)||
       ','||ROUND(t.sql_20,3)||
       */
       ']' line
  FROM sqlstat_top t,
       snapshots s /* dba_hist_snapshot */
 WHERE s.snap_id = t.snap_id
 ORDER BY
       t.snap_id
)
/****************************************************************************************/
SELECT line FROM sql_list
 UNION ALL
SELECT line FROM sql_list_part_2
 UNION ALL
SELECT ']' line FROM DUAL
 UNION ALL
SELECT line FROM data_list
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area]
DEF cs_chart_type = 'Area';
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO scp &&cs_host_name.:&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name._*.html &&cs_local_dir.
PRO scp &&cs_host_name.:&&cs_file_prefix._*_&&cs_reference_sanitized._*.* &&cs_local_dir.
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&computed_metric." "&&kiev_tx." "&&sql_text_piece." "&&sql_id."
--