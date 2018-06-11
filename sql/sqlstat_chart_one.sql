----------------------------------------------------------------------------------------
--
-- File name:   sqlstat_chart_one.sql
--
--              *** Requires Oracle Diagnostics Pack License ***
--
-- Purpose:     Charts a metric group for a set of SQL statements matching filters
--
-- Author:      Carlos Sierra
--
-- Version:     2018/05/19
--
-- Usage:       Execute connected into the CDB or PDB of interest.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sqlstat_chart_one.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
--              *** Requires Oracle Diagnostics Pack License ***
--
---------------------------------------------------------------------------------------
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--

DEF default_awr_days = '14';
DEF date_format = 'YYYY-MM-DD"T"HH24:MI:SS';

SET HEA ON LIN 1000 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL dbid NEW_V dbid NOPRI;
COL db_name NEW_V db_name NOPRI;
SELECT dbid, LOWER(name) db_name FROM v$database
/

COL instance_number NEW_V instance_number NOPRI;
COL host_name NEW_V host_name NOPRI;
SELECT instance_number, LOWER(host_name) host_name FROM v$instance
/

COL con_name NEW_V con_name NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') con_name FROM DUAL
/

COL con_id NEW_V con_id NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_ID') con_id FROM DUAL
/

PRO
PRO Metric Group
PRO ~~~~~~~~~~~~
PRO latency    : ET, CPU, IO, Appl and Conc Times per Exec
PRO db_time    : ET, CPU, IO, Appl and Conc Times as AAS
PRO calls      : Parse, Execution and Fetch counts
PRO rows_sec   : Rows Processed per Sec
PRO rows_exec  : Rows Processed per Exec
PRO reads_sec  : Buffer Gets and Disk Reads per Second
PRO reads_exec : Buffer Gets and Disk Reads per Exec
PRO cursors    : Loads, Invalidations and Version Count
PRO memory     : Sharable Memory
PRO
PRO 1. Metric Group: [{latency}|<metric_group>]
DEF metric_group = '&1.';

COL metric_group NEW_V metric_group NOPRI;
SELECT LOWER(NVL('&&metric_group.', 'latency')) metric_group FROM DUAL
/

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

PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO
PRO 2. KIEV Transaction: [{CBSGU}|C|B|S|G|U|CB|SG] (C=CommitTx B=BeginTx S=Scan G=GC U=Unknown)
DEF kiev_tx = '&2.';

COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT NVL('&&kiev_tx.', 'CBSGU') kiev_tx FROM DUAL
/

PRO
PRO Filtering SQL to reduce search space.
PRO Enter additional SQL Text filtering, such as Table name or SQL Text piece
PRO
PRO 3. SQL Text piece (optional):
DEF sql_text_piece = '&3.';

PRO
PRO 4. Enter SQL_ID (optional):
DEF sql_id = '&4.';

PRO
PRO 5. Enter Plan Hash Value (optional):
DEF phv = '&5.';

PRO
PRO 6. Enter Parsing Schema Name (optional):
DEF parsing_schema_name = '&6.';

COL locale NEW_V locale NOPRI;
SELECT LOWER(REPLACE(SUBSTR('&&host_name.', 1 + INSTR('&&host_name.', '.', 1, 2), 30), '.', '_')) locale FROM DUAL
/

COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'sqlstat_&&locale._&&db_name._'||REPLACE('&&con_name.','$')||(CASE WHEN '&&kiev_tx.' IS NOT NULL THEN REPLACE('_&&kiev_tx.', ' ') END)||(CASE WHEN '&&sql_text_piece.' IS NOT NULL THEN REPLACE('_&&sql_text_piece.', ' ') END)||(CASE WHEN '&&sql_id.' IS NOT NULL THEN '_&&sql_id.' END)||(CASE WHEN '&&phv.' IS NOT NULL THEN '_&&phv.' END)||(CASE WHEN '&&parsing_schema_name.' IS NOT NULL THEN '_&&parsing_schema_name.' END)||'_&&metric_group._'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM DUAL
/

PRO
DEF report_title = "&&report_title.";
DEF report_abstract_1 = "LOCALE: &&locale.";
DEF report_abstract_2 = "<br>DATABASE: &&db_name.";
DEF report_abstract_3 = "<br>PDB: &&con_name.";
DEF report_abstract_4 = "<br>HOST: &&host_name.";
DEF report_abstract_5 = "<br>KIEV Transaction: &&kiev_tx.";
DEF report_abstract_6 = "<br>SQL Text: &&sql_text_piece.";
DEF report_abstract_7 = "<br>SQL_ID: &&sql_id.";
DEF report_abstract_8 = "<br>PHV: &&phv.";
DEF report_abstract_9 = "<br>SCHEMA: &&parsing_schema_name.";
DEF chart_title = "&&report_title.";
DEF xaxis_title = "";
DEF vaxis_title = "&&vaxis_title.";
DEF vaxis_baseline = "";
DEF chart_foot_note_1 = "<br>1) Drag to Zoom, and right click to reset Chart.";
DEF chart_foot_note_2 = "<br>2) Expect lower values than OEM Top Activity since only a subset of SQL is captured into dba_hist_sqlstat.";
DEF chart_foot_note_3 = "<br>3) PL/SQL executions are excluded since they distort charts.";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "&&output_file_name..html based on dba_hist_sqlstat";
PRO
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';

