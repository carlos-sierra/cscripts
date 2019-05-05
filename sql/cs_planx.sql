----------------------------------------------------------------------------------------
--
-- File name:   cs_planx.sql
--
-- Purpose:     Execution Plans and SQL performance metrics for a given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2018/11/25
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_planx.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
--              To further dive into SQL performance diagnostics use SQLd360.
--             
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_planx';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/cs_plans_summary.sql
@@cs_internal/cs_sqlstats.sql
@@cs_internal/cs_plans_performance.sql
@@cs_internal/cs_plans_stability.sql
@@cs_internal/cs_cursors_performance.sql
@@cs_internal/cs_cursors_not_shared.sql
@@cs_internal/cs_bind_capture.sql
@@cs_internal/cs_acs_internal.sql
@@cs_internal/cs_os_load.sql
@@cs_internal/cs_recent_sessions.sql
@@cs_internal/cs_active_sessions.sql
@@cs_internal/cs_plans_summary.sql
@@cs_internal/cs_plans_mem_1.sql
@@cs_internal/cs_plans_mem_2.sql
@@cs_internal/cs_dba_hist_sqlstat_delta.sql
@@cs_internal/cs_plans_awr_1.sql
@@cs_internal/cs_dba_hist_sqlstat_delta_sum.sql
@@cs_internal/cs_plans_awr_2.sql
@@cs_internal/cs_spch_internal_list.sql
@@cs_internal/cs_sprf_internal_list.sql
@@cs_internal/cs_spbl_internal_list.sql
@@cs_internal/cs_spbl_internal_plan.sql
@@cs_internal/cs_dependency_tables.sql
@@cs_internal/cs_dependency_indexes.sql
@@cs_internal/cs_dependency_index_columns.sql
@@cs_internal/cs_dependency_table_columns.sql
@@cs_internal/cs_dependency_lobs.sql
@@cs_internal/cs_dependency_kievlive.sql
@@cs_internal/cs_top_keys.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--