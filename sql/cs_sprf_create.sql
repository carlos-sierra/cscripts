----------------------------------------------------------------------------------------
--
-- File name:   cs_sprf_create.sql
--
-- Purpose:     Create a SQL Profile for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2018/07/25
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID and PLAN_HASH_VALUE when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sprf_create.sql
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
DEF cs_script_name = 'cs_sprf_create';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
--
SELECT '&&cs_file_prefix._&&cs_sql_id._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_plans_performance.sql
@@cs_internal/cs_sprf_internal_list.sql
--
PRO
PRO 2. PLAN_HASH_VALUE (required) 
DEF cs_plan_hash_value = "&2.";
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_hash_value." 
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO PLAN_HASH_VAL: &&cs_plan_hash_value. 
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
-- create xfr files
@@cs_sprf_xfr.sql "&&cs_sql_id." "&&cs_plan_hash_value."
-- create sql profile
@cs_sprf_xfr_1_&&cs_sql_id..sql
@cs_sprf_xfr_2_&&cs_plan_hash_value..sql
--
-- continues with xfr spool
@@cs_internal/cs_set.sql
SPO &&cs_file_name..txt APP
--
@@cs_internal/cs_sprf_internal_list.sql
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_hash_value." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
