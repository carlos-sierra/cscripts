DECLARE
  l_plan VARCHAR2(30) := 'IOD_COMPUTE_PLAN';
BEGIN
  DBMS_RESOURCE_MANAGER.clear_pending_area;
  DBMS_RESOURCE_MANAGER.create_pending_area;
 
  DBMS_RESOURCE_MANAGER.create_cdb_plan(
    plan    => l_plan,
    comment => 'A IOD Compute emergency CDB resource plan');
 
  DBMS_RESOURCE_MANAGER.create_cdb_plan_directive(
    plan                  => l_plan,
    pluggable_database    => 'COMPUTE_PHX_4X',
    shares                => 100,
    utilization_limit     => 100,
    parallel_server_limit => 100);
 
  DBMS_RESOURCE_MANAGER.validate_pending_area;
  DBMS_RESOURCE_MANAGER.submit_pending_area;
END;
/
 
SELECT plan,
       pluggable_database,
       shares,
       utilization_limit AS util,
       parallel_server_limit AS parallel
FROM   dba_cdb_rsrc_plan_directives
WHERE  plan = 'IOD_COMPUTE_PLAN'
ORDER BY pluggable_database;
 
alter system set resource_manager_plan='IOD_COMPUTE_PLAN';