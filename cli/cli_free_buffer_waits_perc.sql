SELECT ROUND(100 * SUM(CASE event WHEN 'free buffer waits' THEN 1 ELSE 0 END) / COUNT(*)) AS free_buffer_waits_perc
  FROM dba_hist_active_sess_history
 WHERE sample_time > SYSDATE - 7
/