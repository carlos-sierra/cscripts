----------------------------------------------------------------------------------------
--
-- File name:   top_report_one.sql
--
--              *** Requires Oracle Diagnostics Pack License ***
--
-- Purpose:     Reports top SQL (as per a computed metric) for given time range
--              If a SQL_ID is passed into optional parameter, then reports top Plans
--
-- Author:      Carlos Sierra
--
-- Version:     2018/06/05
--
-- Usage:       Execute connected into the CDB or PDB of interest.
--
--              Enter range of AWR snapshot (optional), and metric of interest (optional)
--              Dafaults to last day of AWR and to db_time_exec (Latency - DB per Exec)
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @top_report_one.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
--              To further dive into SQL performance diagnostics use SQLd360.
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
-- warn if executed from CDB$ROOT
--WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN
    raise_application_error(-20000, 'Be aware! You are executing this script connected into CDB$ROOT.');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;

DEF top_n = '12';
DEF default_window_hours = '24';
DEF default_awr_days = '30';
DEF date_format = 'YYYY-MM-DD"T"HH24:MI:SS';

SET HEA ON LIN 1000 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET LONG 32000 LONGC 200;

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
PRO Only used to limit the list of snapshots from where we can select TOP SQL bounds.
PRO Default value is usually right.
PRO
PRO 1. Display AWR Days: [{&&default_awr_days.}|1-60]
DEF display_awr_days = '&1.';

COL display_awr_days NEW_V display_awr_days NOPRI;
SELECT NVL('&&display_awr_days.', '&&default_awr_days.') display_awr_days FROM DUAL
/

COL oldest_snap_id NEW_V oldest_snap_id NOPRI;
SELECT TO_CHAR(MAX(snap_id)) oldest_snap_id 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND end_interval_time < SYSDATE - &&display_awr_days.
/
SELECT NVL('&&oldest_snap_id.', TO_CHAR(MIN(snap_id))) oldest_snap_id 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
/

SELECT snap_id, 
       TO_CHAR(begin_interval_time, '&&date_format.') begin_time, 
       TO_CHAR(end_interval_time, '&&date_format.') end_time
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND snap_id >= &&oldest_snap_id.
 ORDER BY
       snap_id
/

COL snap_id_max_default NEW_V snap_id_max_default NOPRI;
SELECT TO_CHAR(NVL(TO_NUMBER(''), MAX(snap_id))) snap_id_max_default 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
/

COL snap_id_min_default NEW_V snap_id_min_default NOPRI;
SELECT TO_CHAR(NVL(TO_NUMBER(''), MAX(snap_id))) snap_id_min_default 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND ( CASE 
         WHEN '' IS NULL 
         THEN ( CASE 
                WHEN begin_interval_time < (SYSDATE - (TO_NUMBER(NVL('&&default_window_hours.', '0'))/24))
                THEN 1 
                ELSE 0 
                END
              ) 
         ELSE 1 
         END
       ) = 1
/

PRO
PRO Range of snaps below are to define lower and upper bounds to compute TOP SQL.
PRO
PRO Enter range of snaps to evaluate TOP SQL. Default is last &&default_window_hours. hours.
PRO
PRO 2. SNAP_ID FROM: [{&&snap_id_min_default.}|snap_id]
DEF snap_id_from = '&2.';
PRO
PRO 3. SNAP_ID TO: [{&&snap_id_max_default.}|snap_id]
DEF snap_id_to = '&3.';

COL snap_id_max NEW_V snap_id_max NOPRI;
SELECT TO_CHAR(NVL(TO_NUMBER('&&snap_id_to.'), MAX(snap_id))) snap_id_max 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
/

COL snap_id_min NEW_V snap_id_min NOPRI;
SELECT TO_CHAR(NVL(TO_NUMBER('&&snap_id_from.'), MAX(snap_id))) snap_id_min 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND ( CASE 
         WHEN '&&snap_id_from.' IS NULL 
         THEN ( CASE 
                WHEN begin_interval_time < (SYSDATE - (TO_NUMBER(NVL('&&default_window_hours.', '0'))/24))
                THEN 1 
                ELSE 0 
                END
              ) 
         ELSE 1 
         END
       ) = 1
/

COL begin_interval_time NEW_V begin_interval_time NOPRI;
SELECT TO_CHAR(begin_interval_time, '&&date_format.') begin_interval_time
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND snap_id = &&snap_id_min.
/

COL end_interval_time NEW_V end_interval_time NOPRI;
SELECT TO_CHAR(end_interval_time, '&&date_format.') end_interval_time
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND snap_id = &&snap_id_max.
/

