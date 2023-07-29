----------------------------------------------------------------------------------------
--
-- File name:   cs_sprf_drop.sql
--
-- Purpose:     Drop all SQL Profiles for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2022/11/17
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sprf_drop.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
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
DEF cs_script_name = 'cs_sprf_drop';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
@@cs_internal/&&cs_zapper_managed.
--
@@cs_internal/cs_plans_performance.sql 
@@cs_internal/cs_sprf_internal_list.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." 
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO APPLICATION  : &&cs_application_category.
PRO TABLE_OWNER  : &&table_owner.
PRO TABLE_NAME   : &&table_name.
--
@@cs_internal/cs_print_sql_text.sql
@@cs_internal/cs_plans_performance.sql 
@@cs_internal/cs_sprf_internal_list.sql
--
@@cs_internal/cs_sprf_internal_stgtab.sql
@@cs_internal/cs_sprf_internal_pack.sql
--
@@cs_internal/cs_sprf_internal_drop.sql
--
@@cs_internal/cs_sprf_internal_list.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
