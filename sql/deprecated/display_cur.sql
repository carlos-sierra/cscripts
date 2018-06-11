REM $Header: 215187.1 display_cur.sql 12.1.02 2013/09/09 carlos.sierra mauro.pagano $

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

SELECT child_number, executions, elapsed_time, /* exclude_me */
       CASE WHEN executions > 0 THEN ROUND(elapsed_time/executions/1e6, 3) END avg_secs_per_exec
  FROM v$sql
 WHERE sql_id = '&&sql_id.'
   AND plan_hash_value = TO_NUMBER('&&plan_hash_value.')
 ORDER BY
       4 DESC NULLS FIRST;

ACC child_number PROMPT 'Enter Child Number: ';

SPO &&sql_id._&&plan_hash_value._&&child_number._cur.txt;

COL sql_text NOPRI;
COL sql_fulltext NOPRI;

SET NUM 20;

SELECT * /* exclude_me */
  FROM v$sql
 WHERE sql_id = '&&sql_id.'
   AND plan_hash_value = TO_NUMBER('&&plan_hash_value.')
   AND child_number = TO_NUMBER('&&child_number.');

COL sql_text PRI;
COL sql_fulltext PRI;

SET PAGES 2000 LIN 300 TRIMS ON ECHO ON FEED OFF HEA OFF;

SELECT * /* exclude_me */
FROM TABLE(DBMS_XPLAN.display_cursor('&&sql_id.', TO_NUMBER('&&child_number.'), 'ADVANCED'));

SPO OFF;

SET NUM 10 PAGES 14 LONG 80 LIN 80 TRIMS OFF ECHO OFF FEED 6 HEA ON;

UNDEF sql_text_piece sql_id plan_hash_value child_number