PRO
PRO Top SQL is computed for selected metric within range of snaphots.
PRO
PRO Computed Metric
PRO ~~~~~~~~~~~~~~~
PRO db_time_exec        : Latency   - Database Time per Exec - (MS)
PRO cpu_time_exec       : Latency   - CPU Time per Exec - (MS)
PRO io_time_exec        : Latency   - IO Wait Time per Exec - (MS)
PRO appl_time_exec      : Latency   - Application Wait Time per Exec - (MS)
PRO conc_time_exec      : Latency   - Concurrency Wait Time per Exec - (MS)
PRO db_time_aas         : DB Time   - Elapsed Time - (AAS)
PRO cpu_time_aas        : DB Time   - CPU Time - (AAS)
PRO io_time_aas         : DB Time   - IO Wait Time - (AAS)
PRO appl_time_aas       : DB Time   - Application Wait Time - (AAS)
PRO conc_time_aas       : DB Time   - Concurrency Wait Time - (AAS)
PRO parses_sec          : Calls     - Parses per Second - Calls
PRO executions_sec      : Calls     - Execs per Second - Calls
PRO fetches_sec         : Calls     - Fetches per Second - Calls
PRO rows_processed_sec  : Resources - Rows Processed per Second - Count
PRO buffer_gets_sec     : Resources - Buffer Gets    per Second - Count
PRO disk_reads_sec      : Resources - Disk Reads     per Second - Count
PRO rows_processed_exec : Resources - Rows Processed per Exec - Count
PRO buffer_gets_exec    : Resources - Buffer Gets    per Exec - Count
PRO disk_reads_exec     : Resources - Disk Reads     per Exec - Count
PRO loads               : Cursors   - Loads - Count
PRO invalidations       : Cursors   - Invalidations - Count
PRO version_count       : Cursors   - Versions - Count
PRO sharable_mem_mb     : Cursors   - Sharable Memory - (MBs)
PRO
PRO 4. Computed Metric: [{db_time_exec}|<computed_metric>]
DEF computed_metric = '&4.';

COL computed_metric NEW_V computed_metric NOPRI;
SELECT LOWER(NVL('&&computed_metric.', 'db_time_exec')) computed_metric FROM DUAL
/

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
       ELSE 'Database Time per Execution'
       END metric_display
  FROM DUAL
/

PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO
PRO 5. KIEV Transaction: [{CBSGU}|C|B|S|G|U|CB|SG] (C=CommitTx B=BeginTx S=Scan G=GC U=Unknown)
DEF kiev_tx = '&5.';

COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT NVL('&&kiev_tx.', 'CBSGU') kiev_tx FROM DUAL
/

PRO
PRO Filtering SQL to reduce search space.
PRO Enter additional SQL Text filtering, such as Table name or SQL Text piece
PRO
PRO 6. SQL Text piece (optional):
DEF sql_text_piece = '&6.';

PRO
PRO Filtering SQL to reduce search space.
PRO By entering an optional SQL_ID, scope changes from TOP SQL to TOP Plans
PRO
PRO 7. SQL_ID (optional):
DEF sql_id = '&7.';

COL top_what NEW_V top_what NOPRI;
SELECT CASE WHEN '&&sql_id.' IS NULL THEN 'SQL' ELSE 'Plans' END top_what FROM DUAL
/

COL locale NEW_V locale NOPRI;
SELECT LOWER(REPLACE(SUBSTR('&&host_name.', 1 + INSTR('&&host_name.', '.', 1, 2), 30), '.', '_')) locale FROM DUAL
/

COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'top_'||LOWER('&&top_what.')||'_&&locale._&&db_name._'||REPLACE('&&con_name.','$')||(CASE WHEN '&&kiev_tx.' IS NOT NULL THEN TRIM('_&&kiev_tx.') END)||(CASE WHEN '&&sql_text_piece.' IS NOT NULL THEN REPLACE('_&&sql_text_piece.',' ') END)||(CASE WHEN '&&sql_id.' IS NOT NULL THEN '_&&sql_id.' END)||'_&&snap_id_min._&&snap_id_max._&&computed_metric.' output_file_name FROM DUAL
/

