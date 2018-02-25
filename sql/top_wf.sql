----------------------------------------------------------------------------------------
--
-- File name:   top_wf.sql
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
--              Dafults to last AWR snapshot and to elapsed_time_delta (DB time)
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @top_wf.sql
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
DEF top_n = '20000';
SET HEA ON LIN 1000 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET LONG 40000 LONGC 400;

COL dbid NEW_V dbid;
COL db_name NEW_V db_name;
SELECT dbid, LOWER(name) db_name FROM v$database
/

COL instance_number NEW_V instance_number;
COL host_name NEW_V host_name;
SELECT instance_number, LOWER(host_name) host_name FROM v$instance
/

COL con_name NEW_V con_name;
SELECT 'NONE' con_name FROM DUAL;
SELECT LOWER(SYS_CONTEXT('USERENV', 'CON_NAME')) con_name FROM DUAL
/

DEF date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
SELECT snap_id, 
       TO_CHAR(begin_interval_time, '&&date_format.') begin_interval_time, 
       TO_CHAR(end_interval_time, '&&date_format.') end_interval_time
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND begin_interval_time > SYSDATE - 7
 ORDER BY
       snap_id
/

ACC snap_id_from PROMPT 'SNAP_ID from: ';
ACC snap_id_to   PROMPT 'SNAP_ID to  : ';

COL snap_id_max NEW_V snap_id_max;
SELECT TO_CHAR(NVL(TO_NUMBER('&&snap_id_to.'), MAX(snap_id))) snap_id_max 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
/

COL snap_id_min NEW_V snap_id_min;
SELECT TO_CHAR(NVL(TO_NUMBER('&&snap_id_from.'), MAX(snap_id))) snap_id_min 
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
/

COL begin_interval_time NEW_V begin_interval_time;
SELECT TO_CHAR(begin_interval_time, '&&date_format.') begin_interval_time
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND snap_id = &&snap_id_min.
/

COL end_interval_time NEW_V end_interval_time;
SELECT TO_CHAR(end_interval_time, '&&date_format.') end_interval_time
  FROM dba_hist_snapshot
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND snap_id = &&snap_id_max.
/

COL interval_seconds NEW_V interval_seconds;
SELECT TO_CHAR(ROUND((TO_DATE('&&end_interval_time.', '&&date_format.') - TO_DATE('&&begin_interval_time.', '&&date_format.')) * 24 * 60 * 60)) interval_seconds FROM DUAL
/

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

ACC metric PROMPT 'Metric: ';
COL metric NEW_V metric;
SELECT NVL('&&metric.', 'elapsed_time_delta') metric FROM DUAL
/

COL aggregate_function NEW_V aggregate_function;
SELECT CASE '&&metric.' WHEN 'version_count' THEN 'MAX' ELSE 'SUM' END aggregate_function FROM DUAL
/

COL locale NEW_V locale;
SELECT LOWER(REPLACE(SUBSTR('&&host_name.', 1 + INSTR('&&host_name.', '.', 1, 2), 30), '.', '_')) locale FROM DUAL
/

COL output_file_name NEW_V output_file_name;
SELECT 'top_wf_&&locale._&&db_name._'||REPLACE('&&con_name.','$')||'_&&snap_id_min._&&snap_id_max._&&metric.' output_file_name FROM DUAL
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

COL dummy_nopri NOPRI;
BRE ON dummy_nopri SKIP PAGE;
COMP SUM LABEL 'TOTAL' OF db_time_aas db_time_perc cpu_time_aas cpu_time_perc io_time_aas io_time_perc appl_time_aas appl_time_perc conc_time_aas conc_time_perc parses_sec parses_perc executions_sec executions_perc fetches_sec fetches_perc loads loads_perc invalidations invalidations_perc version_count version_count_perc sharable_mem_mb sharable_mem_perc rows_processed_sec rows_processed_perc buffer_gets_sec buffer_gets_perc disk_reads_sec disk_reads_perc ON dummy_nopri;

