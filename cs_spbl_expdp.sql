----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_expdp.sql
--
-- Purpose:     Packs into staging table one or all SQL Plan Baselines for given SQL_ID
--              and Exports such Baselines using Datapump
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/21
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
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id._SPM_EXPDP' cs_file_name FROM DUAL;
DEF cs_dp_file_name = '';
COL cs_dp_file_name NEW_V cs_dp_file_name NOPRI;
SELECT REPLACE('&&cs_file_name.', '&&cs_file_dir.') AS cs_dp_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
PRO
ACCEPT sys_password CHAR PROMPT 'Enter SYS Password (hidden): ' HIDE
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SQLHV        : &&cs_sqlid.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO TEMP_DIR     : "&&cs_temp_dir." 
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
DEF cs_plan_name = '';
@@cs_internal/cs_spbl_internal_stgtab.sql
@@cs_internal/cs_spbl_internal_stgtab_delete.sql
@@cs_internal/cs_spbl_internal_pack.sql
--
@@cs_internal/cs_temp_dir_create.sql
--
HOS expdp \"sys/&&sys_password.@&&cs_easy_connect_string. AS SYSDBA\" DIRECTORY=CS_TEMP_DIR DUMPFILE=&&cs_dp_file_name..dmp LOGFILE=&&cs_dp_file_name..expdb.log TABLES=&&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline QUERY=\"WHERE signature = &&cs_signature. AND BITAND\(status\, 1\) \<\> 0 AND BITAND\(status\, 2\) \<\> 0\" EXCLUDE=STATISTICS
UNDEF sys_password
--
HOS cp &&cs_temp_dir./&&cs_dp_file_name..* /tmp/
HOS chmod 644 /tmp/&&cs_dp_file_name..*
--
@@cs_internal/cs_temp_dir_drop.sql
--
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
PRO
PRO Exported DataPump Files
PRO ~~~~~~~~~~~~~~~~~~~~~~~
HOS ls -lt /tmp/&&cs_dp_file_name..* 
PRO 
PRO On target Host:
PRO ~~~~~~~~~~~~~~~
PRO 1. $ scp &&cs_host_name.:/tmp/&&cs_dp_file_name..dmp /tmp/
PRO Note: command above works if target and source and on same Region, else scp into your pc/mac then into target
PRO
PRO 2. SQL> @cs_spbl_impdp.sql "&&cs_dp_file_name..dmp" "&&cs_sql_id." "&&cs_plan_name."
PRO Note: execute command above connected into PDB (i.e. &&cs_con_name.)
PRO
--
