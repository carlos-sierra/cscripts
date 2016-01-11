REM $Header: 215187.1 create_sts_from_cur.sql 12.1.02 2013/09/09 carlos.sierra mauro.pagano $

PAU Requires Oracle Tuning Pack license. Hit "Enter" to proceed

ACC sql_text_piece PROMPT 'Enter SQL Text piece: '

SET PAGES 200 LONG 80000 ECHO ON;

COL sql_text PRI;

SELECT sql_id, sql_text /* exclude_me */
  FROM v$sqlarea
 WHERE sql_text LIKE '%&&sql_text_piece.%'
   AND sql_text NOT LIKE '%/* exclude_me */%';

ACC sql_id PROMPT 'Enter SQL_ID: ';

SELECT plan_hash_value, SUM(executions) executions, SUM(elapsed_time) elapsed_time, /* exclude_me */
       CASE WHEN SUM(executions) > 0 THEN ROUND(SUM(elapsed_time)/SUM(executions)/1e6, 3) END avg_secs_per_exec
  FROM v$sql
 WHERE sql_id = '&&sql_id.'
 GROUP BY
       plan_hash_value
 ORDER BY
       4 DESC NULLS FIRST;

ACC plan_hash_value PROMPT 'Enter Plan Hash Value: ';

VAR sqlset_name VARCHAR2(30);

EXEC :sqlset_name := 's_&&sql_id._&&plan_hash_value._cur';

PRINT sqlset_name;

SET SERVEROUT ON;

DECLARE
  l_sqlset_name VARCHAR2(30);
  l_description VARCHAR2(256);
  sts_cur       SYS.DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
  l_sqlset_name := :sqlset_name;
  l_description := 'SQL_ID:&&sql_id., PHV:&&plan_hash_value.';

  BEGIN
    DBMS_OUTPUT.put_line('dropping sqlset: '||l_sqlset_name);
    SYS.DBMS_SQLTUNE.drop_sqlset (
      sqlset_name  => l_sqlset_name,
      sqlset_owner => USER );
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.put_line(SQLERRM||' while trying to drop STS: '||l_sqlset_name||' (safe to ignore)');
  END;

  l_sqlset_name :=
  SYS.DBMS_SQLTUNE.create_sqlset (
    sqlset_name  => l_sqlset_name,
    description  => l_description,
    sqlset_owner => USER );
  DBMS_OUTPUT.put_line('created sqlset: '||l_sqlset_name);

  OPEN sts_cur FOR
    SELECT VALUE(p)
      FROM TABLE(DBMS_SQLTUNE.select_cursor_cache(
      'sql_id = ''&&sql_id.'' AND plan_hash_value = TO_NUMBER(''&&plan_hash_value.'') AND loaded_versions > 0',
      NULL, NULL, NULL, NULL, 1, NULL, 'ALL')) p;

  SYS.DBMS_SQLTUNE.load_sqlset (
    sqlset_name     => l_sqlset_name,
    populate_cursor => sts_cur );
  DBMS_OUTPUT.put_line('loaded sqlset: '||l_sqlset_name);

  CLOSE sts_cur;
END;
/

SET PAGES 14 LONG 80 ECHO OFF SERVEROUT OFF;

UNDEF sql_text_piece sql_id plan_hash_value
