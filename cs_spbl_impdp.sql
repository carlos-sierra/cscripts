----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_impdp.sql
--
-- Purpose:     Imports from Datapump file into a staging table all SQL Plan Baselines
--              and Unpacks from staging table one or all SQL Plan Baselines for given SQL
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/21
--
-- Usage:       Connecting into PDB.
--
--              Enter Datapump filename and SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_impdp.sql
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
DEF cs_script_name = 'cs_spbl_impdp';
--
ACCEPT sys_password CHAR PROMPT 'Enter SYS Password (hidden): ' HIDE
--
PRO
PRO Datapump files on /tmp
PRO ~~~~~~~~~~~~~~~~~~~~~~
HOS ls -lt /tmp/*_SPM_EXPDP.dmp
-- */
PRO
PRO 1. Enter Datapump filename: (exclude directory path /tmp/)
DEF dp_file_name = '&1.';
UNDEF 1;
COL cs_dp_file_name NEW_V cs_dp_file_name NOPRI;
SELECT REPLACE('&&dp_file_name.', '.dmp') cs_dp_file_name FROM DUAL;
--
PRO 2. SQL_ID: 
DEF cs_sql_id = '&2.';
UNDEF 2;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
DEF cs_plan_id = '';
--
@@cs_internal/cs_spbl_internal_stgtab.sql
@@cs_internal/cs_spbl_internal_stgtab_delete.sql
--
@@cs_internal/cs_temp_dir_create.sql
--
HOS cp /tmp/&&cs_dp_file_name..dmp &&cs_temp_dir./
--
-- TABLE_EXISTS_ACTION=APPEND
--
HOS impdp \"sys/&&sys_password.@&&cs_easy_connect_string. AS SYSDBA\" DIRECTORY=CS_TEMP_DIR DUMPFILE=&&cs_dp_file_name..dmp LOGFILE=&&cs_dp_file_name..impdp.log TABLES=&&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline CONTENT=DATA_ONLY
UNDEF sys_password
--
HOS cp &&cs_temp_dir./&&cs_dp_file_name..impdp.log /tmp/
HOS chmod 644 /tmp/&&cs_dp_file_name..impdp.log
--
@@cs_internal/cs_temp_dir_drop.sql
--
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO 3. Plan Name to unpack from staging table: (opt)
DEF cs_plan_name = '&3.';
UNDEF 3;
--
PRO
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_dp_file_name." "&&cs_sql_id." "&&cs_plan_name."
@@cs_internal/cs_spool_id.sql
--
PRO DATAPUMP_FILE: &&dp_file_name.
PRO SQL_ID       : &&cs_sql_id.
PRO SQLHV        : &&cs_sqlid.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO PLAN_NAME    : "&&cs_plan_name."
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
PRO
PRO Unpack plan: "&&cs_plan_name."
DECLARE
  l_plans INTEGER;
BEGIN
  FOR i IN (SELECT sql_handle, obj_name plan_name 
              FROM &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline 
             WHERE signature = COALESCE(TO_NUMBER('&&cs_signature.'), signature)
               AND obj_name = COALESCE('&&cs_plan_name.', obj_name)
             ORDER BY signature, obj_name)
  LOOP
    l_plans := DBMS_SPM.unpack_stgtab_baseline(table_name => '&&cs_stgtab_prefix._stgtab_baseline', table_owner => '&&cs_stgtab_owner.', sql_handle => i.sql_handle, plan_name => i.plan_name);
  END LOOP;
END;
/
--
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_dp_file_name." "&&cs_sql_id." "&&cs_plan_name."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--