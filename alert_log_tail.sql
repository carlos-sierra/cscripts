-- Last 50 lines of alert log refreshed every 5 seconds 20 times 
COL alert_log NEW_V alert_log FOR A150;
SELECT d.value||'/alert_'||t.instance||'.log' alert_log FROM v$diag_info d, v$thread t WHERE d.name = 'Diag Trace';
HOS tail -n 50 &&alert_log.
PRO Executing alert_log_tail.sql 20 times...
EXEC DBMS_LOCK.sleep(5);
CLEAR SCREEN;
@@alert_log_tail.sql