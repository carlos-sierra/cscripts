REM $Header: 215187.1 drop_sts.sql 11.4.5.8 2013/05/10 carlos.sierra $

PAU Requires Oracle Tuning Pack license. Hit "Enter" to proceed

ACC sql_text_piece PROMPT 'Enter SQL Text piece: '

SET PAGES 200 LONG 80000 ECHO ON;

COL sql_text PRI;

SELECT sql_id, sql_text /* exclude_me */
  FROM dba_sqlset_statements
 WHERE sql_text LIKE '%&&sql_text_piece.%'
   AND sql_text NOT LIKE '%/* exclude_me */%';

ACC sql_id PROMPT 'Enter SQL_ID: ';

SELECT sqlset_name, sqlset_owner /* exclude_me */
  FROM dba_sqlset_statements
 WHERE sql_id = '&&sql_id.';

ACC sqlset_name PROMPT 'Enter SQL Set Name: '

ACC sqlset_owner PROMPT 'Enter SQL Set Owner: '

PRO STS content

SELECT sql_id, plan_hash_value /* exclude_me */
  FROM dba_sqlset_statements
 WHERE sqlset_name = '&&sqlset_name.'
   AND sqlset_owner = '&&sqlset_owner.';

EXEC DBMS_SQLTUNE.drop_sqlset('&&sqlset_name.', '&&sqlset_owner.');

SET PAGES 14 LONG 80 ECHO OFF;

UNDEF sql_text_piece sql_id sqlset_name sqlset_owner
