SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
COL host_name NEW_V host_name;
SELECT host_name FROM v$instance;
--
SELECT machine, COUNT(*) sessions, 
       SUM(CASE status WHEN 'ACTIVE' THEN 1 ELSE 0 END) active,
       SUM(CASE status WHEN 'INACTIVE' THEN 1 ELSE 0 END) inactive,
       SUM(CASE status WHEN 'KILLED' THEN 1 ELSE 0 END) killed,
       MIN(last_call_et) last_call_secs
  FROM v$session
 WHERE type = 'USER'
   AND sid <> USERENV('SID')
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
PRO 2. Enter STATUS (opt): [{ALL}|ACTIVE|INACTIVE]
DEF status = '&2.';
PRO
SET HEA OFF PAGES 0 FEED OFF VER OFF ECHO OFF;
SPO kill_sessions_driver.sql;
SELECT 'ALTER SYSTEM DISCONNECT SESSION '''||e.sid||','||e.serial#||''' IMMEDIATE;' 
  FROM v$session e
 WHERE e.machine LIKE '&&machine.%'
   AND e.type = 'USER'
   AND e.sid <> USERENV('SID')
   AND e.machine <> '&&host_name.'
   AND CASE 
         WHEN NVL(UPPER(TRIM('&&status.')), 'ALL') = 'ALL' THEN 1 
         WHEN NVL(UPPER(TRIM('&&status.')), 'ALL') = e.status THEN 1
         ELSE 0
       END = 1
/
SPO OFF;
PRO
PRO Execute: kill_sessions_driver.sql to kill &&status. sessions from &&machine.
SET HEA ON LIN 80 PAGES 24;


