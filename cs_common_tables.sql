SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL owner FOR A30;
COL table_name FOR A30;
--
SELECT t.owner, t.table_name, num_rows
  FROM dba_users u, dba_tables t
 WHERE u.common = 'YES'
   AND u.oracle_maintained = 'N'
   AND t.owner = u.username
 ORDER BY
       t.owner, t.table_name
/