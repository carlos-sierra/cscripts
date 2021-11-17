@set
COL sample_time FOR A23;
DEF times_cpu_cores = '1';
--
WITH
threshold AS (
  SELECT /*+ MATERIALIZE NO_MERGE */ &&times_cpu_cores. * value AS value FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES' AND ROWNUM >= 1 /* MATERIALIZE */
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
),
time_dim AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       SUM(active_sessions) AS active_sessions,
       LAG(SUM(active_sessions)) OVER (ORDER BY sample_time) AS lag_active_sessions,
       LEAD(SUM(active_sessions)) OVER (ORDER BY sample_time) AS lead_active_sessions
  FROM active_sessions_time_series
 WHERE ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       sample_time
),
t AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       t.sample_time,
       t.active_sessions
  FROM threshold,
       time_dim t
 WHERE (t.active_sessions >= threshold.value OR t.lag_active_sessions >= threshold.value OR t.lead_active_sessions >= threshold.value)
   AND ROWNUM >= 1 /* MATERIALIZE */
)
SELECT t.sample_time,
       t.active_sessions
  FROM t
 ORDER BY
       t.sample_time
/
