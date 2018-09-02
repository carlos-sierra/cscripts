COL max_sample_time FOR A19 HEA 'Max Sample Time';
COL samples FOR 999,999 HEA 'Samples';
COL sid_serial# FOR A12 HEA 'Sid,Serial#';
--
PRO
PRO RECENT SESSIONS (v$active_session_history past 10s)
PRO ~~~~~~~~~~~~~~~
SELECT TO_CHAR(MAX(sample_time), '&&cs_datetime_full_format.') max_sample_time,
       COUNT(*) samples,
       session_id||','||session_serial# sid_serial#
  FROM v$active_session_history
 WHERE sql_id = '&&cs_sql_id.'
   AND sample_time > SYSTIMESTAMP - INTERVAL '10' SECOND
 GROUP BY
       session_id||','||session_serial#
 ORDER BY
       1, 2, 3
/
