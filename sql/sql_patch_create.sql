ACC sql_id PROMPT 'SQL_ID: ';
ACC cbo_hints PROMPT 'CBO Hints: ';

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
