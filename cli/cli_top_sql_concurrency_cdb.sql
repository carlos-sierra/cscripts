SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL execs_per_sec FOR 999,990;
COL db_latency_ms FOR 999,990.000;
COL cc_latency_ms FOR 999,990.000;
COL cc_percent FOR 90.000;
COL pdbs FOR 990;
COL schemas FOR 999,990;
COL invalidations FOR 999,999,999,990;
COL loads FOR 999,999,999,990;
COL db_aas FOR 990.000;
COL cc_aas FOR 990.000;
COL executions FOR 999,999,999,990;
COL parses FOR 999,999,999,990;
COL exec2parse FOR 999,990.0;
COL seconds FOR 99,999,990;
COL db_secs FOR 99,999,990;
COL cc_secs FOR 99,999,990;
COL sql_text FOR A60;
--
WITH
sqlstats AS (
 SELECT /*+ MATERIALIZE NO_MERGE */
        h.snap_id,
        h.dbid,
        h.instance_number,
        h.sql_id,
        COUNT(DISTINCT h.parsing_schema_name) AS schemas,
        COUNT(DISTINCT h.con_id) AS pdbs,
        SUM(executions_delta) AS executions,
        SUM(parse_calls_delta) AS parses,
        SUM(elapsed_time_delta) AS db_time_us,
        SUM(ccwait_delta) AS cc_time_us,
        SUM(invalidations_delta) AS invalidations,
        SUM(loads_delta) AS loads
   FROM dba_hist_sqlstat h
  WHERE parsing_schema_name <> 'SYS'
    AND ROWNUM >= 1 
  GROUP BY
        h.snap_id,
        h.dbid,
        h.instance_number,
        h.sql_id
),
sqlstats2 AS (
 SELECT h.sql_id,
        MAX(h.schemas) AS schemas,
        MAX(h.pdbs) AS pdbs,
        SUM(CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 24 * 3600 AS seconds,
        SUM(h.executions) AS executions,
        SUM(h.parses) AS parses,
        100*(1-(SUM(h.parses)/GREATEST(SUM(h.executions),1))) AS exec2parse,  -- ,' Execute to Parse %:' dscr, round(100*(1-:prse/:exe),2) pctval https://asktom.oracle.com/
        SUM(h.db_time_us) AS db_time_us,
        SUM(h.cc_time_us) AS cc_time_us,
        SUM(h.invalidations) AS invalidations,
        SUM(h.loads) AS loads
   FROM sqlstats h,
        dba_hist_snapshot s
  WHERE s.snap_id = h.snap_id
    AND s.dbid = h.dbid
    AND s.instance_number = h.instance_number
  GROUP BY
        h.sql_id
)
SELECT '|' AS "|",
       s.executions/s.seconds AS execs_per_sec,
       s.db_time_us/1e3/s.executions AS db_latency_ms,
       s.cc_time_us/1e3/s.executions AS cc_latency_ms,
       100*s.cc_time_us/s.db_time_us AS cc_percent,
       s.pdbs,
       s.schemas,
       s.invalidations,
       s.loads,
       s.db_time_us/1e6/s.seconds AS db_aas,
       s.cc_time_us/1e6/s.seconds AS cc_aas,
       s.executions,
       s.parses,
       s.exec2parse,
       s.seconds,
       s.db_time_us/1e6 AS db_secs,
       s.cc_time_us/1e6 AS cc_secs,
       s.sql_id,
       (SELECT DBMS_LOB.substr(t.sql_text, 60) FROM dba_hist_sqltext t WHERE t.sql_id = s.sql_id AND ROWNUM = 1) AS sql_text
  FROM sqlstats2 s
 WHERE s.executions/s.seconds > 500 OR (s.schemas > 1 AND s.executions/s.seconds > 100)
    -- OR s.sql_id = 'g4aw69z19hc36' -- /* getMaxTransactionCommitID */ SELECT lastcommittedtransact
  ORDER BY
        s.executions/s.seconds DESC,
        s.db_time_us DESC
 FETCH FIRST 100 ROWS ONLY
/
