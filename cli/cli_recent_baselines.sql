SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;

ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF6';
--
COL pdb_name FOR A30 TRUNC;
COL created FOR A19 TRUNC;
COL last_modified FOR A19 TRUNC;
COL sql_handle FOR A20;
COL plan_name FOR A30;
COL origin FOR A29;
COL description FOR A220;
--
BREAK ON pdb_name SKIP PAGE;
--
SELECT c.name AS pdb_name, b.last_modified, b.created, b.signature, b.sql_handle, b.plan_name, b.origin, b.description
  FROM cdb_sql_plan_baselines b, v$containers c
 WHERE b.last_modified >= TO_DATE('2020-10-17T13:46:00')
   AND b.description LIKE '%'||SUBSTR(TO_CHAR(b.last_modified), 1, 10)||'%'
   AND c.con_id = b.con_id
 ORDER BY
       1, 2
/