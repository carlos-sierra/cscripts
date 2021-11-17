SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
COL type FOR A4;
COL queries FOR 999,999,990;
COL baselines FOR 999,999,990;
COL pct FOR 990.0;
COL oby NOPRI;
WITH
sq1 AS (
SELECT C##IOD.IOD_SPM.application_category(sql_text) AS type, con_id, sql_id, sql_plan_baseline
  FROM v$sql
 WHERE C##IOD.IOD_SPM.application_category(sql_text) IN ('TP','RO','BG')
 GROUP BY
       C##IOD.IOD_SPM.application_category(sql_text), con_id, sql_id, sql_plan_baseline
),
sq2 AS (
SELECT type, COUNT(DISTINCT con_id||sql_id) AS queries
  FROM sq1
 GROUP BY type
),
sq3 AS (
SELECT type, COUNT(DISTINCT con_id||sql_id) AS baselines
  FROM sq1
 WHERE sql_plan_baseline IS NOT NULL
 GROUP BY type
),
sq4 AS (
SELECT CASE sq2.type WHEN 'TP' THEN 1 WHEN 'RO' THEN 2 WHEN 'BG' THEN 3 END oby,
       sq2.type, sq2.queries, sq3.baselines, ROUND(100 * sq3.baselines / sq2.queries, 1) AS pct
  FROM sq2, sq3 
 WHERE sq3.type = sq2.type
)
SELECT oby, type, queries, baselines, pct
  FROM sq4
 UNION ALL
SELECT 4 AS oby, 'TOT' AS type, SUM(queries) AS queries, SUM(baselines) AS baselines, ROUND(100 * SUM(baselines) / SUM(queries), 1) AS pct
  FROM sq4
 ORDER BY 1
/