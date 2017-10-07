SELECT sid, serial#, module, action, sql_id, last_call_et last_call_secs
  FROM v$session
 WHERE status = 'ACTIVE'
   AND type = 'USER'
 ORDER BY
       sid, serial#
/

