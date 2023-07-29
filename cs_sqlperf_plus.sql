----------------------------------------------------------------------------------------
--
-- File name:   pp.sql | cs_sqlperf_plus.sql
--
-- Purpose:     Basic SQL performance metrics for a given SQL_ID + Top Keys
--
-- Author:      Carlos Sierra
--
-- Version:     2023/05/29
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlperf_plus.sql
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
@@cs_internal/cs_cdb_warn2.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sqlperf_plus';
DEF cs_script_acronym = 'pp.sql | ';
--
DEF cs_sql_id_col = 'NOPRI';
DEF cs_uncommon_col = 'NOPRI';
DEF cs_delta_col = 'NOPRI';
--
DEF cs_binds_days = '1';
DEF cs_sqlstat_days = '14';
DEF cs_scope_1 = 'last &&cs_sqlstat_days. day(s)';
@@cs_internal/cs_sample_time_boundaries.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
DEF cs_filter_1 = 'sql_id = ''&&cs_sql_id.''';
DEF cs_filter_2 = '1 = 1';
DEF cs2_sql_text_piece = '';
--
@@cs_internal/cs_last_snap.sql
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
@@cs_internal/cs_spool_id_list_sql_id.sql
@@cs_internal/cs_print_sql_text.sql
@@cs_internal/cs_plans_performance.sql 
DEF cs_scope_1 = 'last &&cs_sqlstat_days. day(s)';
@@cs_internal/cs_dba_hist_sqlstat_global.sql
DEF cs_scope_1 = '';
@@cs_internal/cs_gv_sqlstat_global.sql
--
-- @@cs_internal/&&cs_set_container_to_cdb_root.
-- DEF cs_scope_1 = '- SCOPE CDB$ROOT';
-- DEF cs_filter_1 = 'get_sql_hv(sql_text) = ''&&cs_sql_hv.'' AND sql_text LIKE SUBSTR(:cs_sql_text_1000, 1, 40)||''%''';
-- DEF cs_sql_id_col = 'PRI';
-- @@cs_internal/cs_gv_sql_global.sql 
-- DEF cs_sql_id_col = 'NOPRI';
-- DEF cs_filter_1 = 'sql_id = ''&&cs_sql_id.''';
-- @@cs_internal/&&cs_set_container_to_curr_pdb.
--
-- DEF cs_scope_1 = '- SCOPE &&cs_con_name.';
DEF cs_scope_1 = '';
@@cs_internal/cs_gv_sql_global.sql 
@@cs_internal/cs_gv_sql_stability.sql
-- @@cs_internal/cs_cursors_not_shared.sql
--
DEF cs_scope_1 = '- last &&cs_sqlstat_days. day(s)';
@@cs_internal/cs_dba_hist_sqlstat_daily.sql
--
SPO OFF;
DEF cs_sqlstat_days = '1';
DEF cs_scope_1 = '- last &&cs_sqlstat_days. day(s)';
@@cs_internal/cs_sample_time_boundaries.sql
@@cs_internal/cs_snap_id_from_and_to.sql
SPO &&cs_file_name..txt APP;
@@cs_internal/cs_dba_hist_sqlstat_hourly.sql
--
SPO OFF;
DEF cs_sqlstat_days = '0.5';
DEF cs_scope_1 = '- last &&cs_sqlstat_days. day(s)';
@@cs_internal/cs_sample_time_boundaries.sql
@@cs_internal/cs_snap_id_from_and_to.sql
SPO &&cs_file_name..txt APP;
@@cs_internal/cs_dba_hist_sqlstat_detailed.sql
--
-- PRO
-- PRO ********************************************************************************************************************************************************************************************************
-- PRO
-- @@cs_internal/cs_sqlmon_hist_internal.sql
-- @@cs_internal/cs_sqlmon_mem_internal.sql
PRO
PRO ********************************************************************************************************************************************************************************************************
PRO
-- @@cs_internal/cs_binds_xml.sql
-- @@cs_internal/cs_bind_capture_hist.sql
@@cs_internal/cs_bind_capture_mem.sql
-- @@cs_internal/cs_acs_internal.sql
-- PRO
-- PRO ********************************************************************************************************************************************************************************************************
-- PRO
@@cs_internal/cs_plans_mem_0.sql
-- @@cs_internal/cs_plans_mem_1.sql
-- @@cs_internal/cs_plans_mem_2.sql
-- @@cs_internal/cs_plans_awr_1.sql
-- @@cs_internal/cs_plans_awr_2.sql
-- @@cs_internal/cs_spbl_internal_plan.sql
PRO
PRO ********************************************************************************************************************************************************************************************************
PRO
@@cs_internal/cs_recent_sessions.sql
@@cs_internal/cs_active_sessions.sql
-- @@cs_internal/cs_load_per_machine.sql
-- @@cs_internal/cs_sql_ash.sql
-- PRO
-- PRO ********************************************************************************************************************************************************************************************************
-- PRO
-- @@cs_internal/cs_spch_internal_list.sql
-- @@cs_internal/cs_sprf_internal_list.sql
-- @@cs_internal/cs_spbl_internal_list.sql
-- PRO
-- PRO ********************************************************************************************************************************************************************************************************
-- PRO
-- @@cs_internal/&&zapper_19_actions_script.
-- PRO
-- PRO ********************************************************************************************************************************************************************************************************
-- PRO
-- @@cs_internal/&&oem_me_sqlperf_script.
-- PRO
-- PRO ********************************************************************************************************************************************************************************************************
-- PRO
-- @@cs_internal/cs_dependency_segments.sql
-- @@cs_internal/cs_dependency_tables.sql
-- @@cs_internal/cs_dependency_indexes.sql
-- @@cs_internal/cs_dependency_part_keys.sql
-- @@cs_internal/cs_dependency_index_columns.sql
-- @@cs_internal/cs_dependency_table_columns.sql
-- @@cs_internal/cs_dependency_lobs.sql
-- PRO
-- PRO ********************************************************************************************************************************************************************************************************
-- PRO
-- @@cs_internal/cs_dependency_metadata.sql
-- @@cs_internal/cs_dependency_kievlive.sql
PRO
PRO ********************************************************************************************************************************************************************************************************
PRO
DEF cs_num_rows_limit_display = '100M';
DEF cs_num_rows_limit_number = '1e8';
@@cs_internal/cs_top_primary_keys_table.sql
-- @@cs_internal/cs_top_keys_sql.sql
PRO
PRO ********************************************************************************************************************************************************************************************************
PRO
DEF cs_scope_1 = '';
@@cs_internal/cs_gv_sql_global.sql 
@@cs_internal/cs_gv_sql_stability.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
@@cs_internal/cs_cdb_warn2.sql
--