----------------------------------------------------------------------------------------
--
-- File name:   cs_spch_create.sql
--
-- Purpose:     Create a SQL Patch for given SQL_ID
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
--              SQL> @cs_spch_create.sql
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
DEF cs_script_name = 'cs_spch_create';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = "&1.";
--
SELECT '&&cs_file_prefix._&&cs_sql_id._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_plans_performance.sql
@@cs_internal/cs_spch_internal_list.sql
--
PRO
PRO 2. CBO_HINTS (required) e.g.: GATHER_PLAN_STATISTICS MONITOR FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF') NO_BIND_AWARE
DEF hints_text = "&2.";
--
-- gets some hash on hints to allow multiple patches
COL hash NEW_V hash;
SELECT TO_CHAR(ORA_HASH(q'[&&hints_text.]',9999)) hash FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&hints_text." 
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO CBO HINTS    : "&&hints_text."
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
-- create patch
PRO
PRO Create name: "spch_&&cs_sql_id._&&hash.."
EXEC DBMS_SQLDIAG_INTERNAL.i_create_patch(sql_text => :cs_sql_text, hint_text => q'[&&hints_text.]', name => 'spch_&&cs_sql_id._&&hash.', description => q'[cs_spch_create.sql /*+ &&hints_text. */ &&cs_reference_sanitized.]');
--
@@cs_internal/cs_spch_internal_list.sql
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&hints_text." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
