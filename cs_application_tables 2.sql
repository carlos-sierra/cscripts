SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
COL owner FOR A30;
COL table_name FOR A30;
COL num_rows FOR 999,999,999,999;
COL blocks FOR 9,999,999,999;
SELECT u.common, t.owner, t.table_name, t.num_rows, t.blocks, t.last_analyzed, t.tablespace_name
  FROM dba_tables t, dba_users u
 WHERE u.username = t.owner
   AND u.oracle_maintained = 'N'
 ORDER BY
       u.common DESC,
       t.owner,
       t.table_name
/