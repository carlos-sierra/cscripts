  SELECT  /*+ MATERIALIZE NO_MERGE */
          h.con_id,
          SUM(CASE h.session_state WHEN 'ON CPU' THEN 1 ELSE 0 END) AS on_cpu,
          SUM(CASE h.wait_class WHEN 'Scheduler' THEN 1 ELSE 0 END) AS throttled,
          (CAST(MAX(h.sample_time) AS DATE) - CAST(MIN(h.sample_time) AS DATE)) * 24 * 3600 AS seconds
  FROM    v$active_session_history h
  WHERE   1 = 1
  AND     h.sample_time > SYSDATE - (1/24)
  AND     ROWNUM >= 1
  GROUP BY
          h.con_id
  HAVING
          SUM(CASE h.wait_class WHEN 'Scheduler' THEN 1 ELSE 0 END) > SUM(CASE h.session_state WHEN 'ON CPU' THEN 1 ELSE 0 END)
/