----------------------------------------------------------------------------------------
--
-- File name:   cs_spch_first_rows.sql
--
-- Purpose:     Create a SQL Patch with FIRST_ROWS for given SQL_ID, and drops SQL Profile and SQL Plan Baselines
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/21
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID and PLAN_HASH_VALUE when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spch_first_rows.sql
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
DEF cs_script_name = 'cs_spch_first_rows';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = "&1.";
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_&&dba_or_cdb._plans_performance.sql
@@cs_internal/cs_spch_internal_list.sql
--
COL hints_text NEW_V hints_text NOPRI;
SELECT q'[FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF')]'||CASE WHEN '&&cs_kiev_table_name.' IS NOT NULL THEN ' LEADING(@SEL$1 &&cs_kiev_table_name.)' END AS hints_text FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&hints_text." 
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SQLHV        : &&cs_sqlid.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO CBO HINTS    : "&&hints_text."
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
-- drop existing patch if any
@@cs_internal/cs_spch_internal_drop.sql
--
PRO
PRO Create name: "spch_&&cs_sql_id."
@@cs_internal/cs_spch_internal_create.sql
--
@@cs_internal/cs_spch_internal_list.sql
--
-- drop existing profile if any
@@cs_internal/cs_sprf_internal_stgtab.sql
@@cs_internal/cs_sprf_internal_pack.sql
@@cs_internal/cs_sprf_internal_drop.sql
--
-- drop existing baseline if any
DEF cs_plan_name = '';
@@cs_internal/cs_spbl_internal_stgtab.sql
@@cs_internal/cs_spbl_internal_pack.sql
DECLARE
  l_plans INTEGER := 0;
BEGIN
  IF '&&cs_sql_handle.' IS NOT NULL THEN
    l_plans := DBMS_SPM.drop_sql_plan_baseline(sql_handle => '&&cs_sql_handle.');
  END IF;
END;
/
--
-- @@cs_internal/cs_plans_summary.sql
-- @@cs_internal/cs_plans_stability.sql
@@cs_internal/cs_sqlstats.sql
@@cs_internal/cs_&&dba_or_cdb._plans_performance.sql
@@cs_internal/cs_cursors_performance.sql
-- @@cs_internal/cs_cursors_not_shared.sql
--@@cs_internal/cs_binds_xml.sql
--@@cs_internal/cs_bind_capture_hist.sql
-- @@cs_internal/cs_bind_capture_mem.sql
-- @@cs_internal/cs_acs_internal.sql
-- @@cs_internal/cs_os_load.sql
DEF cs_sqlstat_days = '0.25';
@@cs_internal/cs_&&dba_or_cdb._hist_sqlstat_delta.sql
-- @@cs_internal/cs_recent_sessions.sql
@@cs_internal/cs_active_sessions.sql
@@cs_internal/cs_plans_stability.sql
@@cs_internal/cs_plans_summary.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&hints_text." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
