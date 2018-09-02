COL sid_serial# FOR A12 HEA 'Sid,Serial#';
COL child_number FOR 999999 HEA 'Child|Number';
COL sql_exec_start FOR A19 HEA 'SQL Exec Start';
COL current_timed_event FOR A80 HEA 'Current Timed Event';
--
PRO
PRO ACTIVE SESSIONS (v$session)
PRO ~~~~~~~~~~~~~~~
SELECT sid||','||serial# sid_serial#,
       sql_child_number child_number,
       TO_CHAR(sql_exec_start, '&&cs_datetime_full_format.') sql_exec_start,
       CASE state WHEN 'WAITING' THEN SUBSTR(wait_class||' - '||event, 1, 100) ELSE 'ON CPU' END current_timed_event
  FROM v$session
 WHERE sql_id = '&&cs_sql_id.'
   AND status = 'ACTIVE'
 ORDER BY
       sid,serial#
/
