@set
COL sample_time FOR A23;
COL timed_event FOR A40 TRUNC;
COL pdb_name FOR A30 TRUNC;
COL sql_text FOR A50 TRUNC;
DEF times_cpu_cores = '1';
--
WITH
threshold AS (
  SELECT /*+ MATERIALIZE NO_MERGE */ &&times_cpu_cores. * value AS value FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES' AND ROWNUM >= 1 /* MATERIALIZE */
),
active_sessions_time_series AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.con_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END AS timed_event,
       COALESCE(h.sql_id, '"null"') AS sql_id,
       COUNT(*) AS active_sessions
  FROM dba_hist_active_sess_history h
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       h.sample_time,
       h.con_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END,
       COALESCE(h.sql_id, '"null"')
UNION
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.con_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END AS timed_event,
       COALESCE(h.sql_id, '"null"') AS sql_id,
       COUNT(*) AS active_sessions
  FROM v$active_session_history h
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       h.sample_time,
       h.con_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END,
       COALESCE(h.sql_id, '"null"')
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
       t.active_sessions,
       CASE WHEN t.active_sessions < threshold.value AND t.lead_active_sessions >= threshold.value THEN 'Y' END AS b,
       CASE WHEN t.active_sessions >= threshold.value THEN 'Y' END AS p,
       CASE WHEN t.active_sessions < threshold.value AND t.lag_active_sessions >= threshold.value THEN 'Y' END AS e
  FROM threshold,
       time_dim t
 WHERE (t.active_sessions >= threshold.value OR t.lag_active_sessions >= threshold.value OR t.lead_active_sessions >= threshold.value)
   AND ROWNUM >= 1 /* MATERIALIZE */
),
con_dim AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       con_id,
       SUM(active_sessions) AS active_sessions,
       ROW_NUMBER() OVER (PARTITION BY sample_time ORDER BY SUM(active_sessions) DESC) AS rn
  FROM active_sessions_time_series
 WHERE ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       sample_time,
       con_id
),
c AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       con_id,
       active_sessions
  FROM con_dim
 WHERE rn = 1
   AND ROWNUM >= 1 /* MATERIALIZE */
),
eve_dim AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       timed_event,
       SUM(active_sessions) AS active_sessions,
       ROW_NUMBER() OVER (PARTITION BY sample_time ORDER BY SUM(active_sessions) DESC) AS rn
  FROM active_sessions_time_series
 WHERE ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       sample_time,
       timed_event
),
e AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       timed_event,
       active_sessions
  FROM eve_dim
 WHERE rn = 1
   AND ROWNUM >= 1 /* MATERIALIZE */
),
sql_dim AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       sql_id,
       SUM(active_sessions) AS active_sessions,
       ROW_NUMBER() OVER (PARTITION BY sample_time ORDER BY SUM(active_sessions) DESC) AS rn
  FROM active_sessions_time_series
 WHERE ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       sample_time,
       sql_id
),
s AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       sql_id,
       active_sessions
  FROM sql_dim
 WHERE rn = 1
   AND ROWNUM >= 1 /* MATERIALIZE */
)
SELECT t.sample_time,
       t.active_sessions,
       t.b,
       t.p,
       t.e,
       s.active_sessions AS s_active_sessions,
       s.sql_id,
       (SELECT /*+ NO_MERGE */ v.sql_text FROM v$sql v WHERE s.sql_id <> '"null"' AND v.sql_id = s.sql_id AND ROWNUM = 1 /* MATERIALIZE */) AS sql_text,
       e.active_sessions AS e_active_sessions,
       e.timed_event,
       c.active_sessions AS c_active_sessions,
       (SELECT /*+ NO_MERGE */ v.name FROM v$containers v WHERE v.con_id = c.con_id AND ROWNUM = 1 /* MATERIALIZE */) AS pdb_name,
       c.con_id
  FROM t, c, e, s
 WHERE c.sample_time = t.sample_time
   AND e.sample_time = t.sample_time
   AND s.sample_time = t.sample_time
 ORDER BY
       t.sample_time
/



