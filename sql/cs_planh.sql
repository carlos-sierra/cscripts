----------------------------------------------------------------------------------------
--
-- File name:   cs_planh.sql
--
-- Purpose:     Execution Plans in AWR for a given SQL
--
-- Author:      Carlos Sierra
--
-- Version:     2018/07/29
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
DEF cs_script_name = 'cs_planh';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
--
DEF cs_plan_hash_value = '';
@@cs_internal/cs_plans_awr_1.sql
--
PRO
PRO 2. PLAN_HASH_VALUE (opt):
DEF cs_plan_hash_value = '&2.';
--
SELECT '&&cs_file_prefix._&&cs_sql_id._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
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
@@cs_internal/cs_plans_awr_1.sql
@@cs_internal/cs_plans_awr_2.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_hash_value."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--