SPO &&output_file_name..html;
PRO <html>
PRO <!-- $Header: line_chart.sql 2014-07-27 carlos.sierra $ -->
PRO <head>
PRO <title>&&output_file_name..html</title>
PRO
PRO <style type="text/css">
PRO body             {font:10pt Arial,Helvetica,Geneva,sans-serif; color:black; background:white;}
PRO h1               {font-size:16pt; font-weight:bold; color:#336699; border-bottom:1px solid #336699; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;}
PRO h2               {font-size:14pt; font-weight:bold; color:#336699; margin-top:4pt; margin-bottom:0pt;}
PRO h3               {font-size:12pt; font-weight:bold; color:#336699; margin-top:4pt; margin-bottom:0pt;}
PRO pre              {font:8pt monospace,Monaco,"Courier New",Courier;}
PRO a                {color:#663300;}
PRO table            {font-size:8pt; border-collapse:collapse; empty-cells:show; white-space:nowrap; border:1px solid #336699;}
PRO li               {font-size:8pt; color:black; padding-left:4px; padding-right:4px; padding-bottom:2px;}
PRO th               {font-weight:bold; color:white; background:#0066CC; padding-left:4px; padding-right:4px; padding-bottom:2px;}
PRO tr               {color:black; background:white;}
PRO tr:hover         {color:white; background:#0066CC;}
PRO tr.main          {color:black; background:white;}
PRO tr.main:hover    {color:black; background:white;}
PRO td               {vertical-align:top; border:1px solid #336699;}
PRO td.c             {text-align:center;}
PRO font.n           {font-size:8pt; font-style:italic; color:#336699;}
PRO font.f           {font-size:8pt; color:#999999; border-top:1px solid #336699; margin-top:30pt;}
PRO div.google-chart {width:809px; height:500px;}
PRO </style>
PRO
PRO <script type="text/javascript" src="https://www.google.com/jsapi"></script>
PRO <script type="text/javascript">
PRO google.load("visualization", "1", {packages:["corechart"]})
PRO google.setOnLoadCallback(drawChart)
PRO
PRO function drawChart() {
PRO var data = google.visualization.arrayToDataTable([
PRO [
PRO 'Date Column'
SET HEA OFF PAGES 0;
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
   AND command_type NOT IN (SELECT action FROM audit_actions WHERE name IN ('PL/SQL EXECUTE', 'EXECUTE PROCEDURE'))
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
 WHERE s.dbid = &&dbid.
   AND s.instance_number = &&instance_number.
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
 WHERE h.dbid = &&dbid.
   AND h.instance_number = &&instance_number.
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

PRO ]);
PRO
PRO var options = {isStacked: true,
PRO chartArea:{left:90, top:75, width:'65%', height:'70%'},
PRO backgroundColor: {fill: 'white', stroke: '#336699', strokeWidth: 1},
PRO explorer: {actions: ['dragToZoom', 'rightClickToReset'], maxZoomIn: 0.01},
PRO title: '&&chart_title.',
PRO titleTextStyle: {fontSize: 18, bold: false},
PRO focusTarget: 'category',
PRO legend: {position: 'right', textStyle: {fontSize: 14}},
PRO tooltip: {textStyle: {fontSize: 14}},
PRO hAxis: {title: '&&xaxis_title.', gridlines: {count: -1}, titleTextStyle: {fontSize: 16, bold: false}},
PRO series: { 0: { color :'#34CF27'}, 1: { color :'#0252D7'},  2: { color :'#1E96DD'},  3: { color :'#CEC3B5'},  4: { color :'#EA6A05'},  5: { color :'#871C12'},  6: { color :'#C42A05'}, 7: {color :'#75763E'},
PRO 8: { color :'#594611'}, 9: { color :'#989779'}, 10: { color :'#C6BAA5'}, 11: { color :'#9FFA9D'}, 12: { color :'#F571A0'}, 13: { color :'#000000'}, 14: { color :'#ff0000'}},
PRO vAxis: {title: '&&vaxis_title.' &&vaxis_baseline., gridlines: {count: -1}, titleTextStyle: {fontSize: 16, bold: false}}
PRO }
PRO
PRO var chart = new google.visualization.LineChart(document.getElementById('chart_div'))
PRO chart.draw(data, options)
PRO }
PRO </script>
PRO </head>
PRO <body>
PRO <h1>&&report_title.</h1>
PRO &&report_abstract_1.
PRO &&report_abstract_2.
PRO &&report_abstract_3.
PRO &&report_abstract_4.
PRO &&report_abstract_5.
PRO &&report_abstract_6.
PRO &&report_abstract_7.
PRO &&report_abstract_8.
PRO &&report_abstract_9.
PRO <div id="chart_div" class="google-chart"></div>
PRO <font class="n">Notes:</font>
PRO <font class="n">&&chart_foot_note_1.</font>
PRO <font class="n">&&chart_foot_note_2.</font>
PRO <font class="n">&&chart_foot_note_3.</font>
PRO <font class="n">&&chart_foot_note_4.</font>
--PRO <pre>
--L
--PRO </pre>
PRO <br>
PRO <font class="f">&&report_foot_note.</font>
PRO </body>
PRO </html>
SPO OFF;
PRO
PRO &&output_file_name..html
PRO
CL COL;
UNDEF 1 2 3 4 5;
