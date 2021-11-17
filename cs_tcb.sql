----------------------------------------------------------------------------------------
--
-- File name:   cs_tcb.sql
--
-- Purpose:     Executes Test Case Builder (TCB) for given SQL_ID
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
--              SQL> @cs_tcb.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_tcb';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
PRO
PRO 2. Sampling Percent: [{100}|1-100]
DEF cs_samplingPercent = '&2.';
UNDEF 2;
COL cs_samplingPercent NEW_V cs_samplingPercent NOPRI;
SELECT CASE WHEN TO_NUMBER('&&cs_samplingPercent.') BETWEEN 1 AND 100 THEN '&&cs_samplingPercent.' ELSE '100' END AS cs_samplingPercent FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id._TCB' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
PRO
ACCEPT sys_password CHAR PROMPT 'Enter SYS Password (hidden): ' HIDE
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_samplingPercent."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SQLHV        : &&cs_sqlid.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO SAMPLING_PERC: "&&cs_samplingPercent." [{100}|1-100]
PRO PARSE_SCHEMA : &&cs_parsing_schema_name.
PRO TEMP_DIR     : "&&cs_temp_dir." 
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/cs_temp_dir_create.sql
--
ALTER SESSION SET current_schema = &&cs_parsing_schema_name.;
--
PRO DBMS_SQLDIAG.export_sql_testcase
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
VAR testcase CLOB;
EXEC DBMS_SQLDIAG.export_sql_testcase(directory => 'CS_TEMP_DIR', sql_id => '&&cs_sql_id.', exportData => TRUE, samplingPercent => TO_NUMBER('&&cs_samplingPercent.'), testcase_name => 'TCB_&&cs_sql_id._&&cs_file_timestamp._', testcase => :testcase);
--
ALTER SESSION SET current_schema = &&cs_current_schema.;
--
HOS cp &&cs_temp_dir./TCB_&&cs_sql_id.* /tmp/
HOS chmod 644 /tmp/TCB_&&cs_sql_id.*
--
@@cs_internal/cs_temp_dir_drop.sql
--
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_samplingPercent."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
PRO
PRO TCB files
PRO ~~~~~~~~~
HOS ls -lt /tmp/TCB_&&cs_sql_id.*
PRO 
HOS zip -mj /tmp/TCB_&&cs_sql_id._&&cs_file_timestamp..zip /tmp/TCB_&&cs_sql_id._&&cs_file_timestamp._*
PRO
PRO To get TCB:
PRO ~~~~~~~~~~~
PRO scp &&cs_host_name.:/tmp/TCB_&&cs_sql_id._&&cs_file_timestamp..zip .
PRO
--