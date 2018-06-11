SET SERVEROUT ON;
DECLARE
  gk_plan CONSTANT VARCHAR2(128) := 'IOD_CDB_PLAN';
  gk_pluggable_database CONSTANT VARCHAR2(128) := 'VNINTEGNEXTREGAP1';
  gk_shares CONSTANT NUMBER := 10;
  gk_utilization_limit CONSTANT NUMBER := 30;
  gk_parallel_server_limit CONSTANT NUMBER := 50;
  gk_date_format CONSTANT VARCHAR2(30) := 'YYYY-MM-DD"T"HH24:MI:SS';
  l_open_mode VARCHAR2(20);
  l_count NUMBER;
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    RETURN;
  END IF;
  SELECT COUNT(*) INTO l_count FROM dba_cdb_rsrc_plans WHERE plan = gk_plan;
  IF l_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Create RSRC MGR Plan: '||gk_plan);
    DBMS_RESOURCE_MANAGER.clear_pending_area;
    DBMS_RESOURCE_MANAGER.create_pending_area;
    DBMS_RESOURCE_MANAGER.create_cdb_plan (
      plan    => gk_plan,
      comment => 'IOD_RSRC_MGR '||TO_CHAR(SYSDATE, gk_date_format)
    );
    DBMS_RESOURCE_MANAGER.validate_pending_area;
    DBMS_RESOURCE_MANAGER.submit_pending_area;
  END IF;
  SELECT COUNT(*) INTO l_count FROM dba_cdb_rsrc_plan_directives WHERE plan = gk_plan AND pluggable_database = gk_pluggable_database;
  IF l_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Create RSRC MGR Directive: '||gk_pluggable_database||' for '||gk_plan);
    DBMS_RESOURCE_MANAGER.clear_pending_area;
    DBMS_RESOURCE_MANAGER.create_pending_area;
    DBMS_RESOURCE_MANAGER.create_cdb_plan_directive (
      plan                      => gk_plan,
      pluggable_database        => gk_pluggable_database,
      comment                   => 'IOD_RSRC_MGR NEW:'||TO_CHAR(SYSDATE, gk_date_format),
      shares                    => gk_shares,
      utilization_limit         => gk_utilization_limit,
      parallel_server_limit     => gk_parallel_server_limit
    );
    DBMS_RESOURCE_MANAGER.validate_pending_area;
    DBMS_RESOURCE_MANAGER.submit_pending_area;
  END IF;
END;
/
