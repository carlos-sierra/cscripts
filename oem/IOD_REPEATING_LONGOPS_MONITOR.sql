-- IOD_REPEATING_LONGOPS_MONITOR (hourly) KIEV
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, '*** Must execute on PRIMARY ***');
  END IF;
END;
/
WHENEVER SQLERROR EXIT FAILURE;
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
DEF seconds_threshold = '1200';
DEF last_update_threshold_secs = '3600';
--
COL pdb_name FOR A35;
COL sid_serial FOR A10;
COL sql_exec_start FOR A19;
COL last_update FOR A19;
COL username FOR A30;
COL sql_text FOR A80;
--
PRO
PRO LONG RUNNING SQL
PRO ~~~~~~~~~~~~~~~~
SELECT c.name||'('||o.con_id||')' pdb_name,
       TO_CHAR(o.sql_exec_start, 'YYYY-MM-DD"T"HH24:MI:SS') sql_exec_start,
       TO_CHAR(o.last_update_time, 'YYYY-MM-DD"T"HH24:MI:SS') last_update,
       o.elapsed_seconds seconds, 
       o.sid||','||o.serial# sid_serial,
       o.sql_id,
       o.sql_plan_hash_value plan_hash_value,
       o.sql_exec_id,
       o.username,
       (SELECT SUBSTR(s.sql_text, 1, 80) FROM v$sql s WHERE s.sql_id = o.sql_id AND ROWNUM = 1) sql_text
  FROM v$session_longops o,
       v$containers c
 WHERE 1 = 1
   --AND o.username <> 'SYS'
   --AND o.opname NOT LIKE 'Gather'||CHR(37)
   AND o.elapsed_seconds > TO_NUMBER('&&seconds_threshold.')
   AND o.last_update_time > SYSDATE - (TO_NUMBER('&&last_update_threshold_secs.')/24/3600)
   AND (SELECT a.name FROM v$sql s, audit_actions a  WHERE s.sql_id = o.sql_id AND a.action = s.command_type AND ROWNUM = 1) IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
   AND c.con_id = o.con_id
   AND c.open_mode = 'READ WRITE'
 ORDER BY
       c.name,
       o.sql_exec_start
/
--
DEF slowest_sql = '';
COL slowest_sql NEW_V slowest_sql FOR A200 NOPRI;
PRO
PRO LONGEST RUNNING SQL
PRO ~~~~~~~~~~~~~~~~~~~
SELECT c.name||'('||o.con_id||') '||
       o.elapsed_seconds||'s '||
       o.sid||','||o.serial#||' '||
       o.sql_id||' '||
       o.sql_plan_hash_value||' '||
       (SELECT SUBSTR(s.sql_text, 1, 80) FROM v$sql s WHERE s.sql_id = o.sql_id AND ROWNUM = 1)
       slowest_sql
  FROM v$session_longops o,
       v$containers c
 WHERE 1 = 1
   --AND o.username <> 'SYS'
   --AND o.opname NOT LIKE 'Gather'||CHR(37)
   AND o.elapsed_seconds > TO_NUMBER('&&seconds_threshold.')
   AND o.last_update_time > SYSDATE - (TO_NUMBER('&&last_update_threshold_secs.')/24/3600)
   AND (SELECT a.name FROM v$sql s, audit_actions a  WHERE s.sql_id = o.sql_id AND a.action = s.command_type AND ROWNUM = 1) IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
   AND c.con_id = o.con_id
   AND c.open_mode = 'READ WRITE'
 ORDER BY
       o.elapsed_seconds DESC
 FETCH FIRST 1 ROW ONLY
/
--
WHENEVER SQLERROR EXIT FAILURE;
BEGIN
  IF '&&slowest_sql.' IS NOT NULL THEN
    raise_application_error(-20000, '*** SQL execution over &&seconds_threshold. seconds! ***'||CHR(10)||'&&slowest_sql.');
  END IF;
END;
/
--
WHENEVER SQLERROR CONTINUE;
