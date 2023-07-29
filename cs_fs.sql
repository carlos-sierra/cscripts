----------------------------------------------------------------------------------------
--
-- File name:   cs_fs.sql
--
-- Purpose:     Find SQL statements matching some string
--
-- Author:      Carlos Sierra
--
-- Version:     2023/04/14
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter string to match when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_fs.sql
--
-- Notes:       Developed and tested on 19c
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_fs';
--
PRO 1. Search String: SQL_ID or SQL_HV or PHV or SQL_TEXT piece: (e.g.: ScanQuery, getValues, TableName, IndexName, Scan%Instances)
DEF cs_search_string = '&1.';
UNDEF 1;
COL cs_search_string NEW_V cs_search_string NOPRI;
SELECT /* &&cs_script_name. */ TRIM('&&cs_search_string.') AS cs_search_string FROM DUAL
/
--
PRO
PRO 2. Days for AWR search?: [{0}|0-61]   *** note: awr search is slow! ***
DEF cs_awr_search_days = '&2.';
UNDEF 2;
COL cs_awr_search_days NEW_V cs_awr_search_days NOPRI;
SELECT CASE WHEN TO_NUMBER('&&cs_awr_search_days.') BETWEEN 0 AND 61 THEN TRIM('&&cs_awr_search_days.') ELSE '0' END AS cs_awr_search_days FROM DUAL
/
COL cs_min_snap_id NEW_V cs_min_snap_id NOPRI;
SELECT TRIM(TO_CHAR(NVL(MAX(snap_id), 0))) AS cs_min_snap_id FROM dba_hist_snapshot WHERE end_interval_time < SYSDATE - TO_NUMBER('&&cs_awr_search_days.')
/
--
PRO
PRO 3. Include SYS Parsing Schema?: [{N}|N,Y]
DEF cs_include_sys = '&3.';
UNDEF 3;
COL cs_include_sys NEW_V cs_include_sys NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&cs_include_sys.')) IN ('N', 'Y') THEN UPPER(TRIM('&&cs_include_sys.')) ELSE 'N' END AS cs_include_sys FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_search_string." "&&cs_awr_search_days." "&&cs_include_sys."
@@cs_internal/cs_spool_id.sql
--
PRO SEARCH_STRING: "&&cs_search_string."
PRO AWR_DAYS:      "&&cs_awr_search_days."
PRO INCLUDE_SYS:   "&&cs_include_sys."
--
-- 1 gv$sql - sql statistics
--
DEF cs_sql_id_col = 'PRI';
DEF cs_uncommon_col = 'NOPRI';
DEF cs_delta_col = 'NOPRI';
DEF cs_execs_delta_h = '&&cs_last_snap_mins. mins';
@@cs_internal/cs_latency_internal_cols.sql
@@cs_internal/cs_fs_internal_query_1.sql
--
-- 2 v$sqlstats - sql statistics
--
@@cs_internal/cs_latency_internal_cols.sql
CLEAR BREAK;
@@cs_internal/cs_fs_internal_query_2.sql
--
-- 3 dba_hist_sqlstat - sql statistics
--
DEF cs_execs_delta_h = 'whole history';
@@cs_internal/cs_latency_internal_cols.sql
COL begin_timestamp FOR A23 HEA 'Begin Timestamp' PRI;
COL end_timestamp FOR A23 HEA 'End Timestamp' PRI;
CLEAR BREAK;
@@cs_internal/cs_fs_internal_query_3.sql
--
-- 4 v$sqlstats - sql text
--
@@cs_internal/cs_fs_internal_query_4.sql
--
-- 5 dba_hist_sqltext - sql text
--
@@cs_internal/cs_fs_internal_query_5.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_search_string." "&&cs_awr_search_days." "&&cs_include_sys."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--