COL rank FOR 9999 HEA 'TOP';
COL con_id FOR 999 HEA 'PDB|ID';
COL pdb_name FOR A30;
COL plan_hash_value_c FOR A10 HEA 'PLAN|HASH VALUE';
COL db_time_exec FOR 999,999,990.000 HEA 'DB TIME|MILLISECONDS|PER EXEC';
COL db_time_aas FOR 9,990.000 HEA 'DB|TIME|(AAS)';
COL db_time_perc FOR 9,990.000 HEA 'DB|TIME|(PERC)';
COL cpu_time_exec FOR 999,999,990.000 HEA 'CPU TIME|MILLISECONDS|PER EXEC';
COL cpu_time_aas FOR 9,990.000 HEA 'CPU|TIME|(AAS)';
COL cpu_time_perc FOR 9,990.000 HEA 'CPU|TIME|(PERC)';
COL io_time_exec FOR 999,999,990.000 HEA 'IO TIME|MILLISECONDS|PER EXEC';
COL io_time_aas FOR 9,990.000 HEA 'IO|TIME|(AAS)';
COL io_time_perc FOR 9,990.000 HEA 'IO|TIME|(PERC)';
COL appl_time_exec FOR 999,999,990.000 HEA 'APPL TIME|MILLISECONDS|PER EXEC';
COL appl_time_aas FOR 9,990.000 HEA 'APPL|TIME|(AAS)';
COL appl_time_perc FOR 9,990.000 HEA 'APPL|TIME|(PERC)';
COL conc_time_exec FOR 999,999,990.000 HEA 'CONC TIME|MILLISECONDS|PER EXEC';
COL conc_time_aas FOR 9,990.000 HEA 'CONC|TIME|(AAS)';
COL conc_time_perc FOR 9,990.000 HEA 'CONC|TIME|(PERC)';
COL parses FOR 999,999,999,990 HEA 'PARSES|TOTAL';
COL parses_sec FOR 999,990.000 HEA 'PARSES|PER|SECOND';
COL parses_perc FOR 9,990.000 HEA 'PARSES|(PERC)';
COL executions FOR 999,999,999,990 HEA 'EXECUTIONS|TOTAL';
COL executions_sec FOR 999,990.000 HEA 'EXECS|PER|SECOND';
COL executions_perc FOR 9,990.000 HEA 'EXECS|(PERC)';
COL fetches FOR 999,999,999,990 HEA 'FETCHES|TOTAL';
COL fetches_sec FOR 999,990.000 HEA 'FETCHES|PER|SECOND';
COL fetches_perc FOR 9,990.000 HEA 'FETCHES|(PERC)';
COL loads FOR 999,990 HEA 'LOADS';
COL loads_perc FOR 9,990.000 HEA 'LOADS|(PERC)';
COL invalidations FOR 999,990 HEA 'INVALI-|DATIONS';
COL invalidations_perc FOR 9,990.000 HEA 'INVALI-|DATIONS|(PERC)';
COL version_count FOR 999,990 HEA 'VERSION|COUNT';
COL version_count_perc FOR 9,990.000 HEA 'VERSION|COUNT|(PERC)';
COL sharable_mem_mb FOR 9999,990 HEA 'SHARABLE|MEM|(MBs)';
COL sharable_mem_perc FOR 99,990.000 HEA 'SHARABLE|MEM|(PERC)';
COL rows_processed_sec FOR 999,999,990.000 HEA 'ROWS|PROCESSSED|PER SECOND';
COL rows_processed_exec FOR 999,999,990.000 HEA 'ROWS|PROCESSSED|PER EXEC';
COL rows_processed_perc FOR 9999,990.000 HEA 'ROWS|PROCESSSED|(PERC)';
COL buffer_gets_sec FOR 999,999,990.000 HEA 'BUFFER|GETS|PER SECOND';
COL buffer_gets_exec FOR 999,999,990.000 HEA 'BUFFER|GETS|PER EXEC';
COL buffer_gets_perc FOR 9,990.000 HEA 'BUFFER|GETS|(PERC)';
COL disk_reads_sec FOR 999,999,990.000 HEA 'DISK|READS|PER SECOND';
COL disk_reads_exec FOR 999,999,990.000 HEA 'DISK|READS|PER EXEC';
COL disk_reads_perc FOR 9,990.000 HEA 'DISK|READS|(PERC)';
COL sql_text_100 FOR A100 HEA 'SQL TEXT';
COL sql_text FOR A200;
COL application_module FOR A8 HEA 'KIEV TX';
COL min_plan_hash_value FOR 9999999999 HEA 'MIN PLAN|HASH VALUE';
COL max_plan_hash_value FOR 9999999999 HEA 'MAX PLAN|HASH VALUE';
-- consistent with top_n
DEF sql_id_01 = '';
DEF sql_id_02 = '';
DEF sql_id_03 = '';
DEF sql_id_04 = '';
DEF sql_id_05 = '';
DEF sql_id_06 = '';
DEF sql_id_07 = '';
DEF sql_id_08 = '';
DEF sql_id_09 = '';
DEF sql_id_10 = '';
DEF sql_id_11 = '';
DEF sql_id_12 = '';
COL sql_id_01 NEW_V sql_id_01 NOPRI;
COL sql_id_02 NEW_V sql_id_02 NOPRI;
COL sql_id_03 NEW_V sql_id_03 NOPRI;
COL sql_id_04 NEW_V sql_id_04 NOPRI;
COL sql_id_05 NEW_V sql_id_05 NOPRI;
COL sql_id_06 NEW_V sql_id_06 NOPRI;
COL sql_id_07 NEW_V sql_id_07 NOPRI;
COL sql_id_08 NEW_V sql_id_08 NOPRI;
COL sql_id_09 NEW_V sql_id_09 NOPRI;
COL sql_id_10 NEW_V sql_id_10 NOPRI;
COL sql_id_11 NEW_V sql_id_11 NOPRI;
COL sql_id_12 NEW_V sql_id_12 NOPRI;

