COL machine FOR A64 HEA 'Machine (Application Server)';
COL samples FOR 999,999 HEA 'Samples';
COL min_sample_time FOR A19 HEA 'Min Sample Time';
COL max_sample_time FOR A19 HEA 'Max Sample Time';
COL sid_serial# FOR A12 HEA 'Sid,Serial#';
--
BREAK ON machine SKIP 1;
--
PRO
PRO RECENT SESSIONS (v$active_session_history past 10 minutes)
PRO ~~~~~~~~~~~~~~~
SELECT machine,
       COUNT(*) samples,
       TO_CHAR(MIN(sample_time), '&&cs_datetime_full_format.') min_sample_time,
       TO_CHAR(MAX(sample_time), '&&cs_datetime_full_format.') max_sample_time,
       session_id||','||session_serial# sid_serial#,
       sql_plan_hash_value plan_hash_value
  FROM v$active_session_history
 WHERE sql_id = '&&cs_sql_id.'
   AND sample_time > SYSTIMESTAMP - INTERVAL '10' MINUTE
 GROUP BY
       machine,
       session_id||','||session_serial#,
       sql_plan_hash_value
 ORDER BY
       1, 2 DESC, 3, 4
/
--
CLEAR BREAK;
