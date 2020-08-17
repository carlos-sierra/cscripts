----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_expdp.sql
--
-- Purpose:     Packs into staging table one or all SQL Plan Baselines for given SQL_ID
--              and Exports such Baselines using Datapump
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/10
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_expdp.sql
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
DEF cs_script_name = 'cs_spbl_expdp';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_dba_plans_performance.sql
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO 2. Enabled and Accepted PLAN_NAME (opt):
DEF cs_plan_name = '&2.';
UNDEF 2;
--
DEF cs_plan_id = '';
COL cs_plan_id NEW_V cs_plan_id NOPRI;
SELECT TO_CHAR(plan_id) cs_plan_id
  FROM sys.sqlobj$
 WHERE obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND signature = TO_NUMBER('&&cs_signature.')
   AND name = '&&cs_plan_name.'
/
--
DEF cs_dp_file_name = '';
COL cs_dp_file_name NEW_V cs_dp_file_name NOPRI;
SELECT REPLACE('&&cs_file_prefix.', '&&cs_file_dir.')||'_SQL_ID_&&cs_sql_id.'||CASE WHEN '&&cs_plan_name.' IS NOT NULL THEN '_&&cs_plan_name.' END AS cs_dp_file_name FROM DUAL;
--
PRO
ACCEPT sys_password CHAR PROMPT 'Enter SYS Password (hidden): ' HIDE
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_name."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO PLAN_NAME    : "&&cs_plan_name."
PRO PLAN_ID      : "&&cs_plan_id."
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/cs_dba_plans_performance.sql
@@cs_internal/cs_spbl_internal_list.sql
--
@@cs_internal/cs_spbl_internal_stgtab.sql
@@cs_internal/cs_spbl_internal_stgtab_delete.sql
@@cs_internal/cs_spbl_internal_pack.sql
--
@@cs_internal/cs_temp_dir_create.sql
--
-- enabled: BITAND(status, 1) <> 0
-- accepted: BITAND(status, 2) <> 0
-- fixed: BITAND(status, 4) <> 0
HOS expdp \"sys/&&sys_password.@&&cs_easy_connect_string. AS SYSDBA\" DIRECTORY=CS_TEMP DUMPFILE=&&cs_dp_file_name..dmp LOGFILE=&&cs_dp_file_name._expdp.log TABLES=&&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline QUERY=\"WHERE signature = &&cs_signature. AND plan_id = COALESCE\(TO_NUMBER\(\'&&cs_plan_id.\'\)\, plan_id\) AND BITAND\(status\, 1\) \<\> 0 AND BITAND\(status\, 2\) \<\> 0\" EXCLUDE=STATISTICS
UNDEF sys_password
--
HOS cp &&cs_temp_dir./&&cs_dp_file_name..dmp /tmp/
HOS chmod 644 /tmp/&&cs_dp_file_name..dmp
HOS cp &&cs_temp_dir./&&cs_dp_file_name._expdp.log /tmp/
HOS chmod 644 /tmp/&&cs_dp_file_name._expdp.log
--
@@cs_internal/cs_temp_dir_drop.sql
--
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_name."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
PRO
PRO Exported DataPump File
PRO ~~~~~~~~~~~~~~~~~~~~~~
HOS ls -l /tmp/&&cs_dp_file_name..dmp
PRO 
PRO On target Host:
PRO ~~~~~~~~~~~~~~~
PRO 1. $ scp &&cs_host_name.:/tmp/&&cs_dp_file_name..dmp /tmp/
PRO Note: if on same Region
PRO 2. SQL> @cs_spbl_impdp.sql "&&cs_dp_file_name..dmp" "&&cs_sql_id." "&&cs_plan_name."
PRO Note: connected into PDB (i.e. &&cs_con_name.)
PRO
--
