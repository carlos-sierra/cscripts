-- log_history.sql - REDO Log History 
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL thread# FOR 990;
COL switches FOR 999,990;
SELECT thread#, TO_CHAR(TRUNC(first_time), 'YYYY-MM-DD') day, COUNT(*) switches
  FROM v$log_history
 GROUP BY
       thread#, TRUNC(first_time)
 ORDER BY
       thread#, TRUNC(first_time)
/
--
SELECT ROUND(COUNT(*) / 7) switches_per_day
  FROM v$log_history
 WHERE first_time BETWEEN TRUNC(SYSDATE) - 7 AND TRUNC(SYSDATE)
/
--
SELECT ROUND(COUNT(*) / 7 / 24, 1) switches_per_hour
  FROM v$log_history
 WHERE first_time BETWEEN TRUNC(SYSDATE) - 7 AND TRUNC(SYSDATE)
/

