WHENEVER SQLERROR CONTINUE;

SPO create_baselines_for_all_pdbs.txt;

DEF sql_identification = '/* readTransactionsSince() */';
DEF plan_hash_value = 766112998;

SET SERVEROUT ON PAGES 100 LINES 300;

VAR l_sql_patch_template CLOB;
BEGIN
  :l_sql_patch_template := q'[
DECLARE
  l_plans NUMBER;
BEGIN
  l_plans :=
  SYS.DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE (
    sql_id            => 'SQL_ID',
    plan_hash_value   => &&plan_hash_value.,
    fixed             => 'YES',
    enabled           => 'YES');
 BEGIN
   SYS.DBMS_SQLDIAG.DROP_SQL_PATCH('sqlpch_SQL_ID');
 EXCEPTION
   WHEN OTHERS THEN
     NULL;
 END;
END;
/]';
END;
/

select s.con_id, p.name, s.sql_id, s.child_number, s.executions, s.optimizer_cost, ROUND(s.elapsed_time/s.executions/1000000,6) secs_per_exec,  s.plan_hash_value, s.is_shareable, s.object_status, s.sql_plan_baseline, s.sql_patch
from v$sql s, v$pdbs p 
where s.sql_text like '&&sql_identification.%'
and p.con_id = s.con_id 
and s.executions > 0
order by 1, 3, 4;

ALTER SESSION SET CONTAINER = CDB$ROOT;

SPO create_baselines_for_all_pdbs.sql;
DECLARE
BEGIN
  FOR i IN (SELECT /* sql_patch_pdb */ DISTINCT p.name, s.sql_id 
              FROM v$sql s, v$pdbs p 
             WHERE s.sql_text LIKE '%&&sql_identification.%' 
               AND UPPER(s.sql_text) NOT LIKE '%V$SQL%' -- exclude itself
               AND p.con_id = s.con_id
            ORDER BY 1, 2)
  LOOP
    DBMS_OUTPUT.PUT_LINE(CHR(10)||CHR(10)||CHR(10)||'/******************/'||CHR(10)||CHR(10)||'/* Creates SQL Baseline for SQL_ID */');
    DBMS_OUTPUT.PUT_LINE(CHR(10)||'ALTER SESSION SET CONTAINER = '||i.name||';');
    DBMS_OUTPUT.PUT_LINE(REPLACE(:l_sql_patch_template, 'SQL_ID', i.sql_id));
  END LOOP;
END;
/

SPO create_baselines_for_all_pdbs.txt APP;

SET ECHO ON FEED ON;
@create_baselines_for_all_pdbs.sql
      
ALTER SESSION SET CONTAINER = CDB$ROOT;

select s.con_id, p.name, s.sql_id, s.child_number, s.executions, s.optimizer_cost, ROUND(s.elapsed_time/s.executions/1000000,6) secs_per_exec,  s.plan_hash_value, s.is_shareable, s.object_status, s.sql_plan_baseline, s.sql_patch
from v$sql s, v$pdbs p 
where s.sql_text like '&&sql_identification.%'
and p.con_id = s.con_id 
and s.executions > 0
order by 1, 3, 4;

SPO OFF;

