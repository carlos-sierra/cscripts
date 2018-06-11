-- setting parameters so it can be executed in all KIEV CDB from OEM as a SQL Job
--@top_sql_one_report.sql "" "" "" "G" "KIEV_CPS_WORKFLOW"
DEF 1 = '';
DEF 2 = ''
DEF 3 = '';
DEF 4 = 'G';
DEF 5 = 'KIEV_CPS_WORKFLOW';
--
----------------------------------------------------------------------------------------
--
-- File name:   top_sql_one_report.sql
--
--              *** Requires Oracle Diagnostics Pack License ***
--
-- Purpose:     Lists Top N (20) SQL statements as per most recent AWR snapshot (default)
--              or for a range of snapshots.
--
-- Author:      Carlos Sierra
--
-- Version:     2018/02/01
--
-- Usage:       Execute connected into the CDB or PDB of interest.
--
--              Enter range of AWR snapshot (optional), and metric of interest (optional)
--              Dafaults to last AWR snapshot and to elapsed_time_delta (DB time)
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @top_sql_one_report.sql
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

DEF top_n = '12';
DEF default_awr_days = '14';
DEF default_window_hours = '1';
DEF date_format = 'YYYY-MM-DD"T"HH24:MI:SS';

SET HEA ON LIN 1000 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET LONG 40000 LONGC 400;

COL dbid NEW_V dbid NOPRI;
COL db_name NEW_V db_name NOPRI;
SELECT dbid, LOWER(name) db_name FROM v$database
/

COL instance_number NEW_V instance_number NOPRI;
COL host_name NEW_V host_name NOPRI;
SELECT instance_number, LOWER(host_name) host_name FROM v$instance
/

COL con_name NEW_V con_name NOPRI;
SELECT 'NONE' con_name FROM DUAL;
SELECT LOWER(SYS_CONTEXT('USERENV', 'CON_NAME')) con_name FROM DUAL
/

COL oldest_snap_id NEW_V oldest_snap_id NOPRI;
SELECT MAX(snap_id) oldest_snap_id 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND end_interval_time < SYSDATE - &&default_awr_days.
/


/* too verbose
SELECT snap_id, 
       TO_CHAR(begin_interval_time, '&&date_format.') begin_time, 
       TO_CHAR(end_interval_time, '&&date_format.') end_time
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND snap_id > &&oldest_snap_id.
 ORDER BY
       snap_id
/
*/

PRO
PRO 1. SNAP_ID from:
DEF snap_id_from = '&1.';
PRO
PRO 2. SNAP_ID to:
DEF snap_id_to = '&2.';

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

COL interval_seconds NEW_V interval_seconds NOPRI;
SELECT TO_CHAR(ROUND((TO_DATE('&&end_interval_time.', '&&date_format.') - TO_DATE('&&begin_interval_time.', '&&date_format.')) * 24 * 60 * 60)) interval_seconds FROM DUAL
/

/* too verbose
PRO
PRO Metrics
PRO ~~~~~~~~~~~~~~~~~~~
PRO elapsed_time_delta
PRO cpu_time_delta
PRO iowait_delta
PRO apwait_delta
PRO ccwait_delta
PRO parse_calls_delta
PRO executions_delta
PRO fetches_delta
PRO loads_delta
PRO invalidations_delta
PRO version_count
PRO sharable_mem
PRO rows_processed_delta
PRO buffer_gets_delta
PRO disk_reads_delta
PRO
*/

PRO 3. Metric:
DEF metric = '&3.';

COL metric NEW_V metric NOPRI;
SELECT NVL('&&metric.', 'elapsed_time_delta') metric FROM DUAL
/

COL aggregate_function NEW_V aggregate_function NOPRI;
SELECT CASE '&&metric.' WHEN 'version_count' THEN 'MAX' ELSE 'SUM' END aggregate_function FROM DUAL
/

PRO
PRO 4. KIEV Transaction: [{CBSGU}|C|B|S|G|U|CB|SG] (C=CommitTx B=BeginTx S=Scan G=GC U=Unknown)
DEF kiev_tx = '&4.';

COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT NVL('&&kiev_tx.', 'CBSGU') kiev_tx FROM DUAL
/

PRO
PRO 5. KIEV Bucket: <null>=all
DEF kiev_bucket = '&5.';

COL locale NEW_V locale NOPRI;
SELECT LOWER(REPLACE(SUBSTR('&&host_name.', 1 + INSTR('&&host_name.', '.', 1, 2), 30), '.', '_')) locale FROM DUAL
/

COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'top_sql_&&locale._&&db_name._'||REPLACE('&&con_name.','cdb$root','cdb')||'_&&snap_id_min._&&snap_id_max._&&metric.' output_file_name FROM DUAL
/

COL rank FOR 9999 HEA 'TOP';
COL con_id FOR 999 HEA 'PDB|ID';
COL pdb_name FOR A30;
COL db_time_exec FOR 999,990.000 HEA 'DB TIME|SECONDS|PER EXEC';
COL db_time_aas FOR 9,990.0 HEA 'DB|TIME|(AAS)';
COL db_time_perc FOR 9,990.0 HEA 'DB|TIME|(PERC)';
COL cpu_time_aas FOR 9,990.0 HEA 'CPU|TIME|(AAS)';
COL cpu_time_perc FOR 9,990.0 HEA 'CPU|TIME|(PERC)';
COL io_time_aas FOR 9,990.0 HEA 'IO|TIME|(AAS)';
COL io_time_perc FOR 9,990.0 HEA 'IO|TIME|(PERC)';
COL appl_time_aas FOR 9,990.0 HEA 'APPL|TIME|(AAS)';
COL appl_time_perc FOR 9,990.0 HEA 'APPL|TIME|(PERC)';
COL conc_time_aas FOR 9,990.0 HEA 'CONC|TIME|(AAS)';
COL conc_time_perc FOR 9,990.0 HEA 'CONC|TIME|(PERC)';
COL parses_sec FOR 999,990 HEA 'PARSES|PER|SECOND';
COL parses_perc FOR 9,990.0 HEA 'PARSES|(PERC)';
COL executions_sec FOR 999,990 HEA 'EXECS|PER|SECOND';
COL executions_perc FOR 9,990.0 HEA 'EXECS|(PERC)';
COL fetches_sec FOR 999,990 HEA 'FETCHES|PER|SECOND';
COL fetches_perc FOR 9,990.0 HEA 'FETCHES|(PERC)';
COL loads FOR 999,990 HEA 'LOADS';
COL loads_perc FOR 9,990.0 HEA 'LOADS|(PERC)';
COL invalidations FOR 999,990 HEA 'INVALI-|DATIONS';
COL invalidations_perc FOR 9,990.0 HEA 'INVALI-|DATIONS|(PERC)';
COL version_count FOR 999,990 HEA 'VERSION|COUNT';
COL version_count_perc FOR 9,990.0 HEA 'VERSION|COUNT|(PERC)';
COL sharable_mem_mb FOR 9999,990 HEA 'SHARABLE|MEM|(MBs)';
COL sharable_mem_perc FOR 99,990.0 HEA 'SHARABLE|MEM|(PERC)';
COL rows_processed_sec FOR 999,999,990 HEA 'ROWS|PROCESSSED|PER SECOND';
COL rows_processed_exec FOR 999,999,990.0 HEA 'ROWS|PROCESSSED|PER EXEC';
COL rows_processed_perc FOR 9999,990.0 HEA 'ROWS|PROCESSSED|(PERC)';
COL buffer_gets_sec FOR 999,999,990 HEA 'BUFFER|GETS|PER SECOND';
COL buffer_gets_exec FOR 999,999,990.0 HEA 'BUFFER|GETS|PER EXEC';
COL buffer_gets_perc FOR 9,990.0 HEA 'BUFFER|GETS|(PERC)';
COL disk_reads_sec FOR 999,999,990 HEA 'DISK|READS|PER SECOND';
COL disk_reads_exec FOR 999,999,990.0 HEA 'DISK|READS|PER EXEC';
COL disk_reads_perc FOR 9,990.0 HEA 'DISK|READS|(PERC)';
COL sql_text_100 FOR A100 HEA 'SQL TEXT';
COL sql_text FOR A400;
COL application_module FOR A8 HEA 'KIEV TX';

COL dummy_nopri NOPRI;
BRE ON dummy_nopri SKIP PAGE;
COMP SUM LABEL 'TOTAL' OF db_time_aas db_time_perc cpu_time_aas cpu_time_perc io_time_aas io_time_perc appl_time_aas appl_time_perc conc_time_aas conc_time_perc parses_sec parses_perc executions_sec executions_perc fetches_sec fetches_perc loads loads_perc invalidations invalidations_perc version_count version_count_perc sharable_mem_mb sharable_mem_perc rows_processed_sec rows_processed_perc buffer_gets_sec buffer_gets_perc disk_reads_sec disk_reads_perc ON dummy_nopri;
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';