BRE ON REPORT;
COMP SUM LABEL 'TOTAL' OF db_time_aas db_time_perc cpu_time_aas cpu_time_perc io_time_aas io_time_perc appl_time_aas appl_time_perc conc_time_aas conc_time_perc parses parses_sec parses_perc executions_sec executions executions_perc fetches fetches_sec fetches_perc loads loads_perc invalidations invalidations_perc version_count version_count_perc sharable_mem_mb sharable_mem_perc rows_processed_sec rows_processed_perc buffer_gets_sec buffer_gets_perc disk_reads_sec disk_reads_perc ON REPORT;
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';

SPO &&output_file_name..txt;
PRO
PRO SQL> @top_report_one.sql "&&display_awr_days." "&&snap_id_from." "&&snap_id_to." "&&computed_metric." "&&kiev_tx." "&&sql_text_piece." "&&sql_id."
PRO
PRO &&output_file_name..txt
PRO
PRO LOCALE   : &&locale.
PRO DATABASE : &&db_name.
PRO PDB      : &&con_name.
PRO HOST     : &&host_name.
PRO BEGIN    : &&begin_interval_time. (SNAP_ID &&snap_id_min.)
PRO END      : &&end_interval_time. (SNAP_ID &&snap_id_max.)
PRO METRIC   : &&computed_metric.
PRO KIEV Tx  : &&kiev_tx. (C=CommitTx B=BeginTx S=Scan G=GC U=Unknown)
PRO SQL TEXT : &&sql_text_piece.
PRO SQL_ID   : &&sql_id.
PRO
PRO Top &&top_what. by "&&metric_display."
PRO ~~~~~~~~~~
--
COL db_time_exec NOPRI;
COL cpu_time_exec NOPRI;
COL io_time_exec NOPRI;
COL appl_time_exec NOPRI;
COL conc_time_exec NOPRI;
--
COL db_time_aas NOPRI;
COL cpu_time_aas NOPRI;
COL io_time_aas NOPRI;
COL appl_time_aas NOPRI;
COL conc_time_aas NOPRI;
--
COL db_time_perc NOPRI;
COL cpu_time_perc NOPRI;
COL io_time_perc NOPRI;
COL appl_time_perc NOPRI;
COL conc_time_perc NOPRI;
--
COL parses NOPRI;
COL executions NOPRI;
COL fetches NOPRI;
--
COL parses_sec NOPRI;
COL executions_sec NOPRI;
COL fetches_sec NOPRI;
--
COL parses_perc NOPRI;
COL executions_perc NOPRI;
COL fetches_perc NOPRI;
--
COL loads NOPRI;
COL invalidations NOPRI;
COL version_count NOPRI;
--
COL loads_perc NOPRI;
COL invalidations_perc NOPRI;
COL version_count_perc NOPRI;
--
COL sharable_mem_mb NOPRI;
COL sharable_mem_perc NOPRI;
--
COL rows_processed_sec NOPRI;
COL buffer_gets_sec NOPRI;
COL disk_reads_sec NOPRI;
--
COL rows_processed_exec NOPRI;
COL buffer_gets_exec NOPRI;
COL disk_reads_exec NOPRI;
--
COL rows_processed_perc NOPRI;
COL buffer_gets_perc NOPRI;
COL disk_reads_perc NOPRI;
--
COL min_plan_hash_value PRI;
COL max_plan_hash_value PRI;
COL application_module PRI;
COL sql_text_100 PRI;
--
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
       REPLACE(SUBSTR(CASE WHEN sql_text LIKE '/*'||CHR(37) THEN SUBSTR(sql_text, 1, INSTR(sql_text, '*/') + 1) ELSE sql_text END, 1, 100), CHR(10), CHR(32)) sql_text_100,
       application_category(sql_text) application_module
  FROM all_sql
),
my_tx_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, MAX(sql_text) sql_text, MAX(sql_text_100) sql_text_100, MAX(application_module) application_module
  FROM all_sql_with_type
 WHERE application_module IS NOT NULL
  AND  (  
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
 WHERE s.dbid = &&dbid.
   AND s.instance_number = &&instance_number.
   AND s.snap_id BETWEEN &&snap_id_min. AND &&snap_id_max.
),
sqlstat AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.con_id,
       h.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END plan_hash_value,
       h.snap_id,
       MIN(h.plan_hash_value) min_plan_hash_value,
       MAX(h.plan_hash_value) max_plan_hash_value,
       SUM(h.elapsed_time_delta) elapsed_time_delta,
       SUM(h.cpu_time_delta) cpu_time_delta,
       SUM(h.iowait_delta) iowait_delta,
       SUM(h.apwait_delta) apwait_delta,
       SUM(h.ccwait_delta) ccwait_delta,
       SUM(h.parse_calls_delta) parse_calls_delta,
       SUM(h.executions_delta) executions_delta,
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
   AND h.snap_id BETWEEN &&snap_id_min. AND &&snap_id_max.
   AND h.sql_id IN (SELECT t.sql_id FROM my_tx_sql t)
 GROUP BY
       h.con_id,
       h.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END,
       h.snap_id
),
sqlstat_extended AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.con_id,
       h.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END plan_hash_value,
       MIN(h.min_plan_hash_value) min_plan_hash_value,
       MAX(h.max_plan_hash_value) max_plan_hash_value,
       --
       ROUND(100*SUM(h.elapsed_time_delta)/GREATEST(SUM(SUM(h.elapsed_time_delta)) OVER (),1),3) db_time_perc,
       ROUND(100*SUM(h.cpu_time_delta)/GREATEST(SUM(SUM(h.cpu_time_delta)) OVER (),1),3) cpu_time_perc,
       ROUND(100*SUM(h.iowait_delta)/GREATEST(SUM(SUM(h.iowait_delta)) OVER (),1),3) io_time_perc,
       ROUND(100*SUM(h.apwait_delta)/GREATEST(SUM(SUM(h.apwait_delta)) OVER (),1),3) appl_time_perc,
       ROUND(100*SUM(h.ccwait_delta)/GREATEST(SUM(SUM(h.ccwait_delta)) OVER (),1),3) conc_time_perc,
       ROUND(100*SUM(h.parse_calls_delta)/GREATEST(SUM(SUM(h.parse_calls_delta)) OVER (),1),3) parses_perc,
       ROUND(100*SUM(h.executions_delta)/GREATEST(SUM(SUM(h.executions_delta)) OVER (),1),3) executions_perc,
       ROUND(100*SUM(h.fetches_delta)/GREATEST(SUM(SUM(h.fetches_delta)) OVER (),1),3) fetches_perc,
       ROUND(100*SUM(h.loads_delta)/GREATEST(SUM(SUM(h.loads_delta)) OVER (),1),3) loads_perc,
       ROUND(100*SUM(h.invalidations_delta)/GREATEST(SUM(SUM(h.invalidations_delta)) OVER (),1),3) invalidations_perc,
       ROUND(100*MAX(h.version_count)/GREATEST(SUM(MAX(h.version_count)) OVER (),1),3) version_count_perc,
       ROUND(100*SUM(h.sharable_mem)/GREATEST(SUM(SUM(h.sharable_mem)) OVER (),1),3) sharable_mem_perc,
       ROUND(100*SUM(h.rows_processed_delta)/GREATEST(SUM(SUM(h.rows_processed_delta)) OVER (),1),3) rows_processed_perc,
       ROUND(100*SUM(h.buffer_gets_delta)/GREATEST(SUM(SUM(h.buffer_gets_delta)) OVER (),1),3) buffer_gets_perc,
       ROUND(100*SUM(h.disk_reads_delta)/GREATEST(SUM(SUM(h.disk_reads_delta)) OVER (),1),3) disk_reads_perc,
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
  FROM sqlstat h, /* dba_hist_sqlstat */
       snapshots s /* dba_hist_snapshot */
 WHERE s.snap_id = h.snap_id
 GROUP BY
       h.con_id,
       h.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END
),
sqlstat_ranked AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.con_id,
       h.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END plan_hash_value,
       h.min_plan_hash_value,
       h.max_plan_hash_value,
       h.db_time_exec,
       h.db_time_aas,
       h.db_time_perc,
       h.cpu_time_exec,
       h.cpu_time_aas,
       h.cpu_time_perc,
       h.io_time_exec,
       h.io_time_aas,
       h.io_time_perc,
       h.appl_time_exec,
       h.appl_time_aas,
       h.appl_time_perc,
       h.conc_time_exec,
       h.conc_time_aas,
       h.conc_time_perc,
       h.parses,
       h.parses_sec,
       h.parses_perc,
       h.executions,
       h.executions_sec,
       h.executions_perc,
       h.fetches,
       h.fetches_sec,
       h.fetches_perc,
       h.loads,
       h.loads_perc,
       h.invalidations,
       h.invalidations_perc,
       h.version_count,
       h.version_count_perc,
       h.sharable_mem_mb,
       h.sharable_mem_perc,
       h.rows_processed_sec,
       h.rows_processed_exec,
       h.rows_processed_perc,
       h.buffer_gets_sec,
       h.buffer_gets_exec,
       h.buffer_gets_perc,
       h.disk_reads_sec,
       h.disk_reads_exec,
       h.disk_reads_perc,
       ROW_NUMBER() OVER (ORDER BY h.&&computed_metric. DESC NULLS LAST, h.db_time_aas DESC NULLS LAST, h.executions_sec DESC NULLS LAST, h.rows_processed_sec DESC NULLS LAST, h.con_id, h.sql_id, CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END) rank
  FROM sqlstat_extended h
),
top_n AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.rank,
       h.con_id,
       h.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN -666 ELSE h.plan_hash_value END plan_hash_value,
       h.min_plan_hash_value,
       h.max_plan_hash_value,
       h.db_time_exec,
       h.db_time_aas,
       h.db_time_perc,
       h.cpu_time_exec,
       h.cpu_time_aas,
       h.cpu_time_perc,
       h.io_time_exec,
       h.io_time_aas,
       h.io_time_perc,
       h.appl_time_exec,
       h.appl_time_aas,
       h.appl_time_perc,
       h.conc_time_exec,
       h.conc_time_aas,
       h.conc_time_perc,
       h.parses,
       h.parses_sec,
       h.parses_perc,
       h.executions,
       h.executions_sec,
       h.executions_perc,
       h.fetches,
       h.fetches_sec,
       h.fetches_perc,
       h.loads,
       h.loads_perc,
       h.invalidations,
       h.invalidations_perc,
       h.version_count,
       h.version_count_perc,
       h.sharable_mem_mb,
       h.sharable_mem_perc,
       h.rows_processed_sec,
       h.rows_processed_exec,
       h.rows_processed_perc,
       h.buffer_gets_sec,
       h.buffer_gets_exec,
       h.buffer_gets_perc,
       h.disk_reads_sec,
       h.disk_reads_exec,
       h.disk_reads_perc
  FROM sqlstat_ranked h
 WHERE h.rank <= &&top_n.
),
top_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       rank,
       sql_id
  FROM top_n
)
SELECT t.rank,
       t.con_id,
       c.name pdb_name,
       t.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN (CASE WHEN t.min_plan_hash_value = t.max_plan_hash_value THEN TO_CHAR(t.max_plan_hash_value) ELSE 'MULTIPLE' END) ELSE TO_CHAR(t.plan_hash_value) END plan_hash_value_c,
       (SELECT sql_id FROM top_sql WHERE rank = 01) sql_id_01,
       (SELECT sql_id FROM top_sql WHERE rank = 02) sql_id_02,
       (SELECT sql_id FROM top_sql WHERE rank = 03) sql_id_03,
       (SELECT sql_id FROM top_sql WHERE rank = 04) sql_id_04,
       (SELECT sql_id FROM top_sql WHERE rank = 05) sql_id_05,
       (SELECT sql_id FROM top_sql WHERE rank = 06) sql_id_06,
       (SELECT sql_id FROM top_sql WHERE rank = 07) sql_id_07,
       (SELECT sql_id FROM top_sql WHERE rank = 08) sql_id_08,
       (SELECT sql_id FROM top_sql WHERE rank = 09) sql_id_09,
       (SELECT sql_id FROM top_sql WHERE rank = 10) sql_id_10,
       (SELECT sql_id FROM top_sql WHERE rank = 11) sql_id_11,
       (SELECT sql_id FROM top_sql WHERE rank = 12) sql_id_12,
       --
       t.db_time_exec,
       t.cpu_time_exec,
       t.io_time_exec,
       t.appl_time_exec,
       t.conc_time_exec,
       --
       t.db_time_aas,
       t.cpu_time_aas,
       t.io_time_aas,
       t.appl_time_aas,
       t.conc_time_aas,
       --
       t.db_time_perc,
       t.cpu_time_perc,
       t.io_time_perc,
       t.appl_time_perc,
       t.conc_time_perc,
       --
       t.parses,
       t.executions,
       t.fetches,
       --
       t.parses_sec,
       t.executions_sec,
       t.fetches_sec,
       --
       t.parses_perc,
       t.executions_perc,
       t.fetches_perc,
       --
       t.loads,
       t.invalidations,
       t.version_count,
       --
       t.loads_perc,
       t.invalidations_perc,
       t.version_count_perc,
       --
       t.sharable_mem_mb,
       t.sharable_mem_perc,
       --
       t.rows_processed_sec,
       t.buffer_gets_sec,
       t.disk_reads_sec,
       --
       t.rows_processed_exec,
       t.buffer_gets_exec,
       t.disk_reads_exec,
       --
       t.rows_processed_perc,
       t.buffer_gets_perc,
       t.disk_reads_perc,
       --
       CASE WHEN t.min_plan_hash_value = t.max_plan_hash_value THEN NULL ELSE t.min_plan_hash_value END min_plan_hash_value,
       CASE WHEN t.min_plan_hash_value = t.max_plan_hash_value THEN NULL ELSE t.max_plan_hash_value END max_plan_hash_value,
       s.application_module,
       s.sql_text_100,
       t.sql_id,
       CASE WHEN '&&sql_id.' IS NULL THEN (CASE WHEN t.min_plan_hash_value = t.max_plan_hash_value THEN TO_CHAR(t.max_plan_hash_value) ELSE 'MULTIPLE' END) ELSE TO_CHAR(t.plan_hash_value) END plan_hash_value_c
  FROM top_n t,
       v$containers c,
       my_tx_sql s
 WHERE c.con_id = t.con_id
   AND s.sql_id = t.sql_id
 ORDER BY
       t.rank
