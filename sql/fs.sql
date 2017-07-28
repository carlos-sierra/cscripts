DEF sql_id = '';
COL sql_id NEW_V sql_id;
SELECT sql_id, SUBSTR(sql_text, 1, 100) sql_text_100 
  FROM v$sql
 WHERE sql_text LIKE '%&sql_text_piece%'
   AND sql_text NOT LIKE '%sql_id%'
/
