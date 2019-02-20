----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_zap.sql
--
-- Purpose:     Zap a SQL Plan Baseline for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2018/07/25
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_zap.sql
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
DEF cs_script_name = 'cs_spbl_zap';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
--
PRO
PRO 2. REPORT_ONLY: [{Y}|N]
DEF report_only = '&2.';
COL report_only NEW_V report_only;
SELECT NVL(UPPER(TRIM('&&report_only.')),'Y') report_only FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_sql_id._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&report_only."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO REPORT_ONLY  : "&&report_only."
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/cs_plans_performance.sql
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO EXECUTING MIGHTY ZAPPER
PRO ~~~~~~~~~~~~~~~~~~~~~~~
PRO please wait...
PRO
ALTER SESSION SET CONTAINER = CDB$ROOT;
SET SERVEROUT ON;
EXEC c##iod.IOD_SPM.fpz(p_report_only => '&&report_only.', p_pdb_name => '&&cs_con_name.', p_sql_id => '&&cs_sql_id.');
SET SERVEROUT OFF;
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&report_only."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
