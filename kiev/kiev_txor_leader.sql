-- kiev_txor_leader.sql - KIEV Transactor Leader Switches
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF6';
--
COL sample_date FOR A26 HEA 'LEADER_CHANGE';
COL seconds FOR 999,990;
COL leader FOR A132;
--
WITH 
txor AS (
SELECT CAST(sample_time AS DATE) AS sample_date,
       machine,
       COUNT(*) cnt,
       ROW_NUMBER() OVER(PARTITION BY CAST(sample_time AS DATE) ORDER BY COUNT(*) DESC) AS rn
  FROM dba_hist_active_sess_history
 WHERE machine LIKE 'kiev-txor-%'
 GROUP BY
       CAST(sample_time AS DATE),
       machine
),
txor2 AS (
SELECT sample_date,
       machine,
       LEAD(machine) OVER (ORDER BY sample_date ASC) AS lead_machine
  FROM txor
 WHERE rn = 1
)
SELECT sample_date,
       (sample_date - LAG(sample_date) OVER(ORDER BY sample_date)) * 24 * 3600 AS seconds,
       machine||' -> '||lead_machine AS leader
  FROM txor2
 WHERE machine <> lead_machine
ORDER BY 1
/
