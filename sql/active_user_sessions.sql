SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

SELECT last_call_et, sid, serial#, module, action, sql_id
  FROM v$session
 WHERE status = 'ACTIVE'
   AND type = 'USER'
   AND sid <> USERENV('SID')
 ORDER BY
       last_call_et DESC, sid, serial#
/

