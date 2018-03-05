-- delete_cdb_plan.sql
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT ON SIZE UNLIMITED;

COL current_resource_manager_plan FOR A128;
SELECT value current_resource_manager_plan FROM v$parameter WHERE name = 'resource_manager_plan';

COL plan_id FOR 9999999;
COL plan FOR A30;
COL comments FOR A60;
COL status FOR A20;
COL mandatory FOR A9;

SELECT plan_id,
       plan,
       mandatory,
       status,
       comments
  FROM dba_cdb_rsrc_plans
 WHERE mandatory = 'NO'
 ORDER BY
       plan_id
/

PRO
ACC plan PROMPT 'Enter plan to delete: ';

DECLARE
  l_value VARCHAR2(4000);
BEGIN
  SELECT value INTO l_value FROM v$parameter WHERE name = 'resource_manager_plan';
  IF UPPER(l_value) LIKE '%'||UPPER('&plan.') THEN
    DBMS_OUTPUT.PUT_LINE('plan &plan. is active, then cannot delete it');
    --DBMS_RESOURCE_MANAGER.switch_plan(NULL);
  END IF;
  --
  DBMS_RESOURCE_MANAGER.clear_pending_area;
  DBMS_RESOURCE_MANAGER.create_pending_area;
  --
  DBMS_RESOURCE_MANAGER.delete_cdb_plan(plan => '&plan.');
  --
  DBMS_RESOURCE_MANAGER.validate_pending_area;
  DBMS_RESOURCE_MANAGER.submit_pending_area;
END;
/

SELECT plan_id,
       plan,
       mandatory,
       status,
       comments
  FROM dba_cdb_rsrc_plans
 WHERE mandatory = 'NO'
 ORDER BY
       plan_id
/