/

PRO
PRO Top &&top_what. by "&&metric_display." - SQL Latency, Average Active Sessions and Database Time
PRO ~~~~~~~~~~
--
COL db_time_exec PRI;
COL cpu_time_exec PRI;
COL io_time_exec PRI;
COL appl_time_exec PRI;
COL conc_time_exec PRI;
--
COL db_time_aas PRI;
COL cpu_time_aas PRI;
COL io_time_aas PRI;
COL appl_time_aas PRI;
COL conc_time_aas PRI;
--
COL db_time_perc PRI;
COL cpu_time_perc PRI;
COL io_time_perc PRI;
COL appl_time_perc PRI;
COL conc_time_perc PRI;
--
COL parses NOPRI;
COL executions NOPRI;
COL fetches NOPRI;
--
COL parses_sec NOPRI;
COL executions_sec NOPRI;
COL fetches_sec NOPRI;
--
COL parses_perc NOPRI;
COL executions_perc NOPRI;
COL fetches_perc NOPRI;
--
COL loads NOPRI;
COL invalidations NOPRI;
COL version_count NOPRI;
--
COL loads_perc NOPRI;
COL invalidations_perc NOPRI;
COL version_count_perc NOPRI;
--
COL sharable_mem_mb NOPRI;
COL sharable_mem_perc NOPRI;
--
COL rows_processed_sec NOPRI;
COL buffer_gets_sec NOPRI;
COL disk_reads_sec NOPRI;
--
COL rows_processed_exec NOPRI;
COL buffer_gets_exec NOPRI;
COL disk_reads_exec NOPRI;
--
COL rows_processed_perc NOPRI;
COL buffer_gets_perc NOPRI;
COL disk_reads_perc NOPRI;
--
COL min_plan_hash_value NOPRI;
COL max_plan_hash_value NOPRI;
COL application_module NOPRI;
COL sql_text_100 NOPRI;
--
/

