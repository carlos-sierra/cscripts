----------------------------------------------------------------------------------------
--
-- File name:   cs_rsrc_mgr_create.sql
--
-- Purpose:     Create Resource Manager Plan
--
-- Author:      Carlos Sierra
--
-- Version:     2019/11/01
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_rsrc_mgr_create.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
DEF cs_resource_manager_plan = 'IOD_CDB_PLAN';
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_rsrc_mgr_create';
DEF cs_parallel_server_limit = '50';
DEF default_utilization_limit = '45';
DEF default_shares = '45';
DEF min_utilization_limit = '24';
DEF max_utilization_limit = '65';
DEF min_shares = '24';
DEF max_shares = '65';
--
COL pdb_name NEW_V pdb_name FOR A30;
ALTER SESSION SET container = CDB$ROOT;
--
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
  l_count NUMBER;
  l_plan VARCHAR2(30) := '&&cs_resource_manager_plan.';
  l_pdbs NUMBER;
  l_shares NUMBER;
  l_utilization_limit NUMBER;
  l_parallel_server_limit NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_count FROM dba_cdb_rsrc_plans WHERE plan = l_plan AND mandatory = 'NO'; 
  IF l_count > 0 THEN
    raise_application_error(-20000, l_plan||' already exists!');
  END IF;
  --
  SELECT COUNT(*) INTO l_pdbs FROM v$containers WHERE con_id > 2 AND open_mode = 'READ WRITE';
  --
  l_parallel_server_limit := &&cs_parallel_server_limit.;
  IF l_pdbs <= 5 THEN
    l_shares := &&max_shares.;
    l_utilization_limit := &&max_utilization_limit.;
  ELSIF l_pdbs <= 10 THEN
    l_shares := &&default_shares.;
    l_utilization_limit := &&default_utilization_limit.;
  ELSE
    l_shares := &&min_shares.;
    l_utilization_limit := &&min_utilization_limit.;
  END IF;
  --
  DBMS_RESOURCE_MANAGER.clear_pending_area;
  DBMS_RESOURCE_MANAGER.create_pending_area;
  --
  DBMS_RESOURCE_MANAGER.create_cdb_plan(
    plan    => l_plan,
    comment => '&&cs_reference.');
  --
  DBMS_RESOURCE_MANAGER.update_cdb_autotask_directive(
    plan                      => l_plan, 
    new_shares                => 12, 
    new_utilization_limit     => 12,
    new_parallel_server_limit => 50);
  --
  DBMS_RESOURCE_MANAGER.update_cdb_default_directive(
    plan                      => l_plan, 
    new_shares                => l_shares, 
    new_utilization_limit     => l_utilization_limit,
    new_parallel_server_limit => l_parallel_server_limit);
  --
  FOR i IN (SELECT name AS pluggable_database FROM v$containers WHERE con_id > 2 AND open_mode = 'READ WRITE' ORDER BY name)
  LOOP
    DBMS_RESOURCE_MANAGER.create_cdb_plan_directive(
      plan                  => l_plan, 
      pluggable_database    => i.pluggable_database, 
      shares                => l_shares, 
      utilization_limit     => l_utilization_limit,
      parallel_server_limit => l_parallel_server_limit);
  END LOOP;
  --
  DBMS_RESOURCE_MANAGER.validate_pending_area;
  DBMS_RESOURCE_MANAGER.submit_pending_area;
END;
/
WHENEVER SQLERROR CONTINUE;
--
ALTER SYSTEM SET resource_manager_plan = 'FORCE:&&cs_resource_manager_plan.';
--
PRO wait...
EXEC DBMS_LOCK.sleep(10);
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