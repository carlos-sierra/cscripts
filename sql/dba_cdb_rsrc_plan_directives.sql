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

PRO
ACC plan PROMPT 'Enter plan: ';

COL pluggable_database FOR A30;
COL shares FOR 999990;
COL utilization_limit FOR 99990 HEA 'UTIL|LIMIT'
COL parallel_server_limit FOR 99999999 HEA 'PARALLEL|SERVER';
COL directive_type FOR A20;

SELECT mandatory,
       pluggable_database, 
       shares, 
       utilization_limit,
       parallel_server_limit,
       status,
       directive_type,
       comments
  FROM dba_cdb_rsrc_plan_directives
 WHERE plan = UPPER(TRIM('&plan.'))
 ORDER BY 
       mandatory DESC,
       CASE WHEN pluggable_database LIKE '%$%' THEN 1 ELSE 2 END,
       pluggable_database
 /
 
 