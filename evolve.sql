@list_plans.sql

ACC plan_name PROMPT 'Enter optional Plan Name: ';
ACC verify_par PROMPT 'Enter optional verify parameter [ YES | NO ]: ';
ACC commit_par PROMPT 'Enter optional commit parameter [ YES | NO ]: '

VAR x CLOB;

BEGIN
  :x := DBMS_SPM.evolve_sql_plan_baseline (
    sql_handle  => '&&sql_handle.',
    plan_name   => '&&plan_name.',
    verify      => NVL('&&verify_par.', 'YES'),
    commit      => NVL('&&commit_par.', 'YES') );
END;
/

SET PAGES 2000 LONG 80000 LIN 300 TRIMS ON ECHO ON FEED OFF HEA OFF;
SPO &&sql_handle._&&plan_name._evolve.txt;
PRINT x;
SPO OFF;
SET PAGES 14 LONG 80 LIN 300 TRIMS OFF ECHO OFF FEED 6 HEA ON;

@list_plans.sql
