SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL pdb_name FOR A30 TRUNC;
COL avg_ms_pagination FOR 999,990.0;
COL avg_ms_no_pagination FOR 999,990.0;
COL sum_secs FOR 999,999,990;
COL sum_executions FOR 999,999,990;
COL statements FOR 999,990;
--
WITH
sqlstats AS (
SELECT con_id,
       SUM(CASE WHEN sql_text LIKE '%(% > :% ) OR%' THEN elapsed_time ELSE 0 END) / NULLIF(SUM(CASE WHEN sql_text LIKE '%(% > :% ) OR%' THEN executions ELSE 0 END), 0) / 1e3 AS avg_ms_pagination,
       SUM(CASE WHEN sql_text LIKE '%(% > :% ) OR%' THEN 0 ELSE elapsed_time END) / NULLIF(SUM(CASE WHEN sql_text LIKE '%(% > :% ) OR%' THEN 0 ELSE executions END), 0) / 1e3 AS avg_ms_no_pagination,
       SUM(elapsed_time) / 1e6 AS sum_secs,
       SUM(executions) AS sum_executions,
       COUNT(DISTINCT sql_id||plan_hash_value) AS statements
  FROM v$sqlstats
 WHERE sql_text LIKE '/* performScanQuery(%'
   AND executions > 0
 GROUP BY
       con_id
)
SELECT c.name AS pdb_name,
       s.avg_ms_pagination,
       s.avg_ms_no_pagination,
       s.sum_secs,
       s.sum_executions,
       s.statements
  FROM sqlstats s,
       v$containers c
 WHERE s.avg_ms_pagination IS NOT NULL
   AND s.avg_ms_no_pagination IS NOT NULL
   AND (s.avg_ms_pagination > 10 * s.avg_ms_no_pagination OR s.avg_ms_no_pagination > 10 * s.avg_ms_pagination)
   AND c.con_id = s.con_id
 ORDER BY
       c.name
/
