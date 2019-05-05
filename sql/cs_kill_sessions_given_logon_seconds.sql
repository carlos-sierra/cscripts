SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
COL host_name NEW_V host_name;
SELECT host_name FROM v$instance;
--
COL min_last_call_secs FOR 999,999,990 HEA 'MIN_LAST|CALL_SECS';
COL max_last_call_secs FOR 999,999,990 HEA 'MAX_LAST|CALL_SECS';
COL min_logon_age_secs FOR 999,999,990 HEA 'MIN_LOGON|AGE_SECS';
COL max_logon_age_secs FOR 999,999,990 HEA 'MAX_LOGON|AGE_SECS';
--
SELECT machine, COUNT(*) sessions, 
       SUM(CASE status WHEN 'ACTIVE' THEN 1 ELSE 0 END) active,
       SUM(CASE status WHEN 'INACTIVE' THEN 1 ELSE 0 END) inactive,
       SUM(CASE status WHEN 'KILLED' THEN 1 ELSE 0 END) killed,
       MIN(last_call_et) min_last_call_secs,
       MAX(last_call_et) max_last_call_secs,
       (SYSDATE - MAX(logon_time)) * 24 * 3600 min_logon_age_secs,
       (SYSDATE - MIN(logon_time)) * 24 * 3600 max_logon_age_secs
  FROM v$session
 WHERE type = 'USER'
   AND sid <> USERENV('SID')
   AND status = 'INACTIVE'
   AND machine <> '&&host_name.'
 GROUP BY 
       machine
 ORDER BY
       machine
/
PRO
PRO 1. Enter MACHINE:
DEF machine = '&1.';
PRO
COL last_call_et FOR 999,999,990 HEA 'LAST CALL SECS';
COL sid_serial FOR A12;
--
SELECT e.last_call_et,
       (SYSDATE - e.logon_time) * 24 * 3600 logon_age_secs,
       e.sid||','||e.serial# sid_serial,
       machine
  FROM v$session e
 WHERE e.machine LIKE '&&machine.%'
   AND e.type = 'USER'
   AND e.sid <> USERENV('SID')
   AND e.status = 'INACTIVE'
   AND e.machine <> '&&host_name.'
 ORDER BY 
       e.last_call_et
/
PRO
PRO 2. Enter LOGON_AGE_SECS "greater than" to kill sessions older than: (default 3600)
DEF logon_age_secs = '&2.';
PRO
PRO 3. Sleep SECONDS between kills: (default 0)
DEF sleep_seconds = '&3.';
PRO
SET HEA OFF PAGES 0 FEED OFF VER OFF ECHO OFF;
SPO kill_sessions_driver.sql;
SELECT '-- logon age: '||(SYSDATE - e.logon_time) * 24 * 3600||' seconds'||CHR(10)||
       'ALTER SYSTEM DISCONNECT SESSION '''||e.sid||','||e.serial#||''' IMMEDIATE;'||CHR(10)||
       'EXEC DBMS_LOCK.SLEEP('||NVL('&sleep_seconds.', '0')||');'
  FROM v$session e
 WHERE e.machine LIKE '&&machine.%'
   AND e.type = 'USER'
   AND e.sid <> USERENV('SID')
   AND e.machine <> '&&host_name.'
   AND (SYSDATE - e.logon_time) * 24 * 3600 > TO_NUMBER(NVL('&logon_age_secs.', '3600'))
 ORDER BY 
       e.last_call_et
/
SPO OFF;
PRO
PRO Execute: kill_sessions_driver.sql to kill INACTIVE sessions from &&machine.
SET HEA ON LIN 80 PAGES 24;


