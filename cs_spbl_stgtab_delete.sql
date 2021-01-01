----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_stgtab_delete.sql
--
-- Purpose:     Deletes Staging Table for SQL Plan Baselines
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/10
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID (opt) when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_stgtab_delete.sql
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
DEF cs_script_name = 'cs_spbl_stgtab_delete';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
PRO 1. SQL_ID (opt): 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
@@cs_internal/cs_signature.sql
--
DEF cs_plan_id = '';
--
PRO
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
@@cs_internal/cs_spbl_internal_stgtab.sql
@@cs_internal/cs_spbl_internal_stgtab_delete.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
