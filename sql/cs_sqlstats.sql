SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL pdb_name FOR A30 TRUNC;
COL execs_per_sec FOR 999,990;
--
WITH 
duration AS (
    SELECT  /*+ MATERIALIZE NO_MERGE */
            (SYSDATE - CAST(MAX(end_interval_time) AS DATE)) * 24 * 3600 AS seconds
    FROM    dba_hist_snapshot
),
sql_stat AS (
SELECT  /*+ MATERIALIZE NO_MERGE */
        s.sql_id,
        s.delta_execution_count / duration.seconds AS execs_per_sec,
        c.name AS pdb_name
FROM    v$sqlstats s, duration, v$containers c
WHERE   1 = 1
AND     duration.seconds > 0
AND     s.sql_id IN ('05cf70j3mhh9n', 'a1yjudvhqx98j')
AND     c.con_id = s.con_id
ORDER BY
        s.delta_execution_count DESC
FETCH FIRST 10 ROWS ONLY
)
SELECT  sql_id,
        execs_per_sec,
        pdb_name
FROM    sql_stat
WHERE   execs_per_sec > 50
ORDER BY
        sql_id,
        execs_per_sec DESC
/