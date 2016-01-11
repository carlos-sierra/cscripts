REM $Header: 215187.1 create_spb_from_sts.sql 11.4.5.8 2013/05/10 carlos.sierra $

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

SELECT sqlset_owner, plan_hash_value /* exclude_me */
  FROM dba_sqlset_statements
 WHERE sql_id = '&&sql_id.'
   AND sqlset_name = '&&sqlset_name.';

ACC sqlset_owner PROMPT 'Enter SQL Set Owner: ';

SELECT plan_hash_value /* exclude_me */
  FROM dba_sqlset_statements
 WHERE sql_id = '&&sql_id.'
   AND sqlset_name = '&&sqlset_name.'
   AND sqlset_owner = '&&sqlset_owner.';

ACC plan_hash_value PROMPT 'Enter optional Plan Hash Value: ';

VAR plans NUMBER;

BEGIN
  :plans := DBMS_SPM.load_plans_from_sqlset (
    sqlset_name  => '&&sqlset_name.',
    sqlset_owner => '&&sqlset_owner.',
    basic_filter => 'sql_id = ''&&sql_id.'' AND plan_hash_value = NVL(TO_NUMBER(''&&plan_hash_value.''), plan_hash_value)' );
END;
/

PRINT plans;

SET PAGES 14 LONG 80 ECHO OFF;

UNDEF sql_text_piece sqlset_name sqlset_owner sql_id plan_hash_value
