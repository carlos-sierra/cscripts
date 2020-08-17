----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlstat_report.sql
--
-- Purpose:     SQL Statistics for a given SQL
--
-- Author:      Carlos Sierra
--
-- Version:     2020/07/14
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlstat_report.sql
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
DEF cs_script_name = 'cs_sqlstat_report';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
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
@@cs_internal/cs_&&dba_or_cdb._hist_sqlstats_by_time.sql
@@cs_internal/cs_plans_awr_1.sql
@@cs_internal/cs_&&dba_or_cdb._hist_sqlstat_delta_sum.sql
@@cs_internal/cs_&&dba_or_cdb._hist_sqlstat_delta.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--