DEF metric_group = '&1.';
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name._&&metric_group.' cs_file_name FROM DUAL;
--
COL report_title NEW_V report_title NOPRI;
COL vaxis_title NEW_V vaxis_title NOPRI;
SELECT CASE '&&metric_group.'
       WHEN 'latency' THEN 'Database Latency (avg)'
       WHEN 'db_time' THEN 'Database Time (avg)'
       WHEN 'calls' THEN 'Database Calls per Second (avg)'
       WHEN 'rows_sec' THEN 'Rows Processed per Second (avg)'
       WHEN 'rows_exec' THEN 'Rows Processed per Execution (avg)'
       WHEN 'reads_sec' THEN 'Logical and Physical Reads per Second (avg)'
       WHEN 'reads_exec' THEN 'Logical and Physical Reads per Execution (avg)'
       WHEN 'cursors' THEN 'Loads, Invalidations and Version Count (avg)'
       WHEN 'memory' THEN 'Sharable Memory (avg)'
       END report_title,
       CASE '&&metric_group.'
       WHEN 'latency' THEN 'ms (per execution)'
       WHEN 'db_time' THEN 'Average Active Sessions (AAS)'
       WHEN 'calls' THEN 'Calls Count per Second'
       WHEN 'rows_sec' THEN 'Rows Processed'
       WHEN 'rows_exec' THEN 'Rows Processed'
       WHEN 'reads_sec' THEN 'Reads per Second'
       WHEN 'reads_exec' THEN 'Reads per Execution'
       WHEN 'cursors' THEN 'Count'
       WHEN 'memory' THEN 'MBs'
       END vaxis_title
  FROM DUAL
/
--
DEF report_title = "&&report_title. &&sql_text_piece. &&sql_id. &&phv. &&parsing_schema_name.";
DEF chart_title = "&&report_title.";
DEF xaxis_title = "";
DEF vaxis_title = "&&vaxis_title.";
--
DEF vaxis_baseline = "";;
DEF chart_foot_note_2 = "<br>2) Expect lower values than OEM Top Activity since only a subset of SQL is captured into dba_hist_sqlstat.";
DEF chart_foot_note_3 = "<br>3) PL/SQL executions are excluded since they distort charts.";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "&&cs_script_name..sql";
--
@@cs_internal/cs_spool_head_chart.sql
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
SELECT 
CASE '&&metric_group.' 
WHEN 'latency' THEN 
q'[// &&metric_group.
,'DB Time'
,'CPU Time'
,'User IO Time'
,'Application (LOCK)'
,'Concurrency Time' ]'
WHEN 'db_time' THEN 
q'[// &&metric_group.
,'DB Time'
,'CPU Time'
,'User IO Time'
,'Application (LOCK)'
,'Concurrency Time' ]'
WHEN 'calls' THEN 
q'[// &&metric_group.
,'Parses'
,'Executions'
,'Fetches' ]'
WHEN 'rows_sec' THEN 
q'[// &&metric_group.
,'Rows Processed' ]'
WHEN 'rows_exec' THEN 
q'[// &&metric_group.
,'Rows Processed' ]'
WHEN 'reads_sec' THEN 
q'[// &&metric_group.
,'Buffer Gets'
,'Disk Reads' ]'
WHEN 'reads_exec' THEN 
q'[// &&metric_group.
,'Buffer Gets'
,'Disk Reads' ]'
WHEN 'cursors' THEN 
q'[// &&metric_group.
,'Loads'
,'Invalidations'
,'Version Count' ]'
WHEN 'memory' THEN 
q'[// &&metric_group.
,'Sharable Memory' ]'
END FROM DUAL
/
PRO // please wait... getting &&metric_group....
PRO ]
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
    ELSIF p_sql_text LIKE k_appl_handle_prefix||'SPM:CP'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'findMatchingRow'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'readTransactionsSince'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'writeTransactionKeys'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'setValueByUpdate'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'setValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'deleteValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'exists'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'existsUnique'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'updateIdentityValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE 'LOCK TABLE'||CHR(37) 
      OR  p_sql_text LIKE '/* null */ LOCK TABLE'||CHR(37)
      OR  p_sql_text LIKE k_appl_handle_prefix||'getTransactionProgress'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'recordTransactionState'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'checkEndRowValid'||k_appl_handle_suffix
      OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionCommitID'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_2;
    ELSIF p_sql_text LIKE k_appl_handle_prefix||'getValues'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getNextIdentityValue'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performScanQuery'||k_appl_handle_suffix
      OR  p_sql_text LIKE k_appl_handle_prefix||'performSnapshotScanQuery'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performFirstRowsScanQuery'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performStartScanValues'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'performContinuedScanValues'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'bucketIndexSelect'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'bucketKeySelect'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'selectBuckets'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getAutoSequences'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'bucketValueSelect'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'countTransactions'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Fetch snapshots'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_3;
    ELSIF p_sql_text LIKE k_appl_handle_prefix||'populateBucketGCWorkspace'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'deleteBucketGarbage'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Populate workspace'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage fOR  transaction GC'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Delete garbage in KTK GC'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'hashBucket'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'validateIfWorkspaceEmpty'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getGCLogEntries'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventTryInsert'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'countAllRows'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'Delete rows from'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'hashSnapshot'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'countKtkRows'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'gcEventMaxId'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'secondsSinceLastGcEvent'||k_appl_handle_suffix 
      OR  p_sql_text LIKE k_appl_handle_prefix||'getMaxTransactionOlderThan'||k_appl_handle_suffix 
    THEN RETURN gk_appl_cat_4;
    ELSE RETURN 'Unknown';
    END IF;
  END application_category;
