SET SERVEROUT ON;
DECLARE
  l_date DATE := SYSDATE;
  l_count NUMBER;
BEGIN
  C##IOD.IOD_SESS.snap_sessions;
  SELECT COUNT(*) INTO l_count FROM C##IOD.sess_mon_session WHERE api = 'SNAP_SESSIONS' AND snap_time >= l_date;
  DBMS_OUTPUT.put_line('|'||LPAD(TO_CHAR(l_count, '999,990'), 8)||' v$session');
  SELECT COUNT(*) INTO l_count FROM C##IOD.sess_mon_lock WHERE api = 'SNAP_SESSIONS' AND snap_time >= l_date;
  DBMS_OUTPUT.put_line('|'||LPAD(TO_CHAR(l_count, '999,990'), 8)||' v$lock');
  SELECT COUNT(*) INTO l_count FROM C##IOD.sess_mon_transaction WHERE api = 'SNAP_SESSIONS' AND snap_time >= l_date;
  DBMS_OUTPUT.put_line('|'||LPAD(TO_CHAR(l_count, '999,990'), 8)||' v$transaction');
  SELECT COUNT(*) INTO l_count FROM C##IOD.sess_mon_wait_chains WHERE api = 'SNAP_SESSIONS' AND snap_time >= l_date;
  DBMS_OUTPUT.put_line('|'||LPAD(TO_CHAR(l_count, '999,990'), 8)||' v$wait_chains');
--  SELECT COUNT(*) INTO l_count FROM C##IOD.sess_mon_lc_pin WHERE api = 'SNAP_SESSIONS' AND snap_time >= l_date;
--  DBMS_OUTPUT.put_line('|'||LPAD(TO_CHAR(l_count, '999,990'), 8)||' lc pin');
--  SELECT COUNT(*) INTO l_count FROM C##IOD.sess_mon_lc_lock WHERE api = 'SNAP_SESSIONS' AND snap_time >= l_date;
--  DBMS_OUTPUT.put_line('|'||LPAD(TO_CHAR(l_count, '999,990'), 8)||' lc lock');
  SELECT COUNT(*) INTO l_count FROM C##IOD.sess_mon_objects WHERE api = 'SNAP_SESSIONS' AND snap_time >= l_date;
  DBMS_OUTPUT.put_line('|'||LPAD(TO_CHAR(l_count, '999,990'), 8)||' dba_objects');
END;
/
SET SERVEROUT OFF;