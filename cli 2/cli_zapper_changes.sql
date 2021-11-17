SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
COL pdb_name FOR A30 TRUNC;
COL changes FOR 999,990;
COL schemas FOR 999,990;
SELECT pdb_name,
       sql_id,
       SUM(plans_create + plans_disable + plans_drop) AS changes,
       COUNT(DISTINCT parsing_schema_name) AS schemas
  FROM C##IOD.zapper_log
 WHERE (plans_create + plans_disable + plans_drop) > 0 
 GROUP BY
       pdb_name,
       sql_id
 HAVING SUM(plans_create + plans_disable + plans_drop) > 20
 ORDER BY 3 DESC
/

