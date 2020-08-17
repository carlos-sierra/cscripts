----------------------------------------------------------------------------------------
--
-- File name:   cs_rsrc_mgr_drop.sql
--
-- Purpose:     Drop Resource Manager Plan
--
-- Author:      Carlos Sierra
--
-- Version:     2020/04/22
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_rsrc_mgr_drop.sql
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
DEF cs_script_name = 'cs_rsrc_mgr_drop';
--
COL pdb_name NEW_V pdb_name FOR A30;
ALTER SESSION SET container = CDB$ROOT;
--
SELECT plan FROM dba_cdb_rsrc_plans WHERE mandatory = 'NO' ORDER BY plan;
PRO
PRO 1. Enter Plan to drop:
DEF cs_resource_manager_plan = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_rsrc_mgr_internal_set.sql
@@cs_internal/cs_rsrc_mgr_internal_directives.sql
--
ALTER SYSTEM SET resource_manager_plan = '';
--
-- dont drop it since it may cause standby to crash!
--
/*
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
  l_plan VARCHAR2(30) := '&&cs_resource_manager_plan.';
BEGIN
  DBMS_RESOURCE_MANAGER.clear_pending_area;
  DBMS_RESOURCE_MANAGER.create_pending_area;
  --
  DBMS_RESOURCE_MANAGER.delete_cdb_plan(plan => l_plan);
  --
  DBMS_RESOURCE_MANAGER.validate_pending_area;
  DBMS_RESOURCE_MANAGER.submit_pending_area;
END;
/
WHENEVER SQLERROR CONTINUE;
*/
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