----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlperf.sql
--
-- Purpose:     SQL performance metrics for a given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/10
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlperf.sql
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
DEF cs_script_name = 'cs_sqlperf';
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
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/cs_plans_summary.sql
@@cs_internal/cs_sqlstats.sql
@@cs_internal/cs_dba_plans_performance.sql
@@cs_internal/cs_plans_stability.sql
@@cs_internal/cs_cursors_performance.sql
@@cs_internal/cs_cursors_not_shared.sql
--@@cs_internal/cs_binds_xml.sql
--@@cs_internal/cs_bind_capture_hist.sql
@@cs_internal/cs_bind_capture_mem.sql
@@cs_internal/cs_acs_internal.sql
@@cs_internal/cs_os_load.sql
@@cs_internal/cs_recent_sessions.sql
@@cs_internal/cs_active_sessions.sql
DEF cs_sqlstat_days = '0.25';
@@cs_internal/cs_&&dba_or_cdb._hist_sqlstat_delta.sql
@@cs_internal/cs_plans_summary.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--