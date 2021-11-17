SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
COL cnt FOR 999990;
COL container_name FOR A30;
COL min_time FOR A23;
COL max_time FOR A23;
SELECT container_name, COUNT(*) AS cnt, MIN(originating_timestamp) AS min_time, MAX(originating_timestamp) AS max_time FROM x$dbgalertext WHERE problem_key = 'ORA 600 [kkshhcdel:wrong-bucket]' GROUP BY container_name ORDER BY container_name;