PRO
PRO Top &&top_what. by "&&metric_display." - Database User Calls (Load)
PRO ~~~~~~~~~~
--
COL db_time_exec NOPRI;
COL cpu_time_exec NOPRI;
COL io_time_exec NOPRI;
COL appl_time_exec NOPRI;
COL conc_time_exec NOPRI;
--
COL db_time_aas NOPRI;
COL cpu_time_aas NOPRI;
COL io_time_aas NOPRI;
COL appl_time_aas NOPRI;
COL conc_time_aas NOPRI;
--
COL db_time_perc NOPRI;
COL cpu_time_perc NOPRI;
COL io_time_perc NOPRI;
COL appl_time_perc NOPRI;
COL conc_time_perc NOPRI;
--
COL parses PRI;
COL executions PRI;
COL fetches PRI;
--
COL parses_sec PRI;
COL executions_sec PRI;
COL fetches_sec PRI;
--
COL parses_perc PRI;
COL executions_perc PRI;
COL fetches_perc PRI;
--
COL loads NOPRI;
COL invalidations NOPRI;
COL version_count NOPRI;
--
COL loads_perc NOPRI;
COL invalidations_perc NOPRI;
COL version_count_perc NOPRI;
--
COL sharable_mem_mb NOPRI;
COL sharable_mem_perc NOPRI;
--
COL rows_processed_sec NOPRI;
COL buffer_gets_sec NOPRI;
COL disk_reads_sec NOPRI;
--
COL rows_processed_exec NOPRI;
COL buffer_gets_exec NOPRI;
COL disk_reads_exec NOPRI;
--
COL rows_processed_perc NOPRI;
COL buffer_gets_perc NOPRI;
COL disk_reads_perc NOPRI;
--
COL min_plan_hash_value NOPRI;
COL max_plan_hash_value NOPRI;
COL application_module NOPRI;
COL sql_text_100 NOPRI;
--
/