SPO &&output_file_name..txt;
PRO
PRO &&output_file_name..txt
PRO
PRO LOCALE   : &&locale.
PRO DATABASE : &&db_name.
PRO CONTAINER: &&con_name.
PRO HOST     : &&host_name.
PRO BEGIN    : &&begin_interval_time. (SNAP_ID &&snap_id_min.)
PRO END      : &&end_interval_time. (SNAP_ID &&snap_id_max.)
PRO SECONDS  : &&interval_seconds.
PRO METRIC   : &&metric.
PRO
PRO Average Active Sessions (AAS) on CPU means: how many CPU Threads a SQL burns. 
PRO System has 36 CPU Cores, capable to serve up to 50 CPU Threads before oversubscrption.
PRO Example: One SQL with 5 AAS on CPU burns 10% of total System capacity.
PRO
PRO Top SQL by &&metric.
PRO ~~~~~~~~~~

WITH
sqlstat AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       sql_id,
       SUM(elapsed_time_delta) db_time,
       SUM(SUM(elapsed_time_delta)) OVER () tot_db_time,
       SUM(cpu_time_delta) cpu_time,
       SUM(SUM(cpu_time_delta)) OVER () tot_cpu_time,
       SUM(iowait_delta) io_time,
       SUM(SUM(iowait_delta)) OVER () tot_io_time,
       SUM(apwait_delta) appl_time,
       SUM(SUM(apwait_delta)) OVER () tot_appl_time,
       SUM(ccwait_delta) conc_time,
       SUM(SUM(ccwait_delta)) OVER () tot_conc_time,
       SUM(parse_calls_delta) parses,
       SUM(SUM(parse_calls_delta)) OVER () tot_parses,
       SUM(executions_delta) executions,
       SUM(SUM(executions_delta)) OVER () tot_executions,
       SUM(fetches_delta) fetches,
       SUM(SUM(fetches_delta)) OVER () tot_fetches,
       SUM(loads_delta) loads,
       SUM(SUM(loads_delta)) OVER () tot_loads,
       SUM(invalidations_delta) invalidations,
       SUM(SUM(invalidations_delta)) OVER () tot_invalidations,
       MAX(version_count) version_count,
       SUM(MAX(version_count)) OVER () tot_version_count,
       SUM(sharable_mem) sharable_mem,
       SUM(SUM(sharable_mem)) OVER () tot_sharable_mem,
       SUM(rows_processed_delta) rows_processed,
       SUM(SUM(rows_processed_delta)) OVER () tot_rows_processed,
       SUM(buffer_gets_delta) buffer_gets,
       SUM(SUM(buffer_gets_delta)) OVER () tot_buffer_gets,
       SUM(disk_reads_delta) disk_reads,
       SUM(SUM(disk_reads_delta)) OVER () tot_disk_reads,
       RANK() OVER (ORDER BY &&aggregate_function.(&&metric.) DESC NULLS LAST, SUM(elapsed_time_delta) DESC NULLS LAST) rank
  FROM dba_hist_sqlstat
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND snap_id BETWEEN &&snap_id_min. AND &&snap_id_max.
 GROUP BY
       con_id,
       sql_id
),
top_n AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       rank,
       con_id,
       sql_id,
       ROUND(db_time/1e6/CASE WHEN executions > 1 THEN executions END, 3) db_time_exec,
       ROUND(db_time/1e6/&&interval_seconds.,1) db_time_aas,
       ROUND(100*db_time/GREATEST(tot_db_time,1),1) db_time_perc,
       ROUND(cpu_time/1e6/&&interval_seconds.,1) cpu_time_aas,
       ROUND(100*cpu_time/GREATEST(tot_cpu_time,1),1) cpu_time_perc,
       ROUND(io_time/1e6/&&interval_seconds.,1) io_time_aas,
       ROUND(100*io_time/GREATEST(tot_io_time,1),1) io_time_perc,
       ROUND(appl_time/1e6/&&interval_seconds.,1) appl_time_aas,
       ROUND(100*appl_time/GREATEST(tot_appl_time,1),1) appl_time_perc,
       ROUND(conc_time/1e6/&&interval_seconds.,1) conc_time_aas,
       ROUND(100*conc_time/GREATEST(tot_conc_time,1),1) conc_time_perc,
       ROUND(parses/&&interval_seconds.) parses_sec,
       ROUND(100*parses/GREATEST(tot_parses,1),1) parses_perc,
       ROUND(executions/&&interval_seconds.) executions_sec,
       ROUND(100*executions/GREATEST(tot_executions,1),1) executions_perc,
       ROUND(fetches/&&interval_seconds.) fetches_sec,
       ROUND(100*fetches/GREATEST(tot_fetches,1),1) fetches_perc,
       loads,
       ROUND(100*loads/GREATEST(tot_loads,1),1) loads_perc,
       invalidations,
       ROUND(100*invalidations/GREATEST(tot_invalidations,1),1) invalidations_perc,
       version_count,
       ROUND(100*version_count/GREATEST(tot_version_count,1),1) version_count_perc,
       ROUND(sharable_mem/POWER(2,20)) sharable_mem_mb,
       ROUND(100*sharable_mem/GREATEST(tot_sharable_mem,1),1) sharable_mem_perc,
       ROUND(rows_processed/&&interval_seconds.) rows_processed_sec,
       ROUND(rows_processed/CASE WHEN executions > 1 THEN executions END, 1) rows_processed_exec,
       ROUND(100*rows_processed/GREATEST(tot_rows_processed,1),1) rows_processed_perc,
       ROUND(buffer_gets/&&interval_seconds.) buffer_gets_sec,
       ROUND(buffer_gets/CASE WHEN executions > 1 THEN executions END, 1) buffer_gets_exec,
       ROUND(100*buffer_gets/GREATEST(tot_buffer_gets,1),1) buffer_gets_perc,
       ROUND(disk_reads/&&interval_seconds.) disk_reads_sec,
       ROUND(disk_reads/CASE WHEN executions > 1 THEN executions END, 1) disk_reads_exec,
       ROUND(100*disk_reads/GREATEST(tot_disk_reads,1),1) disk_reads_perc
  FROM sqlstat
 WHERE rank <= &&top_n.
)
SELECT 1 dummy_nopri,
       t.rank,
       t.con_id,
       c.pdb_name,
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
       REPLACE(REPLACE(DBMS_LOB.SUBSTR(s.sql_text, 100), CHR(10), CHR(32)), CHR(9), CHR(32)) sql_text_100
  FROM top_n t,
       cdb_pdbs c,
       dba_hist_sqltext s
 WHERE c.con_id = t.con_id
   AND s.con_id = t.con_id
   AND s.dbid = &&dbid.
   AND s.sql_id = t.sql_id
   AND (DBMS_LOB.SUBSTR(s.sql_text, 100) LIKE '/* performScanQuery(leaseDecorators,HashRangeIndex) */%' OR DBMS_LOB.SUBSTR(s.sql_text, 100) LIKE '/* performScanQuery(workflowInstances,HashRangeIndex) */%')
 ORDER BY
       t.rank