all_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT sql_id, plan_hash_value, command_type, sql_text 
  FROM v$sql
 WHERE 1 = 1
   AND ('&&sql_text_piece.' IS NULL OR UPPER(sql_text) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
   AND ('&&sql_id.' IS NULL OR sql_id = '&&sql_id.') 
   --AND ('&&phv.' IS NULL OR plan_hash_value = TO_NUMBER('&&phv.'))
   --AND ('&&parsing_schema_name.' IS NULL OR parsing_schema_name = UPPER('&&parsing_schema_name.'))
),
all_sql_with_type AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, plan_hash_value, command_type, sql_text, 
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
   --AND command_type NOT IN (SELECT action FROM audit_actions WHERE name IN ('PL/SQL EXECUTE', 'EXECUTE PROCEDURE'))
   --AND ('&&sql_text_piece.' IS NULL OR UPPER(sql_text) LIKE CHR(37)||UPPER('&&sql_text_piece.')||CHR(37))
   --AND ('&&sql_id.' IS NULL OR sql_id = '&&sql_id.') 
   --AND ('&&phv.' IS NULL OR plan_hash_value = TO_NUMBER('&&phv.'))
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
  FROM dba_hist_sqlstat h /* sys.wrh$_sqlstat */
 WHERE h.dbid = &&cs_dbid.
   AND h.instance_number = &&cs_instance_number.
   AND h.con_dbid > 0
   AND ('&&sql_id.' IS NULL OR h.sql_id = '&&sql_id.') 
   AND ('&&phv.' IS NULL OR h.plan_hash_value = TO_NUMBER('&&phv.'))
   AND ('&&parsing_schema_name.' IS NULL OR h.parsing_schema_name = UPPER('&&parsing_schema_name.'))
   AND h.sql_id IN (SELECT t.sql_id FROM my_tx_sql t)
 GROUP BY
       h.snap_id
),
sqlstat_time_series AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.snap_id,
       s.end_date_time,
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
       ROUND(SUM(h.disk_reads_delta)/GREATEST(SUM(h.executions_delta),1),3) disk_reads_exec
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
         WHEN 'latency' THEN
           ','||q.db_time_exec|| 
           ','||q.cpu_time_exec|| 
           ','||q.io_time_exec|| 
           ','||q.appl_time_exec|| 
           ','||q.conc_time_exec
         WHEN 'db_time' THEN
           ','||q.db_time_aas|| 
           ','||q.cpu_time_aas|| 
           ','||q.io_time_aas|| 
           ','||q.appl_time_aas|| 
           ','||q.conc_time_aas
         WHEN 'calls' THEN
           ','||q.parses_sec|| 
           ','||q.executions_sec|| 
           ','||q.fetches_sec
         WHEN 'rows_sec' THEN
           ','||q.rows_processed_sec
         WHEN 'rows_exec' THEN
           ','||q.rows_processed_exec
         WHEN 'reads_sec' THEN
           ','||q.buffer_gets_sec|| 
           ','||q.disk_reads_sec
         WHEN 'reads_exec' THEN
           ','||q.buffer_gets_exec|| 
           ','||q.disk_reads_exec
         WHEN 'cursors' THEN
           ','||q.loads|| 
           ','||q.invalidations|| 
           ','||q.version_count
         WHEN 'memory' THEN
           ','||q.sharable_mem_mb
       END||
       ']'
  FROM sqlstat_time_series q
 ORDER BY
       q.end_date_time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
DEF cs_chart_type = 'Line';
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO scp &&cs_host_name.:&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name._*.html &&cs_local_dir.
PRO scp &&cs_host_name.:&&cs_file_prefix._*_&&cs_reference_sanitized._*.* &&cs_local_dir.
--
PRO
PRO SQL> @&&cs_script_name..sql "&&metric_group." "&&kiev_tx." "&&sql_text_piece." "&&sql_id." "&&phv." "&&parsing_schema_name."
--