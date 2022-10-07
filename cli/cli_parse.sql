SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
COL pdb_name FOR A30;
SELECT c.name AS pdb_name, ROUND(100 * (1 - (SUM(s.parse_calls) / SUM(s.executions)))) AS parse2exec_ratio, COUNT(DISTINCT sql_id) sql_ids
  FROM v$sqlstats s, v$containers c
 WHERE c.con_id = s.con_id
 GROUP BY
       c.name
 ORDER BY
       c.name
/
