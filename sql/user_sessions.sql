SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET RECSEP OFF;

COL sid_serial FOR A10;
COL module FOR A30;
COL last_call_et FOR 999999 HEA 'LAST|CALL|SECS';
COL sql_text FOR A101;
COL sql_ids FOR A14 HEA 'SQL_ID CURR|SQL_ID PRIOR';
BREAK ON sid_serial SKIP 1;

SELECT last_call_et, sid||','||serial# sid_serial, status, SUBSTR(module, 1, 30) module, 
       NVL(sql_id, '"null"')||CHR(10)||NVL(prev_sql_id, '"null"') sql_ids,
       (SELECT SUBSTR(sql_text, 1, 100) FROM v$sql sq WHERE sq.sql_id = se.sql_id AND ROWNUM = 1)||CHR(10)||
       (SELECT SUBSTR(sql_text, 1, 100) FROM v$sql sq WHERE sq.sql_id = se.prev_sql_id AND ROWNUM = 1) sql_text
  FROM v$session se
 WHERE type = 'USER'
   AND sid <> USERENV('SID')
 ORDER BY
       last_call_et, sid, serial#
/

