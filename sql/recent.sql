SELECT TO_CHAR(SYSDATE, 'YYYY_MM_DD_HH24_MI') "YYYY_MM_DD_HH_MI" FROM DUAL;

SELECT COUNT(*) secs,
       a.inst_id,
       a.sql_id,
       COUNT(DISTINCT a.session_id||'.'||a.session_serial#) sessions,
       a.module,
       s.sql_text
  FROM gv$active_session_history a,
       gv$sql s
 WHERE a.sample_time > TO_TIMESTAMP('&&YYYY_MM_DD_HH_MI', 'YYYY-MM-DD-HH24-MI')
   AND a.sql_id IS NOT NULL
   AND s.inst_id = a.inst_id 
   AND s.sql_id = a.sql_id
   AND s.child_number = a.sql_child_number
 GROUP BY       
       a.inst_id,
       a.sql_id,
       a.module,
       s.sql_text
HAVING COUNT(*) > 10
 ORDER BY
       1 DESC,
       2, 3
/
