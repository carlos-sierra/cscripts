SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL pdb_name FOR A30;
COL pdb_tps FOR 999,990;
COL cdb_tps FOR 999,990;
COL perc FOR 990.0 HEA 'PERC%';
--
 WITH
 xid AS (
 SELECT /*+ MATERIALIZE NO_MERGE */
        con_id,
        COUNT(DISTINCT xid) / SUM(COUNT(DISTINCT xid)) OVER () AS contribution
   FROM v$active_session_history
  WHERE xid IS NOT NULL
    AND sample_time > SYSDATE - (1/24) -- last 1h only
  GROUP BY
        con_id 
 ),
 tps AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       average
  FROM v$sysmetric_summary
 WHERE group_id IN (2, 18)
   AND metric_name = 'User Transaction Per Sec'
 )
 SELECT c.name AS pdb_name,
        x.contribution * t.average AS pdb_tps,
        t.average AS cdb_tps,
        100 * x.contribution AS perc
   FROM xid x, tps t, v$containers c
  WHERE c.con_id = x.con_id
    AND x.contribution * t.average > 1
 ORDER BY
       x.contribution DESC
 FETCH FIRST 10 ROWS ONLY
 /
