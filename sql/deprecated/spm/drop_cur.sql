REM $Header: 215187.1 drop_cur.sql 11.4.5.8 2013/05/10 carlos.sierra $

ACC sql_text_piece PROMPT 'Enter SQL Text piece: '

SET PAGES 200 LONG 80000 ECHO ON;

COL sql_text PRI;

SELECT sql_id, sql_text /* exclude_me */
  FROM v$sqlarea
 WHERE sql_text LIKE '%&&sql_text_piece.%'
   AND sql_text NOT LIKE '%/* exclude_me */%';

ACC sql_id PROMPT 'Enter SQL_ID: ';

BEGIN
  FOR i IN (SELECT address, hash_value
              FROM gv$sqlarea WHERE sql_id = '&&sql_id.')
  LOOP
    SYS.DBMS_SHARED_POOL.UNKEEP(name => i.address||','||i.hash_value, flag => 'C');
    SYS.DBMS_SHARED_POOL.PURGE(name => i.address||','||i.hash_value, flag => 'C');
  END LOOP;
END;
/

SET NUM 10 PAGES 14 LONG 80 ECHO OFF;

UNDEF sql_text_piece sql_id
