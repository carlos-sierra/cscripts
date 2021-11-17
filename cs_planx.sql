----------------------------------------------------------------------------------------
--
-- File name:   x.sql | cs_planx.sql
--
-- Purpose:     Execution Plans and SQL performance metrics for a given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/21
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
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_planx';
DEF cs_script_acronym = 'x.sql | ';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
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
PRO SQLHV        : &&cs_sqlid.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO APPLICATION  : &&cs_application_category.
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/cs_plans_summary.sql
@@cs_internal/cs_plans_stability.sql
@@cs_internal/&&oem_me_sqlperf_script.
@@cs_internal/cs_sqlmon_hist_internal.sql
@@cs_internal/cs_sqlmon_mem_internal.sql
@@cs_internal/cs_sqlstats.sql
@@cs_internal/cs_&&dba_or_cdb._plans_performance.sql
@@cs_internal/cs_cursors_performance.sql
@@cs_internal/cs_cursors_not_shared.sql
@@cs_internal/cs_binds_xml.sql
@@cs_internal/cs_bind_capture_hist.sql
@@cs_internal/cs_bind_capture_mem.sql
@@cs_internal/cs_acs_internal.sql
@@cs_internal/cs_os_load.sql
@@cs_internal/cs_load_per_machine.sql
@@cs_internal/cs_plans_stability.sql
@@cs_internal/cs_plans_summary.sql
@@cs_internal/cs_plans_mem_1.sql
@@cs_internal/cs_plans_mem_2.sql
@@cs_internal/cs_plans_awr_1.sql
@@cs_internal/cs_&&dba_or_cdb._hist_sqlstats_by_time.sql
@@cs_internal/cs_&&dba_or_cdb._hist_sqlstat_delta_sum.sql
@@cs_internal/cs_&&dba_or_cdb._hist_sqlstat_delta.sql
@@cs_internal/cs_recent_sessions.sql
@@cs_internal/cs_active_sessions.sql
@@cs_internal/cs_sql_ash.sql
@@cs_internal/cs_plans_awr_2.sql
@@cs_internal/cs_spch_internal_list.sql
@@cs_internal/cs_sprf_internal_list.sql
@@cs_internal/cs_spbl_internal_list.sql
@@cs_internal/cs_spbl_internal_plan.sql
@@cs_internal/&&zapper_19_actions_script.
@@cs_internal/cs_dependency_segments.sql
@@cs_internal/cs_dependency_tables.sql
@@cs_internal/cs_dependency_indexes.sql
@@cs_internal/cs_dependency_part_keys.sql
@@cs_internal/cs_dependency_index_columns.sql
@@cs_internal/cs_dependency_table_columns.sql
@@cs_internal/cs_dependency_lobs.sql
@@cs_internal/cs_dependency_metadata.sql
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