PRO
PRO Top &&top_what. by "&&metric_display." - Resources
PRO ~~~~~~~~~~
--
COL db_time_exec NOPRI;
COL cpu_time_exec NOPRI;
COL io_time_exec NOPRI;
COL appl_time_exec NOPRI;
COL conc_time_exec NOPRI;
--
COL db_time_aas NOPRI;
COL cpu_time_aas NOPRI;
COL io_time_aas NOPRI;
COL appl_time_aas NOPRI;
COL conc_time_aas NOPRI;
--
COL db_time_perc NOPRI;
COL cpu_time_perc NOPRI;
COL io_time_perc NOPRI;
COL appl_time_perc NOPRI;
COL conc_time_perc NOPRI;
--
COL parses NOPRI;
COL executions NOPRI;
COL fetches NOPRI;
--
COL parses_sec NOPRI;
COL executions_sec NOPRI;
COL fetches_sec NOPRI;
--
COL parses_perc NOPRI;
COL executions_perc NOPRI;
COL fetches_perc NOPRI;
--
COL loads NOPRI;
COL invalidations NOPRI;
COL version_count NOPRI;
--
COL loads_perc NOPRI;
COL invalidations_perc NOPRI;
COL version_count_perc NOPRI;
--
COL sharable_mem_mb NOPRI;
COL sharable_mem_perc NOPRI;
--
COL rows_processed_sec PRI;
COL buffer_gets_sec PRI;
COL disk_reads_sec PRI;
--
COL rows_processed_exec PRI;
COL buffer_gets_exec PRI;
COL disk_reads_exec PRI;
--
COL rows_processed_perc PRI;
COL buffer_gets_perc PRI;
COL disk_reads_perc PRI;
--
COL min_plan_hash_value NOPRI;
COL max_plan_hash_value NOPRI;
COL application_module NOPRI;
COL sql_text_100 NOPRI;
--
/

