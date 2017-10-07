SELECT s.machine,
       COUNT(*) sessions
  FROM v$session s, v$process p, v$instance i
 WHERE s.type = 'USER'
   AND (s.status = 'ACTIVE' OR s.last_call_et < 300)
   AND s.machine <> i.host_name
   AND p.addr = s.paddr
 GROUP BY
       s.machine
 ORDER BY
       s.machine
/

ACC machine PROMPT 'Machine prefix to trace (i.e. compute-worker%): '
ACC trace_seconds PROMPT 'Seconds to trace (i.e. 180): '

-- used to disable trace before we start then when we finish (3 places)
DECLARE
CURSOR traced_sessions IS
SELECT s.sid,
       s.serial#
  FROM v$session s
 WHERE s.sql_trace = 'ENABLED'
 ORDER BY
       s.machine,
       s.sid,
       s.serial#; 
BEGIN
FOR i IN traced_sessions
LOOP
  DBMS_MONITOR.SESSION_TRACE_DISABLE(i.sid,i.serial#);
END LOOP;
END;
/
SAVE /tmp/disable_trace.sql REPLACE

SET VER OFF;
SPO /tmp/trace_sessions_dynamic.sql
SET SERVEROUT ON;
DECLARE
l_inactive_seconds INTEGER := 300;
l_trace_path VARCHAR2(4000);
CURSOR active_sessions (p_inactive_seconds IN NUMBER) IS
SELECT s.machine,
       s.sid,
       s.serial#,
       p.spid,
       s.status,
       s.last_call_et
  FROM v$session s, v$process p, v$instance i
 WHERE s.type = 'USER'
   AND (s.status = 'ACTIVE' OR s.last_call_et < p_inactive_seconds)
   AND s.machine LIKE '%&&machine.%'
   AND s.machine <> i.host_name
   AND p.addr = s.paddr
 ORDER BY
       s.machine,
       s.sid,
       s.serial#;
BEGIN
FOR i IN active_sessions(l_inactive_seconds)
LOOP
  DBMS_OUTPUT.PUT_LINE('PRO enable trace for machine:'||i.machine||' sid:'||i.sid||' serial#:'||i.serial#||' spid:'||i.spid);
  DBMS_OUTPUT.PUT_LINE('EXEC DBMS_MONITOR.SESSION_TRACE_ENABLE('||i.sid||','||i.serial#||',TRUE,TRUE);');
END LOOP;
DBMS_OUTPUT.PUT_LINE('PRO tracing for '||&&trace_seconds.||' seconds. please wait.');
DBMS_OUTPUT.PUT_LINE('EXEC DBMS_LOCK.SLEEP('||&&trace_seconds.||');');
FOR i IN active_sessions(l_inactive_seconds + &&trace_seconds.)
LOOP
  DBMS_OUTPUT.PUT_LINE('PRO disable trace for machine:'||i.machine||' sid:'||i.sid||' serial#:'||i.serial#||' spid:'||i.spid);
  DBMS_OUTPUT.PUT_LINE('EXEC DBMS_MONITOR.SESSION_TRACE_DISABLE('||i.sid||','||i.serial#||');');
END LOOP;
DBMS_OUTPUT.PUT_LINE('@/tmp/disable_trace.sql');
DBMS_OUTPUT.PUT_LINE('HOST rm /tmp/big.trc');
DBMS_OUTPUT.PUT_LINE('HOST rm /tmp/trace_sessions.zip');
DBMS_OUTPUT.PUT_LINE('HOST rm /tmp/tkprof_sessions.zip');
SELECT value INTO l_trace_path FROM v$diag_info WHERE name = 'Diag Trace';
FOR i IN active_sessions(l_inactive_seconds + &&trace_seconds.)
LOOP
  DBMS_OUTPUT.PUT_LINE('HOST zip -j /tmp/trace_sessions.zip '||l_trace_path||'/*_ora_'||i.spid||'.trc');
  DBMS_OUTPUT.PUT_LINE('HOST tkprof '||l_trace_path||'/*_ora_'||i.spid||'.trc /tmp/tkprof_'||i.machine||'_'||i.sid||'_'||i.serial#||'_'||i.spid||'.txt sort=exeela,fchela');
  DBMS_OUTPUT.PUT_LINE('HOST zip -mj /tmp/tkprof_sessions.zip /tmp/tkprof_'||i.machine||'_'||i.sid||'_'||i.serial#||'_'||i.spid||'.txt');
  DBMS_OUTPUT.PUT_LINE('HOST cat '||l_trace_path||'/*_ora_'||i.spid||'.trc >> /tmp/big.trc');
END LOOP;
DBMS_OUTPUT.PUT_LINE('HOST tkprof /tmp/big.trc /tmp/tkprof_all.txt sort=exeela,fchela');
DBMS_OUTPUT.PUT_LINE('HOST rm /tmp/big.trc');
DBMS_OUTPUT.PUT_LINE('HOST zip -mj /tmp/tkprof_sessions.zip /tmp/tkprof_all.txt');
DBMS_OUTPUT.PUT_LINE('PRO files /tmp/tkprof_sessions.zip and /tmp/trace_sessions.zip are now available');
END;
/
SPO OFF;

@/tmp/trace_sessions_dynamic.sql
HOST rm /tmp/trace_sessions_dynamic.sql
@/tmp/disable_trace.sql
HOST rm /tmp/disable_trace.sql
