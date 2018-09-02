-- dba_cdb_rsrc_plans.sql
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

--
COL pdb_name NEW_V pdb_name FOR A30;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') pdb_name FROM DUAL;
--
ALTER SESSION SET container = CDB$ROOT;
--

COL current_resource_manager_plan FOR A128;
SELECT value current_resource_manager_plan FROM v$parameter WHERE name = 'resource_manager_plan';

COL plan_id FOR 9999999;
COL plan FOR A30;
COL comments FOR A60;
COL status FOR A20;
COL mandatory FOR A9;

SELECT plan,
       comments,
       mandatory,
       status
  FROM dba_cdb_rsrc_plans
 ORDER BY
       plan
/

ALTER SESSION SET container = &&pdb_name.;

