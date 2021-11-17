SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL date_time FOR A19;
COL aas FOR 99,999;
COL machines FOR 999,990;
--
WITH
over_height AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       COUNT(*) AS aas,
       COUNT(DISTINCT machine) AS machines,
       (CAST(h.sample_time AS DATE) - LAG(CAST(h.sample_time AS DATE)) OVER (ORDER BY h.sample_time)) * 24 * 3600 AS secs_from_prior
  FROM dba_hist_active_sess_history h
 GROUP BY
       h.sample_time
HAVING COUNT(*) > 1000
)
SELECT TO_CHAR(h.sample_time, 'YYYY-MM-DD"T"HH24:MI:SS') AS date_time,
       h.aas,
       h.machines
  FROM over_height h
 WHERE secs_from_prior < 20
 ORDER BY
       h.sample_time
/
