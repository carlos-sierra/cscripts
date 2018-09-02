----------------------------------------------------------------------------------------
--
-- File name:   cs_top_chart.sql
--
-- Purpose:     Top SQL (or Top Plans) for range of dates
--
-- Author:      Carlos Sierra
--
-- Version:     2018/08/19
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter optional parameters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_chart.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_top_chart';
DEF cs_display_awr_days = '30';
DEF cs_top_n = '12';
DEF cs_hours_range_default = '24';
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL oldest_snap_id NEW_V oldest_snap_id NOPRI;
SELECT TO_CHAR(MAX(snap_id)) oldest_snap_id 
  FROM dba_hist_snapshot
 WHERE dbid = &&cs_dbid.
   AND instance_number = &&cs_instance_number.
   AND end_interval_time < SYSDATE - &&cs_display_awr_days.
/
SELECT NVL('&&oldest_snap_id.', TO_CHAR(MIN(snap_id))) oldest_snap_id 
  FROM dba_hist_snapshot
 WHERE dbid = &&cs_dbid.
   AND instance_number = &&cs_instance_number.
/
--
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
PRO *                   : All
PRO
PRO 3. Computed Metric: [{db_time_exec}|<computed_metric>|*]
DEF computed_metric = '&3.';
COL computed_metric NEW_V computed_metric NOPRI;
SELECT LOWER(NVL('&&computed_metric.', 'db_time_exec')) computed_metric FROM DUAL
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO
PRO 4. KIEV Transaction: [{CBSGU}|C|B|S|G|U|CB|SG] (C=CommitTx B=BeginTx S=Scan G=GC U=Unknown)
DEF kiev_tx = '&4.';
COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT NVL('&&kiev_tx.', 'CBSGU') kiev_tx FROM DUAL
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Enter additional SQL Text filtering, such as Table name or SQL Text piece
PRO
PRO 5. SQL Text piece (optional):
DEF sql_text_piece = '&5.';
--
PRO
PRO Filtering SQL to reduce search space.
PRO By entering an optional SQL_ID, scope changes from TOP SQL to TOP Plans
PRO
PRO 6. SQL_ID (optional):
DEF sql_id = '&6.';
COL top_what NEW_V top_what NOPRI;
SELECT CASE WHEN '&&sql_id.' IS NULL THEN 'SQL' ELSE 'Plans' END top_what FROM DUAL
/
--
SET HEA OFF;
SPO cs_dynamic_driver.sql
          SELECT '@@cs_internal/cs_top_chart_internal.sql "db_time_aas"' FROM DUAL WHERE '&&computed_metric.' IN ('db_time_aas', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "db_time_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('db_time_exec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "cpu_time_aas"' FROM DUAL WHERE '&&computed_metric.' IN ('cpu_time_aas', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "cpu_time_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('cpu_time_exec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "io_time_aas"' FROM DUAL WHERE '&&computed_metric.' IN ('io_time_aas', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "io_time_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('io_time_exec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "appl_time_aas"' FROM DUAL WHERE '&&computed_metric.' IN ('appl_time_aas', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "appl_time_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('appl_time_exec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "conc_time_aas"' FROM DUAL WHERE '&&computed_metric.' IN ('conc_time_aas', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "conc_time_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('conc_time_exec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "parses_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('parses_sec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "executions_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('executions_sec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "fetches_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('fetches_sec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "loads"' FROM DUAL WHERE '&&computed_metric.' IN ('loads', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "invalidations"' FROM DUAL WHERE '&&computed_metric.' IN ('invalidations', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "version_count"' FROM DUAL WHERE '&&computed_metric.' IN ('version_count', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "sharable_mem_mb"' FROM DUAL WHERE '&&computed_metric.' IN ('sharable_mem_mb', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "rows_processed_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('rows_processed_sec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "rows_processed_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('rows_processed_exec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "buffer_gets_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('buffer_gets_sec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "buffer_gets_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('buffer_gets_exec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "disk_reads_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('disk_reads_sec', '*')
UNION ALL SELECT '@@cs_internal/cs_top_chart_internal.sql "disk_reads_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('disk_reads_exec', '*')
/
SPO OFF;
SET HEA ON;
@cs_dynamic_driver.sql
HOST rm cs_dynamic_driver.sql
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--