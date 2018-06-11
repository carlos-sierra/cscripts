SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET LONG 5000 LONGC 200;

PRO 1. Enter SQL_ID
DEF sql_id = '&1.';

COL sql_text FOR A200;
SELECT sql_text FROM v$sql WHERE sql_id = '&&sql_id' AND ROWNUM = 1
/

SELECT sql_text FROM dba_hist_sqltext WHERE sql_id = '&&sql_id' AND ROWNUM = 1
/

UNDEF 1 sql_id
