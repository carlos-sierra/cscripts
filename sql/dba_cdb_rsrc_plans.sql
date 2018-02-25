SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

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
 ORDER BY
       plan_id
/
