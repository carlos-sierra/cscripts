COL day FOR A10;
COL sample_time FOR A25;
COL active_sessions FOR 999,990 HEA 'SESSIONS';
COL max_sessions FOR A4 HEA 'MAX';
COL peak FOR A5 HEA 'PEAK';
COL graph FOR A200 HEA 'GRAPH';
--
BREAK ON day SKIP PAGE DUPL;
--
PRO
PRO ACTIVE SESSIONS PEAKS
PRO ~~~~~~~~~~~~~~~~~~~~~
--
WITH
cpu_cores AS (
  SELECT /*+ MATERIALIZE NO_MERGE */value FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES' AND ROWNUM >= 1 /* MATERIALIZE */
),
active_sessions_time_series AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       COUNT(*) AS active_sessions
  FROM dba_hist_active_sess_history h
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       h.sample_time
UNION
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       COUNT(*) AS active_sessions
  FROM v$active_session_history h
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       h.sample_time
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
    GOINGUP AS (GOINGUP.active_sessions >= PREV(GOINGUP.active_sessions)),
    GOINGDOWN AS (GOINGDOWN.active_sessions <= PREV(GOINGDOWN.active_sessions))
) 
WHERE active_sessions > 1 * cpu_cores.value
ORDER BY sample_time
/