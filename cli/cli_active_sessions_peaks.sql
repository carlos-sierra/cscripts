SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
COL day FOR A10;
COL sample_time FOR A25;
COL active_sessions FOR 999,990 HEA 'SESSIONS';
COL max_sessions FOR A4 HEA 'MAX';
COL peak FOR A5 HEA 'PEAK';
COL graph FOR A200 HEA 'GRAPH';
--
BREAK ON day SKIP PAGE DUPL;
--
WITH
cpu_cores AS (
  SELECT /*+ MATERIALIZE NO_MERGE */value FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES' AND ROWNUM >= 1 /* MATERIALIZE */
),
active_sessions_time_series AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       COUNT(*) AS active_sessions
  FROM dba_hist_active_sess_history
 WHERE ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       sample_time
)
-- https://blog.dbi-services.com/oracle-row-pattern/
SELECT TO_CHAR(sample_time, 'YYYY-MM-DD') AS day, sample_time, active_sessions, 
       CASE WHEN active_sessions = MAX(active_sessions) OVER (PARTITION BY TO_CHAR(sample_time, 'YYYY-MM-DD')) THEN 'MAX' END AS max_sessions,
       CASE WHEN active_sessions = peak_active_sessions THEN 'PEAK' END AS peak,
       LPAD('*', active_sessions / 100, '*') AS graph
  FROM cpu_cores, active_sessions_time_series
MATCH_RECOGNIZE (
  /* PARTITION BY xxx */ ORDER BY sample_time
  MEASURES
    MATCH_NUMBER() AS peak_num,
    LAST(GOINGUP.sample_time) AS peak_time,
    LAST(GOINGUP.active_sessions) AS peak_active_sessions
  ALL ROWS PER MATCH
  PATTERN (GOINGUP+ GOINGDOWN+)
  DEFINE
    GOINGUP AS (GOINGUP.active_sessions > PREV(GOINGUP.active_sessions)),
    GOINGDOWN AS (GOINGDOWN.active_sessions < PREV(GOINGDOWN.active_sessions))
) 
WHERE active_sessions > 10 * cpu_cores.value
ORDER BY sample_time
/
