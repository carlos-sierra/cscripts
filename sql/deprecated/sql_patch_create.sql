ACC sql_id PROMPT 'SQL_ID: ';
ACC cbo_hints PROMPT 'CBO Hints: ';

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

SPO sql_patch_create_&&sql_id._&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO SQL_ID: &&sql_id.
PRO CBO_HINTS: &&cbo_hints.

DECLARE
  l_sql_fulltext CLOB;
BEGIN
  SELECT sql_fulltext INTO l_sql_fulltext FROM v$sql WHERE sql_id = '&&sql_id.' AND ROWNUM = 1;
  SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH (
    sql_text    => l_sql_fulltext,
    hint_text   => q'[&&cbo_hints.]',
    name        => 'sql_patch_&&sql_id.',
    description => q'[/*+ &&cbo_hints. */]',
    category    => 'DEFAULT',
    validate    => TRUE
  );  
END;
/

PRO Note: to drop use EXEC DBMS_SQLDIAG.DROP_SQL_PATCH(name => 'sql_patch_&&sql_id.', ignore => TRUE);

SPO OFF;