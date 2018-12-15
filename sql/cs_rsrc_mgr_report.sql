----------------------------------------------------------------------------------------
--
-- File name:   cs_rsrc_mgr_report.sql
--
-- Purpose:     Plan directives, configuration and history for current plan
--
-- Author:      Carlos Sierra
--
-- Version:     2018/09/03
--
-- Usage:       Execute connected to CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_rsrc_mgr_report.sql
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
DEF cs_script_name = 'cs_rsrc_mgr_report';
--
COL pdb_name NEW_V pdb_name FOR A30;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') pdb_name FROM DUAL;
ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_rsrc_mgr_internal.sql
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--