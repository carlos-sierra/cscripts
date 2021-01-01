----------------------------------------------------------------------------------------
--
-- File name:   dbrmr.sql | cs_rsrc_mgr_report.sql
--
-- Purpose:     Database Resource Manager (DBRM) Report
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/16
--
-- Usage:       Execute connected to CDB or PDB.
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
DEF cs_script_acronym = 'dbrmr.sql | ';
--
COL pdb_name NEW_V pdb_name FOR A30;
ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_rsrc_mgr_internal_set.sql
@@cs_internal/cs_rsrc_mgr_internal_configuration.sql
@@cs_internal/cs_rsrc_mgr_internal_directives.sql
@@cs_internal/cs_rsrc_mgr_internal_history.sql
@@cs_internal/cs_rsrc_mgr_internal_directives.sql
@@cs_internal/cs_rsrc_mgr_internal_configuration.sql
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--