SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
WITH
kt AS (
SELECT CAST(begintime AS DATE) AS beginsec, COUNT(*) AS transactions, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
  FROM kaasrwuser.kievtransactions
 WHERE begintime > SYSDATE - 1
 GROUP BY
       CAST(begintime AS DATE)
)
SELECT beginsec, transactions
  FROM kt
 WHERE rn < 11
 ORDER BY
       1
/