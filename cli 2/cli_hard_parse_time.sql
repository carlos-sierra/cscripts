SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET PAGES 300;
COL pdb_name FOR A30;
SELECT c.name AS pdb_name,
       ROUND(s.avg_hard_parse_time / 1000) AS avg_hard_parse_ms,
       ROUND(s.delta_execution_count / t.seconds) AS execs_per_sec,
       s.delta_execution_count AS executions,
       t.seconds
  FROM v$sqlstats s, 
       v$containers c,
       (SELECT (SYSDATE - CAST(MAX(end_interval_time) AS DATE)) * 24 * 60 * 60 AS seconds FROM dba_hist_snapshot) t
 WHERE s.sql_id = '3hahc9c3zmc6d' /*'gvk9m8bnvtkjz'*/
   AND c.con_id = s.con_id
 ORDER BY
       /*s.avg_hard_parse_time*/ 3 DESC
/
