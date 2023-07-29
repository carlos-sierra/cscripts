-- dp.sql - Display Plan Table Explain Plan. Execute this script after one EXPLAIN PLAN FOR for a SQL for which you want to see the Explain Plan
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20;
SET HEA OFF PAGES 0;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', NULL, 'ADVANCED'));
SET HEA ON PAGES 100;
-- in case it was ON the repeat SQL execution followed by this script
SET SERVEROUT OFF;