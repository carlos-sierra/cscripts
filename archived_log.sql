-- archived_log.sql - Archived Logs list
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL recid_range FOR A13;
--
SELECT first_time, next_time, 
       (next_time - first_time) * 24 * 3600 seconds,
       ROUND(AVG(blocks * block_size) / POWER(2,30), 3) size_gbs, MIN(recid)||'-'||MAX(recid) recid_range
  FROM v$archived_log
 WHERE name IS NOT NULL
 GROUP BY
       first_time, next_time
 ORDER BY
       first_time, next_time
/