REM $Header: 215187.1 evolve_spb.sql 11.4.5.8 2013/05/10 carlos.sierra $

ACC sql_text_piece PROMPT 'Enter SQL Text piece: '

SET PAGES 200 LONG 80000 ECHO ON;

COL sql_text PRI;

SELECT sql_handle, plan_name, sql_text /* exclude_me */
  FROM dba_sql_plan_baselines
 WHERE sql_text LIKE '%&&sql_text_piece.%'
   AND sql_text NOT LIKE '%/* exclude_me */%';

ACC sql_handle PROMPT 'Enter SQL Handle: ';

SELECT sql_handle, sql_text /* exclude_me */
  FROM dba_sql_plan_baselines
 WHERE sql_handle = '&&sql_handle.'
   AND ROWNUM = 1;

SELECT plan_name, enabled, accepted, fixed, reproduced, created /* exclude_me */
  FROM dba_sql_plan_baselines
 WHERE sql_handle = '&&sql_handle.'
 ORDER BY
       created;

ACC plan_name PROMPT 'Enter optional Plan Name: ';

SELECT plan_name, enabled, accepted, fixed, reproduced, created /* exclude_me */
  FROM dba_sql_plan_baselines
 WHERE sql_handle = '&&sql_handle.'
   AND plan_name = NVL('&&plan_name.', plan_name)
 ORDER BY
       created;

ACC verify_par PROMPT 'Enter optional verify parameter (YES/NO): ';

ACC commit_par PROMPT 'Enter optional commit parameter (NO/YES): '

VAR x CLOB;

BEGIN
  :x := DBMS_SPM.evolve_sql_plan_baseline (
    sql_handle  => '&&sql_handle.',
    plan_name   => '&&plan_name.',
    verify      => NVL('&&verify_par.', 'YES'),
    commit      => NVL('&&commit_par.', 'NO') );
END;
/

SET PAGES 2000 LIN 300 TRIMS ON ECHO ON FEED OFF HEA OFF;

SPO &&sql_handle._&&plan_name._evolve.txt;

PRINT x;

SPO OFF;

SET PAGES 14 LONG 80 LIN 80 TRIMS OFF ECHO OFF FEED 6 HEA ON;

UNDEF sql_text_piece sql_handle plan_name verify_par commit_par
