----------------------------------------------------------------------------------------
--
-- File name:   cs_top_report.sql
--
-- Purpose:     Top SQL (or Top Plans) for range of dates
--
-- Author:      Carlos Sierra
--
-- Version:     2019/01/20
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter optional parameters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_report.sql
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
DEF cs_script_name = 'cs_top_report';
DEF cs_top_n = '12';
DEF cs_hours_range_default = '24';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO
PRO Top SQL is computed for selected metric within range of snaphots.
PRO
PRO Computed Metric
PRO ~~~~~~~~~~~~~~~
PRO db_time_exec              : Latency   - Elapsed Time          per Exec   - (MS)
PRO cpu_time_exec             : Latency   - CPU Time              per Exec   - (MS)
PRO io_time_exec              : Latency   - IO Wait Time          per Exec   - (MS)
PRO appl_time_exec            : Latency   - Application Wait Time per Exec   - (MS)
PRO conc_time_exec            : Latency   - Concurrency Wait Time per Exec   - (MS)
PRO db_time_aas               : DB Time   - Elapsed Time          - (AAS)
PRO cpu_time_aas              : DB Time   - CPU Time              - (AAS)
PRO io_time_aas               : DB Time   - IO Wait Time          - (AAS)
PRO appl_time_aas             : DB Time   - Application Wait Time - (AAS)
PRO conc_time_aas             : DB Time   - Concurrency Wait Time - (AAS)
PRO parses_sec                : DB Calls  - Parses                per Second - DB Calls
PRO executions_sec            : DB Calls  - Execs                 per Second - DB Calls
PRO fetches_sec               : DB Calls  - Fetches               per Second - DB Calls
PRO rows_processed_exec       : Resources - Rows Processed        per Exec   - Count
PRO buffer_gets_exec          : Resources - Buffer Gets           per Exec   - Count
PRO disk_reads_exec           : Resources - Disk Reads            per Exec   - Count
PRO physical_read_bytes_exec  : Resources - Physical Read Bytes   per Exec   - Bytes
PRO physical_write_bytes_exec : Resources - Physical Write Bytes  per Exec   - Bytes
PRO rows_processed_sec        : Resources - Rows Processed        per Second - Count
PRO buffer_gets_sec           : Resources - Buffer Gets           per Second - Count
PRO disk_reads_sec            : Resources - Disk Reads            per Second - Count
PRO physical_read_bytes_sec   : Resources - Physical Read Bytes   per Second - Bytes
PRO physical_write_bytes_sec  : Resources - Physical Write Bytes  per Second - Bytes
PRO loads                     : Cursors   - Loads                 - Count
PRO invalidations             : Cursors   - Invalidations         - Count
PRO version_count             : Cursors   - Versions              - Count
PRO sharable_mem_mb           : Cursors   - Sharable Memory       - (MBs)
PRO ~~~ groups ~~~
PRO Latency                   : Time per Exec - (MS)
PRO DB Time                   : DB Load (AAS)
PRO DB Calls                  : Executions (DB Calls)
PRO Resources per Exec        : Counts and Bytes
PRO Resources per Second      : Counts and Bytes
PRO Resources                 : per Second and per Exec
PRO Cursors                   : Count
PRO Main                      : db_time_exec, cpu_time_exec, db_time_aas, cpu_time_aas, executions_sec, rows_processed_exec, buffer_gets_exec
PRO *                         : All
PRO
PRO 3. Computed Metric (name or group, case sensitive): [{Main}|<computed_metric>|<group_name>]
DEF computed_metric = '&3.';
COL computed_metric NEW_V computed_metric NOPRI;
SELECT NVL('&&computed_metric.', 'Main') computed_metric FROM DUAL
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO *=All, TP=Transaction Processing, RO=Read Only, BG=Background, IG=Ignore, UN=Unknown
PRO
PRO 4. SQL Type: [{*}|TP|RO|BG|IG|UN|TP,RO|TP,RO,BG] 
DEF kiev_tx = '&4.';
COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT UPPER(NVL(TRIM('&&kiev_tx.'), '*')) kiev_tx FROM DUAL
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
          SELECT '@@cs_internal/cs_top_report_internal.sql "db_time_aas"' FROM DUAL WHERE '&&computed_metric.' IN ('db_time_aas', 'DB Time', 'Main', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "db_time_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('db_time_exec', 'Latency', 'Main', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "cpu_time_aas"' FROM DUAL WHERE '&&computed_metric.' IN ('cpu_time_aas', 'DB Time', 'Main', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "cpu_time_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('cpu_time_exec', 'Latency', 'Main', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "io_time_aas"' FROM DUAL WHERE '&&computed_metric.' IN ('io_time_aas', 'DB Time', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "io_time_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('io_time_exec', 'Latency', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "appl_time_aas"' FROM DUAL WHERE '&&computed_metric.' IN ('appl_time_aas', 'DB Time', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "appl_time_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('appl_time_exec', 'Latency', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "conc_time_aas"' FROM DUAL WHERE '&&computed_metric.' IN ('conc_time_aas', 'DB Time', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "conc_time_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('conc_time_exec', 'Latency', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "parses_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('parses_sec', 'DB Calls', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "executions_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('executions_sec', 'DB Calls', 'Main', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "fetches_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('fetches_sec', 'DB Calls', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "loads"' FROM DUAL WHERE '&&computed_metric.' IN ('loads', 'Cursors', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "invalidations"' FROM DUAL WHERE '&&computed_metric.' IN ('invalidations', 'Cursors', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "version_count"' FROM DUAL WHERE '&&computed_metric.' IN ('version_count', 'Cursors', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "sharable_mem_mb"' FROM DUAL WHERE '&&computed_metric.' IN ('sharable_mem_mb', 'Cursors', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "rows_processed_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('rows_processed_sec', 'Resources per Second', 'Resources', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "rows_processed_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('rows_processed_exec', 'Resources per Exec', 'Resources', 'Main', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "buffer_gets_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('buffer_gets_sec', 'Resources per Second', 'Resources', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "buffer_gets_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('buffer_gets_exec', 'Resources per Exec', 'Resources', 'Main', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "disk_reads_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('disk_reads_sec', 'Resources per Second', 'Resources', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "disk_reads_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('disk_reads_exec', 'Resources per Exec', 'Resources', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "physical_read_bytes_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('physical_read_bytes_sec', 'Resources per Second', 'Resources', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "physical_read_bytes_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('physical_read_bytes_exec', 'Resources per Exec', 'Resources', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "physical_write_bytes_sec"' FROM DUAL WHERE '&&computed_metric.' IN ('physical_write_bytes_sec', 'Resources per Second', 'Resources', '*')
UNION ALL SELECT '@@cs_internal/cs_top_report_internal.sql "physical_write_bytes_exec"' FROM DUAL WHERE '&&computed_metric.' IN ('physical_write_bytes_exec', 'Resources per Exec', 'Resources', '*')
/
SPO OFF;
SET HEA ON;
@cs_dynamic_driver.sql
HOST rm cs_dynamic_driver.sql
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--