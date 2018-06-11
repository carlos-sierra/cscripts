REM $Header: 215187.1 create_spb_from_cur.sql 12.1.02 2013/09/09 carlos.sierra $

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

VAR plans NUMBER;

EXEC :plans := DBMS_SPM.load_plans_from_cursor_cache('&&sql_id.', TO_NUMBER('&&plan_hash_value.'));

PRINT plans;

SET PAGES 14 LONG 80 ECHO OFF;

UNDEF sql_text_piece sql_id plan_hash_value
