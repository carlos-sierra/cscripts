----------------------------------------------------------------------------------------
--
-- File name:   ssri.sql | cs_sqlstat_report_iod.sql
--
-- Purpose:     SQL Statistics Report (IOD) - detailed(1m)
--
-- Author:      Carlos Sierra
--
-- Version:     2022/08/17
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlstat_report_iod.sql
--
-- Notes:       Developed and tested on 19c
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
-- @@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sqlstat_report_iod';
DEF cs_script_acronym = 'ssri.sql | ';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF cs_hours_range_default = '3';
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
DEF cs_scope_1 = 'between &&cs_sample_time_from. and &&cs_sample_time_to.';
--
PRO
PRO Uncommon Columns include: PL/SQL, Cluster, Java, End of Fetch, Parses, Invalidations, Loads, Sorts, Direct Writes, Physical Requests for Reads and Writes, etc.
PRO Selecting 'Y' widens output report.
PRO
PRO 3. Include Uncommon Columns [{N}|Y]:
DEF cs_include_uncommon_columns = '&3.';
UNDEF 3;
COL cs_include_uncommon_columns NEW_V cs_include_uncommon_columns NOPRI;
COL cs_uncommon_col NEW_V cs_uncommon_col NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&cs_include_uncommon_columns.')) IN ('N', 'Y') THEN UPPER(TRIM('&&cs_include_uncommon_columns.')) ELSE 'N' END AS cs_include_uncommon_columns,
       CASE UPPER(TRIM('&&cs_include_uncommon_columns.')) WHEN 'Y' THEN 'PRI' ELSE 'NOPRI' END AS cs_uncommon_col
FROM DUAL
/
--
PRO
PRO Delta Columns refer to multiple raw counters considering the range of dates provided.
PRO Selecting 'Y' widens output report.
PRO
PRO 4. Include Delta Columns [{N}|Y]:
DEF cs_include_delta_columns = '&4.';
UNDEF 4;
COL cs_include_delta_columns NEW_V cs_include_delta_columns NOPRI;
COL cs_delta_col NEW_V cs_delta_col NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&cs_include_delta_columns.')) IN ('N', 'Y') THEN UPPER(TRIM('&&cs_include_delta_columns.')) ELSE 'N' END AS cs_include_delta_columns,
       CASE UPPER(TRIM('&&cs_include_delta_columns.')) WHEN 'Y' THEN 'PRI' ELSE 'NOPRI' END AS cs_delta_col
FROM DUAL
/
--
PRO
PRO 5. SQL Text piece (e.g.: ScanQuery, getValues, TableName, IndexName):
DEF cs2_sql_text_piece = '&5.';
UNDEF 5;
--
PRO
PRO 6. SQL_ID (opt): 
DEF cs_sql_id = '&6.';
UNDEF 6;
DEF cs_filter_1 = '';
DEF cs_filter_2 = '';
COL cs_filter_1 NEW_V cs_filter_1 NOPRI;
COL cs_filter_2 NEW_V cs_filter_2 NOPRI;
COL cs_sql_id_col NEW_V cs_sql_id_col NOPRI;
SELECT CASE LENGTH('&&cs_sql_id.') WHEN 13 THEN 'sql_id = ''&&cs_sql_id.''' ELSE '1 = 1' END AS cs_filter_1,
       CASE '&&cs_con_id.' WHEN '1' THEN '1 = 1' ELSE 'con_id = &&cs_con_id.' END AS cs_filter_2,
       CASE LENGTH('&&cs_sql_id.') WHEN 13 THEN 'NOPRI' ELSE 'PRI' END AS cs_sql_id_col
FROM DUAL
/
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_include_uncommon_columns." "&&cs_include_delta_columns." "&&cs2_sql_text_piece." "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO UNCOMMON_COLS: "&&cs_include_uncommon_columns."
PRO DELTA_COLS   : "&&cs_include_delta_columns."
PRO SQL_TEXT     : "&&cs2_sql_text_piece."
PRO SQL_ID       : "&&cs_sql_id."
--
-- @@cs_internal/&&cs_set_container_to_cdb_root.
--
@@cs_internal/cs_iod_sqlstats_detailed.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_include_uncommon_columns." "&&cs_include_delta_columns." "&&cs2_sql_text_piece." "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
--
-- @@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--