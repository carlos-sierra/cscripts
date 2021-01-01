-- log.sql - REDO Log on Primary and Standby
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
SET NUM 20;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
PRO
PRO v$log
PRO ~~~~~
SELECT * FROM v$log
/
--
PRO
PRO v$log
PRO ~~~~~
SELECT COUNT(*) groups,
       AVG(members) AS members,
       AVG(bytes)/POWER(2,20) avg_mbs,
       MIN(bytes)/POWER(2,20) min_mbs,
       MAX(bytes)/POWER(2,20) max_mbs,
       ROUND(SUM(bytes)/POWER(2,30), 1) sum_gbs
  FROM v$log
/
--
PRO
PRO v$log
PRO ~~~~~
SELECT bytes / POWER(2,30) AS size_gb, COUNT(*) AS groups, AVG(members) AS members
  FROM v$log
GROUP BY bytes / POWER(2,30)
/
PRO
PRO v$standby_log
PRO ~~~~~
SELECT * FROM v$standby_log
/
--
PRO
PRO v$standby_log
PRO ~~~~~
SELECT COUNT(*) groups,
       1 AS members,
       AVG(bytes)/POWER(2,20) avg_mbs,
       MIN(bytes)/POWER(2,20) min_mbs,
       MAX(bytes)/POWER(2,20) max_mbs,
       ROUND(SUM(bytes)/POWER(2,30), 1) sum_gbs
  FROM v$standby_log
/
--
PRO
PRO v$standby_log
PRO ~~~~~
SELECT bytes / POWER(2,30) AS size_gb, COUNT(*) AS groups, 1 AS members
  FROM v$standby_log
GROUP BY bytes / POWER(2,30)
/