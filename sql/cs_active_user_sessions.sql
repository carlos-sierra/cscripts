SET HEA ON LIN 32767 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20;
--
COL last_call_et FOR 999,999,990 HEA 'LAST_CALL|ET_SECS';
COL logon_age FOR 999,999,990 HEA 'LOGON|AGE_SECS';
COL sid_serial FOR A10;
COL module_action_program FOR A70 TRUNC;
COL sql_text FOR A70 TRUNC;
COL pdb_name FOR A30 TRUNC;
--
WITH 
sqf1 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       se.last_call_et, 
       (SYSDATE - se.logon_time) * 24 * 3600 logon_age,
       se.sid||','||se.serial# sid_serial,
       se.con_id,
       CASE WHEN TRIM(se.module) IS NOT NULL THEN 'm:'||TRIM(se.module)||' ' END||
       CASE WHEN TRIM(se.action) IS NOT NULL THEN 'a:'||TRIM(se.action)||' ' END||
       CASE WHEN TRIM(se.program) IS NOT NULL THEN 'p:'||TRIM(se.program) END
       module_action_program, 
       NVL(se.sql_id, se.prev_sql_id) sql_id
  FROM v$session se
 WHERE se.status = 'ACTIVE'
   AND se.type = 'USER'
   AND se.con_id > 2
   AND se.sid <> USERENV('SID')
)
SELECT DISTINCT
       sqf1.last_call_et,
       sqf1.logon_age,
       sqf1.sid_serial,
       sqf1.sql_id,
       s.sql_text,
       sqf1.module_action_program,
       c.name pdb_name
  FROM sqf1,
       v$sql s,
       v$containers c
 WHERE s.con_id(+) = sqf1.con_id
   AND s.sql_id(+) = sqf1.sql_id
   AND c.con_id = sqf1.con_id
   AND c.open_mode = 'READ WRITE'
 ORDER BY
       sqf1.last_call_et DESC, 
       sqf1.logon_age,
       sqf1.sid_serial
/
