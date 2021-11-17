SET HEA OFF PAGES 0 SERVEROUT ON;
DECLARE
  l_line INTEGER := 0;
  l_b1 VARCHAR2(300) := '|                         |   Active || Top #1 SQL |                                                                  || Top #1 Event |                                                    || Top #1 PDB |                                     |';
  l_b2 VARCHAR2(300) := '| Sample Time             | Sessions ||   Sessions | Top #1 SQL                                                       ||     Sessions | Top #1 Timed Event                                 ||   Sessions | Top #1 PDB                          |';
  l_s1 VARCHAR2(300) := '+-------------------------+----------++------------+------------------------------------------------------------------++--------------+----------------------------------------------------++------------+-------------------------------------+';
  l_p1 VARCHAR2(300);
BEGIN
IF &&times_cpu_cores. = 0 THEN
  DBMS_OUTPUT.put_line(l_s1);
  DBMS_OUTPUT.put_line(l_b1);
  DBMS_OUTPUT.put_line(l_b2);
  DBMS_OUTPUT.put_line(l_s1);
END IF;
FOR i IN (
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
 WHERE '&&include_hist.' = 'Y'
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
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
 WHERE '&&include_mem.' = 'Y'
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
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
)
LOOP
  l_line := l_line + 1;
  l_p1 := 
  '| '||TO_CHAR(i.sample_time, 'YYYY-MM-DD"T"HH24:MI:SS.FF3')||
  ' | '||TO_CHAR(i.active_sessions, '999,990')||
  ' ||   '||TO_CHAR(i.s_active_sessions, '999,990')||
  ' | '||RPAD(i.sql_id, 13)||
  ' '||RPAD(COALESCE(i.sql_text, ' '), 50)||
  ' ||     '||TO_CHAR(i.e_active_sessions, '999,990')||
  ' | '||RPAD(i.timed_event, 50)||
  ' ||   '||TO_CHAR(i.c_active_sessions, '999,990')||
  ' | '||RPAD(i.pdb_name||'('||i.con_id||')', 35)||
  ' | ';
  IF i.e = 'Y' AND i.b = 'Y' THEN
    DBMS_OUTPUT.put_line(l_p1);
    DBMS_OUTPUT.put_line(l_s1);
  END IF;
  IF i.b = 'Y' THEN
    DBMS_OUTPUT.put_line(l_s1);
    DBMS_OUTPUT.put_line(l_b1);
    DBMS_OUTPUT.put_line(l_b2);
    DBMS_OUTPUT.put_line(l_s1);
  END IF;
  DBMS_OUTPUT.put_line(l_p1);
  IF i.e = 'Y' AND i.b IS NULL THEN
    DBMS_OUTPUT.put_line(l_s1);
  END IF;
  IF &&times_cpu_cores. = 0 AND MOD(l_line, 100) = 0 THEN
    DBMS_OUTPUT.put_line(l_s1);
    DBMS_OUTPUT.put_line(l_b1);
    DBMS_OUTPUT.put_line(l_b2);
    DBMS_OUTPUT.put_line(l_s1);
  END IF;
END LOOP;
IF &&times_cpu_cores. = 0 THEN
  DBMS_OUTPUT.put_line(l_s1);
END IF;
END;
/
SET HEA ON PAGES 100 SERVEROUT OFF;
PRO NOTE: Sum of Active Sessions per AWR sampled time, when greater than &&times_cpu_cores.x NUM_CPU_CORES(&&cs_num_cpu_cores.). Report includes for each sampled time Top #1: SQL, Timed Event and PDB; with corresponding Sum of Active Sessions for each of these 3 dimensions.