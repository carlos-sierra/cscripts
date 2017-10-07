SELECT sql_text FROM v$sql WHERE sql_id = '&&sql_id.' AND ROWNUM = 1
/
