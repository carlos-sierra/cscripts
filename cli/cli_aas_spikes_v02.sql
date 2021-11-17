SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL date_time FOR A10;
COL min_date_time FOR A19;
COL max_date_time FOR A19;
COL max_aas FOR 99,999;
COL max_machines FOR 999,990;
COL seconds FOR 999,990;
COL max_pdbs FOR 999,990;
--
WITH
over_height AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       COUNT(*) AS aas,
       COUNT(DISTINCT machine) AS machines, 
       COUNT(DISTINCT con_id) AS pdbs,
       (CAST(h.sample_time AS DATE) - LAG(CAST(h.sample_time AS DATE)) OVER (ORDER BY h.sample_time)) * 24 * 3600 AS secs_from_prior
  FROM dba_hist_active_sess_history h
 GROUP BY
       h.sample_time
HAVING COUNT(*) > 1000
),
over_time AS (
SELECT CAST(h.sample_time AS DATE) AS sample_time,
       h.aas,
       h.machines,
       h.pdbs
  FROM over_height h
 WHERE secs_from_prior < 20
)
SELECT TO_CHAR(TRUNC(sample_time), 'YYYY-MM-DD') AS date_time,
       TO_CHAR(MIN(sample_time - (20/24/3600)), 'YYYY-MM-DD"T"HH24:MI:SS') AS min_date_time,
       TO_CHAR(MAX(sample_time), 'YYYY-MM-DD"T"HH24:MI:SS') AS max_date_time,
       ((MAX(sample_time) - MIN(sample_time)) * 24 * 3600) + 20 AS seconds,
       MAX(aas) AS max_aas,
       MAX(machines) AS max_machines,
       MAX(pdbs) AS max_pdbs
  FROM over_time
 GROUP BY
       TRUNC(sample_time)
 ORDER BY
       1
/