SPO &&output_file_name..txt;
PRO
PRO &&output_file_name..txt
PRO
PRO LOCALE   : &&locale.
PRO DATABASE : &&db_name.
PRO PDB      : &&con_name.
PRO HOST     : &&host_name.
PRO BEGIN    : &&begin_interval_time. (SNAP_ID &&snap_id_min.)
PRO END      : &&end_interval_time. (SNAP_ID &&snap_id_max.)
PRO SECONDS  : &&interval_seconds.
PRO METRIC   : &&metric.
PRO KIEV TX  : &&kiev_tx.
PRO KIEV BKT : &&kiev_bucket.
PRO
PRO Average Active Sessions (AAS) on CPU means: how many CPU Threads a SQL burns. 
PRO System has 36 CPU Cores, capable to serve up to 50 CPU Threads before oversubscrption.
PRO Example: One SQL with 5 AAS on CPU burns 10 percent of total System capacity.
PRO
PRO Top SQL by &&metric.
PRO ~~~~~~~~~~

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
--      DISTINCT sql_id, sql_text FROM v$sql
--UNION
SELECT /*+ MATERIALIZE NO_MERGE */ 
       DISTINCT sql_id, DBMS_LOB.SUBSTR(sql_text, 1000) sql_text FROM dba_hist_sqltext
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
SELECT /*+ MATERIALIZE NO_MERGE FULL(s) */
       s.snap_id,
       CAST(s.end_interval_time AS DATE) end_date_time,
       (CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 24 * 60 * 60 interval_seconds
  FROM sys.wrm$_snapshot s /* dba_hist_snapshot */
 WHERE s.dbid = &&dbid.
   AND s.instance_number = &&instance_number.
   AND s.snap_id BETWEEN &&snap_id_min. AND &&snap_id_max.
),
sqlstat AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       CON_DBID_TO_ID(h.con_dbid) con_id,
       h.sql_id,
       SUM(s.interval_seconds) interval_seconds,
       SUM(h.elapsed_time_delta) db_time,
       SUM(SUM(h.elapsed_time_delta)) OVER () tot_db_time,
       SUM(h.cpu_time_delta) cpu_time,
       SUM(SUM(h.cpu_time_delta)) OVER () tot_cpu_time,
       SUM(h.iowait_delta) io_time,
       SUM(SUM(h.iowait_delta)) OVER () tot_io_time,
       SUM(h.apwait_delta) appl_time,
       SUM(SUM(h.apwait_delta)) OVER () tot_appl_time,
       SUM(h.ccwait_delta) conc_time,
       SUM(SUM(h.ccwait_delta)) OVER () tot_conc_time,
       SUM(h.parse_calls_delta) parses,
       SUM(SUM(h.parse_calls_delta)) OVER () tot_parses,
       SUM(h.executions_delta) executions,
       SUM(SUM(h.executions_delta)) OVER () tot_executions,
       SUM(h.fetches_delta) fetches,
       SUM(SUM(h.fetches_delta)) OVER () tot_fetches,
       SUM(h.loads_delta) loads,
       SUM(SUM(h.loads_delta)) OVER () tot_loads,
       SUM(h.invalidations_delta) invalidations,
       SUM(SUM(h.invalidations_delta)) OVER () tot_invalidations,
       MAX(h.version_count) version_count,
       SUM(MAX(h.version_count)) OVER () tot_version_count,
       SUM(h.sharable_mem) sharable_mem,
       SUM(SUM(h.sharable_mem)) OVER () tot_sharable_mem,
       SUM(h.rows_processed_delta) rows_processed,
       SUM(SUM(h.rows_processed_delta)) OVER () tot_rows_processed,
       SUM(h.buffer_gets_delta) buffer_gets,
       SUM(SUM(h.buffer_gets_delta)) OVER () tot_buffer_gets,
       SUM(h.disk_reads_delta) disk_reads,
       SUM(SUM(h.disk_reads_delta)) OVER () tot_disk_reads,
       RANK() OVER (ORDER BY &&aggregate_function.(h.&&metric.) DESC NULLS LAST, SUM(h.elapsed_time_delta) DESC NULLS LAST) rank
  FROM sys.wrh$_sqlstat h, /* dba_hist_sqlstat */
       snapshots s /* dba_hist_snapshot */
 WHERE h.dbid = &&dbid.
   AND h.instance_number = &&instance_number.
   AND h.snap_id BETWEEN &&snap_id_min. AND &&snap_id_max.
   AND h.sql_id IN (SELECT t.sql_id FROM my_tx_sql t WHERE UPPER(t.sql_text) LIKE CHR(37)||UPPER('&&kiev_bucket.')||CHR(37))
   AND s.snap_id = h.snap_id
 GROUP BY
       CON_DBID_TO_ID(h.con_dbid),
       h.sql_id
),
top_n AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       rank,
       con_id,
       sql_id,
       ROUND(db_time/1e6/GREATEST(executions,1), 3) db_time_exec,
       ROUND(db_time/1e6/interval_seconds,1) db_time_aas,
       ROUND(100*db_time/GREATEST(tot_db_time,1),1) db_time_perc,
       ROUND(cpu_time/1e6/interval_seconds,1) cpu_time_aas,
       ROUND(100*cpu_time/GREATEST(tot_cpu_time,1),1) cpu_time_perc,
       ROUND(io_time/1e6/interval_seconds,1) io_time_aas,
       ROUND(100*io_time/GREATEST(tot_io_time,1),1) io_time_perc,
       ROUND(appl_time/1e6/interval_seconds,1) appl_time_aas,
       ROUND(100*appl_time/GREATEST(tot_appl_time,1),1) appl_time_perc,
       ROUND(conc_time/1e6/interval_seconds,1) conc_time_aas,
       ROUND(100*conc_time/GREATEST(tot_conc_time,1),1) conc_time_perc,
       ROUND(parses/interval_seconds) parses_sec,
       ROUND(100*parses/GREATEST(tot_parses,1),1) parses_perc,
       ROUND(executions/interval_seconds) executions_sec,
       ROUND(100*executions/GREATEST(tot_executions,1),1) executions_perc,
       ROUND(fetches/interval_seconds) fetches_sec,
       ROUND(100*fetches/GREATEST(tot_fetches,1),1) fetches_perc,
       loads,
       ROUND(100*loads/GREATEST(tot_loads,1),1) loads_perc,
       invalidations,
       ROUND(100*invalidations/GREATEST(tot_invalidations,1),1) invalidations_perc,
       version_count,
       ROUND(100*version_count/GREATEST(tot_version_count,1),1) version_count_perc,
       ROUND(sharable_mem/POWER(2,20)) sharable_mem_mb,
       ROUND(100*sharable_mem/GREATEST(tot_sharable_mem,1),1) sharable_mem_perc,
       ROUND(rows_processed/interval_seconds) rows_processed_sec,
       ROUND(rows_processed/GREATEST(executions,1), 1) rows_processed_exec,
       ROUND(100*rows_processed/GREATEST(tot_rows_processed,1),1) rows_processed_perc,
       ROUND(buffer_gets/interval_seconds) buffer_gets_sec,
       ROUND(buffer_gets/GREATEST(executions,1), 1) buffer_gets_exec,
       ROUND(100*buffer_gets/GREATEST(tot_buffer_gets,1),1) buffer_gets_perc,
       ROUND(disk_reads/interval_seconds) disk_reads_sec,
       ROUND(disk_reads/GREATEST(executions,1), 1) disk_reads_exec,
       ROUND(100*disk_reads/GREATEST(tot_disk_reads,1),1) disk_reads_perc
  FROM sqlstat
 WHERE rank <= &&top_n.
)
SELECT 1 dummy_nopri,
       t.rank,
       t.con_id,
       c.name pdb_name,
       t.sql_id,
       t.db_time_exec,
       t.db_time_aas,
       t.db_time_perc,
       t.cpu_time_aas,
       t.cpu_time_perc,
       t.io_time_aas,
       t.io_time_perc,
       t.appl_time_aas,
       t.appl_time_perc,
       t.conc_time_aas,
       t.conc_time_perc,
       t.parses_sec,
       t.parses_perc,
       t.executions_sec,
       t.executions_perc,
       t.fetches_sec,
       t.fetches_perc,
       t.loads,
       t.loads_perc,
       t.invalidations,
       t.invalidations_perc,
       t.version_count,
       t.version_count_perc,
       t.sharable_mem_mb,
       t.sharable_mem_perc,
       t.rows_processed_sec,
       t.rows_processed_exec,
       t.rows_processed_perc,
       t.buffer_gets_sec,
       t.buffer_gets_exec,
       t.buffer_gets_perc,
       t.disk_reads_sec,
       t.disk_reads_exec,
       t.disk_reads_perc,
       t.sql_id,
       s.application_module,
       s.sql_text_100
  FROM top_n t,
       v$containers c,
       my_tx_sql s
 WHERE c.con_id = t.con_id
   AND s.sql_id = t.sql_id
 ORDER BY
       t.rank
/

PRO
PRO &&output_file_name..txt

SPO OFF;
CL COL BRE COMP;
UNDEF 1 2 3 4 5;