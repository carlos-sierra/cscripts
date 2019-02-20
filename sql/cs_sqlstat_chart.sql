----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlstat_chart.sql
--
-- Purpose:     SQLSTAT chart for a set of SQL statements matching filters
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
--              SQL> @cs_sqlstat_chart.sql
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
DEF cs_script_name = 'cs_sqlstat_chart';
DEF cs_display_awr_days = '60';
DEF cs_hours_range_default = '168';
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
PRO ~~~ groups ~~~
PRO Main       : latency, db_time, calls, rows_exec, reads_exec
PRO *          : All
PRO
PRO 3. Metric Group (name or group, case sensitive): [{Main}|<metric_group>|<group_name>]
DEF metric_group = '&3.';
COL metric_group NEW_V metric_group NOPRI;
SELECT NVL('&&metric_group.', 'Main') metric_group FROM DUAL
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
PRO
PRO 6. SQL_ID (optional):
DEF sql_id = '&6.';
--
PRO
PRO Filtering SQL to reduce search space.
PRO
PRO 7. Plan Hash Value (optional):
DEF phv = '&7.';
--
PRO
PRO Filtering SQL to reduce search space.
PRO
PRO 8. Parsing Schema Name (optional):
DEF parsing_schema_name = '&8.';
--
SET HEA OFF;
SPO cs_dynamic_driver.sql
          SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "latency"' FROM DUAL WHERE '&&metric_group.' IN ('latency', 'Main', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "db_time"' FROM DUAL WHERE '&&metric_group.' IN ('db_time', 'Main', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "calls"' FROM DUAL WHERE '&&metric_group.' IN ('calls', 'Main', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "rows_sec"' FROM DUAL WHERE '&&metric_group.' IN ('rows_sec', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "rows_exec"' FROM DUAL WHERE '&&metric_group.' IN ('rows_exec', 'Main', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "reads_sec"' FROM DUAL WHERE '&&metric_group.' IN ('reads_sec', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "reads_exec"' FROM DUAL WHERE '&&metric_group.' IN ('reads_exec', 'Main', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "cursors"' FROM DUAL WHERE '&&metric_group.' IN ('cursors', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "memory"' FROM DUAL WHERE '&&metric_group.' IN ('memory', '*')
/
SPO OFF;
SET HEA ON;
@cs_dynamic_driver.sql
HOST rm cs_dynamic_driver.sql
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--