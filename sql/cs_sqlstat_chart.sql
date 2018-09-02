----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlstat_chart.sql
--
-- Purpose:     SQLSTAT chart for a set of SQL statements matching filters
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
PRO *          : All
PRO
PRO 1. Metric Group: [{latency}|<metric_group>|*]
DEF metric_group = '&1.';
COL metric_group NEW_V metric_group NOPRI;
SELECT LOWER(NVL('&&metric_group.', 'latency')) metric_group FROM DUAL
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO
PRO 2. KIEV Transaction: [{CBSGU}|C|B|S|G|U|CB|SG] (C=CommitTx B=BeginTx S=Scan G=GC U=Unknown)
DEF kiev_tx = '&2.';
COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT NVL('&&kiev_tx.', 'CBSGU') kiev_tx FROM DUAL
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Enter additional SQL Text filtering, such as Table name or SQL Text piece
PRO
PRO 3. SQL Text piece (optional):
DEF sql_text_piece = '&3.';
--
PRO
PRO Filtering SQL to reduce search space.
PRO
PRO 4. SQL_ID (optional):
DEF sql_id = '&4.';
--
PRO
PRO Filtering SQL to reduce search space.
PRO
PRO 5.  Plan Hash Value (optional):
DEF phv = '&5.';
--
PRO
PRO Filtering SQL to reduce search space.
PRO
PRO 6. Parsing Schema Name (optional):
DEF parsing_schema_name = '&6.';
--
SET HEA OFF;
SPO cs_dynamic_driver.sql
          SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "latency"' FROM DUAL WHERE '&&metric_group.' IN ('latency', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "db_time"' FROM DUAL WHERE '&&metric_group.' IN ('db_time', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "calls"' FROM DUAL WHERE '&&metric_group.' IN ('calls', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "rows_sec"' FROM DUAL WHERE '&&metric_group.' IN ('rows_sec', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "rows_exec"' FROM DUAL WHERE '&&metric_group.' IN ('rows_exec', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "reads_sec"' FROM DUAL WHERE '&&metric_group.' IN ('reads_sec', '*')
UNION ALL SELECT '@@cs_internal/cs_sqlstat_chart_internal.sql "reads_exec"' FROM DUAL WHERE '&&metric_group.' IN ('reads_exec', '*')
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