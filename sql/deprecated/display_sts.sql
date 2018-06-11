REM $Header: 215187.1 display_sts.sql 11.4.5.8 2013/05/10 carlos.sierra $

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

SPO &&sql_id._&&sqlset_name._sts.txt;

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

SELECT * /* exclude_me */
  FROM dba_sqlset
 WHERE name = '&&sqlset_name.'
   AND owner = NVL('&&sqlset_owner.', owner);

SET NUM 20;

SELECT * /* exclude_me */
  FROM dba_sqlset_statements
 WHERE sqlset_name = '&&sqlset_name.'
   AND sqlset_owner = NVL('&&sqlset_owner.', sqlset_owner)
   AND sql_id = '&&sql_id.'
   AND plan_hash_value = NVL(TO_NUMBER('&&plan_hash_value.'), plan_hash_value);

COL type FOR A13;
COL value FOR A20;

SELECT force_matching_signature, /* exclude_me */
       position, captured, SUBSTR(SYS.ANYDATA.getTypeName(value), 1, 13) type,
       SUBSTR(CASE SYS.ANYDATA.getTypeName(value)
       WHEN 'SYS.VARCHAR2' THEN SYS.ANYDATA.accessVarchar2(value)
       WHEN 'SYS.NUMBER'   THEN TO_CHAR(SYS.ANYDATA.accessNumber(value))
       WHEN 'SYS.DATE'     THEN TO_CHAR(SYS.ANYDATA.accessDate(value), 'DD-MON-YYYY')
       END, 1, 20) value
  FROM dba_sqlset_binds
 WHERE sqlset_name = '&&sqlset_name.'
   AND sqlset_owner = NVL('&&sqlset_owner.', sqlset_owner)
   AND sql_id = '&&sql_id.'
   AND plan_hash_value = NVL(TO_NUMBER('&&plan_hash_value.'), plan_hash_value)
 ORDER BY
       position;

SET PAGES 2000 LIN 300 TRIMS ON ECHO ON FEED OFF HEA OFF;

SELECT * /* exclude_me */
FROM TABLE(DBMS_XPLAN.display_sqlset('&&sqlset_name.', '&&sql_id.', TO_NUMBER('&&plan_hash_value.'), 'ADVANCED', '&&sqlset_owner.'));

SPO OFF;

SET NUM 10 PAGES 14 LONG 80 LIN 80 TRIMS OFF ECHO OFF FEED 6 HEA ON;

UNDEF sql_text_piece sqlset_name sqlset_owner sql_id plan_hash_value