PRO
PRO Top &&top_what. by "&&metric_display." - Cursors
PRO ~~~~~~~~~~
--
COL db_time_exec NOPRI;
COL cpu_time_exec NOPRI;
COL io_time_exec NOPRI;
COL appl_time_exec NOPRI;
COL conc_time_exec NOPRI;
--
COL db_time_aas NOPRI;
COL cpu_time_aas NOPRI;
COL io_time_aas NOPRI;
COL appl_time_aas NOPRI;
COL conc_time_aas NOPRI;
--
COL db_time_perc NOPRI;
COL cpu_time_perc NOPRI;
COL io_time_perc NOPRI;
COL appl_time_perc NOPRI;
COL conc_time_perc NOPRI;
--
COL parses NOPRI;
COL executions NOPRI;
COL fetches NOPRI;
--
COL parses_sec NOPRI;
COL executions_sec NOPRI;
COL fetches_sec NOPRI;
--
COL parses_perc NOPRI;
COL executions_perc NOPRI;
COL fetches_perc NOPRI;
--
COL loads PRI;
COL invalidations PRI;
COL version_count PRI;
--
COL loads_perc PRI;
COL invalidations_perc PRI;
COL version_count_perc PRI;
--
COL sharable_mem_mb PRI;
COL sharable_mem_perc PRI;
--
COL rows_processed_sec NOPRI;
COL buffer_gets_sec NOPRI;
COL disk_reads_sec NOPRI;
--
COL rows_processed_exec NOPRI;
COL buffer_gets_exec NOPRI;
COL disk_reads_exec NOPRI;
--
COL rows_processed_perc NOPRI;
COL buffer_gets_perc NOPRI;
COL disk_reads_perc NOPRI;
--
COL min_plan_hash_value NOPRI;
COL max_plan_hash_value NOPRI;
COL application_module NOPRI;
COL sql_text_100 NOPRI;
--
/

BRE ON sql_id SKIP PAGE;

PRO
PRO SQL Text
PRO ~~~~~~~~

SET PAGES 1000;
WITH
my_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id, 
       MIN(con_id) con_id
  FROM dba_hist_sqltext
 WHERE dbid = &&dbid.
   AND ('&&sql_id.' IS NULL OR sql_id = '&&sql_id.')
   AND sql_id IN ('&&sql_id_01.', '&&sql_id_02.', '&&sql_id_03.', '&&sql_id_04.', '&&sql_id_05.', '&&sql_id_06.', '&&sql_id_07.', '&&sql_id_08.', '&&sql_id_09.', '&&sql_id_10.', '&&sql_id_11.', '&&sql_id_12.') 
 GROUP BY
       sql_id
)
SELECT sql_id,
       sql_text
  FROM dba_hist_sqltext
 WHERE dbid = &&dbid.
   AND (sql_id, con_id) IN (SELECT sql_id, con_id FROM my_sql)
 ORDER BY 
       sql_id
/
SET PAGES 100;

PRO
PRO &&output_file_name..txt
PRO
SPO OFF;
CL COL BRE COMP;
UNDEF 1 2 3 4 5 6 7;