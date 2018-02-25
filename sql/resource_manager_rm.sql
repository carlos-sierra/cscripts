SET HEA OFF LINE 300 ECHO OFF;
ALTER SESSION SET CONTAINER = CDB$ROOT;

SPO rm_kiev_pdb_plan_force.sql
SELECT 'ALTER SESSION SET CONTAINER = '||v.name||';'||CHR(10)||
       'ALTER SYSTEM SET RESOURCE_MANAGER_PLAN = ''FORCE:KIEV_PDB_PLAN'';'
       --'EXEC DBMS_RESOURCE_MANAGER.SWITCH_PLAN(plan_name => ''KIEV_PDB_PLAN'', allow_scheduler_plan_switches => FALSE);'
  FROM v$pdbs v
 WHERE v.con_id > 2
   AND v.open_mode = 'READ WRITE'
 ORDER BY
       v.name
/
SPO OFF;
@rm_kiev_pdb_plan_force.sql

ALTER SESSION SET CONTAINER = CDB$ROOT;