----------------------------------------------------------------------------------------
--
-- File name:   z.sql | cs_spbl_zap.sql
--
-- Purpose:     Zap a SQL Plan Baseline for given SQL_ID or entire PDB or entire CDB
--
-- Author:      Carlos Sierra
--
-- Version:     2022/08/10
--
-- Usage:       Connecting into PDB or CDB.
--
--              Enter optional SQL_ID when requested.
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
DEF cs_script_acronym = 'z.sql | ';
--
PRO 1. SQL_ID: (opt)
DEF cs_sql_id = '&1.';
UNDEF 1;
--
PRO
PRO 2. REPORT_ONLY: [{N}|Y]
DEF report_only = '&2.';
UNDEF 2;
COL report_only NEW_V report_only NOPRI;
SELECT NVL(UPPER(TRIM('&&report_only.')),'N') AS report_only FROM DUAL;
--
PRO
PRO 3. DEBUG: [{N}|Y]
DEF debug = '&3.';
UNDEF 3;
COL debug NEW_V debug NOPRI;
SELECT NVL(UPPER(TRIM('&&debug.')),'N') AS debug FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&report_only."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SQLHV        : &&cs_sqlid.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO REPORT_ONLY  : "&&report_only."
PRO DEBUG        : "&&debug."
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
PRO
PRO EXECUTING ZAPPER
PRO ~~~~~~~~~~~~~~~~
PRO please wait... (may take a while if there are other &&cs_tools_schema. APIs executing)
PRO
@@cs_internal/&&cs_set_container_to_cdb_root.
SET SERVEROUT ON;
EXEC &&cs_tools_schema..IOD_SPM.fpz(p_report_only => '&&report_only.', p_debug => '&&debug.', p_pdb_name => (CASE NVL('&&cs_con_name.', 'CDB$ROOT') WHEN 'CDB$ROOT' THEN 'ALL' ELSE '&&cs_con_name.' END), p_sql_id => NVL('&&cs_sql_id.', 'ALL'));
SET SERVEROUT OFF;
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&report_only." "&&debug."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
