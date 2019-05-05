SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
--
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
--
SELECT sid, serial#, status, type, module, sql_id, last_call_et last_call_secs, logon_time
  FROM v$session
 WHERE machine = '&&machine.'
 ORDER BY
       sid, serial#
/
--