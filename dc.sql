-- dc.sql - Display Cursor Execution Plan. Execute this script after one SQL for which you want to see the Execution Plan
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20;
SET HEA OFF PAGES 0;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR((SELECT prev_sql_id FROM v$session WHERE sid = SYS_CONTEXT('USERENV', 'SID')), NULL, 'ADVANCED ALLSTATS LAST'));
SET HEA ON PAGES 100;
-- in case it was ON the repeat SQL execution followed by this script
SET SERVEROUT OFF;