/

BRE ON rank SKIP PAGE;

PRO
PRO SQL Text
PRO ~~~~~~~~

WITH
sqlstat AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       sql_id,
       RANK() OVER (ORDER BY &&aggregate_function.(&&metric.) DESC NULLS LAST, SUM(elapsed_time_delta) DESC NULLS LAST) rank
  FROM dba_hist_sqlstat
 WHERE dbid = &&dbid.
   AND instance_number = &&instance_number.
   AND snap_id BETWEEN &&snap_id_min. AND &&snap_id_max.
 GROUP BY
       con_id,
       sql_id
),
top_n AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       rank,
       con_id,
       sql_id
  FROM sqlstat
 WHERE rank <= &&top_n.
)
SELECT t.rank,
       t.con_id,
       c.pdb_name,
       t.sql_id,
       s.sql_text
  FROM top_n t,
       cdb_pdbs c,
       dba_hist_sqltext s
 WHERE c.con_id = t.con_id
   AND s.con_id = t.con_id
   AND s.dbid = &&dbid.
   AND s.sql_id = t.sql_id
   AND (DBMS_LOB.SUBSTR(s.sql_text, 100) LIKE '/* performScanQuery(leaseDecorators,%' OR DBMS_LOB.SUBSTR(s.sql_text, 100) LIKE '/* performScanQuery(workflowInstances,%')
 ORDER BY
       t.rank
/

PRO
PRO &&output_file_name..txt

SPO OFF;
CL COL BRE COMP;