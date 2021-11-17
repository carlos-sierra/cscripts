SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
--
COL last_call_et FOR 999,999,999,990 HEA 'LAST_CALL|ET_SECS';
COL logon_age FOR 999,999,990 HEA 'LOGON|AGE_SECS';
COL sid_serial FOR A12;
COL blocker FOR 9999990;
COL module_action_program FOR A50 TRUNC;
COL sql_text FOR A50 TRUNC;
COL pdb_name FOR A35 TRUNC;
COL timed_event FOR A60 HEA 'TIMED EVENT' TRUNC;
COL type FOR A10 TRUNC;
COL username FOR A20 TRUNC;
COL txn FOR A3;
COL last_call_time FOR A19;
COL logon_time FOR A19;
COL sp FOR A1 HEA '-|-';
--
WITH
v_session AS (
SELECT /*+ MATERIALIZE NO_MERGE */ * FROM v$session 
),
sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       sid,
       serial#,
       CASE WHEN final_blocking_session_status = 'VALID' THEN final_blocking_session END AS blocker,
       type,
       status,
       username,
       paddr,
       taddr,
       logon_time,
       last_call_et,
       (SYSDATE - logon_time) * 24 * 3600 AS logon_age,
       COALESCE(sql_id, prev_sql_id) sql_id,
       machine,
       's:'||state||
       CASE WHEN wait_class IS NOT NULL THEN ' w:'||wait_class END||
       CASE WHEN event IS NOT NULL THEN ' - '||event END AS
       timed_event,
       CASE WHEN TRIM(module) IS NOT NULL THEN 'm:'||TRIM(module)||' ' END||
       CASE WHEN TRIM(action) IS NOT NULL THEN 'a:'||TRIM(action)||' ' END||
       CASE WHEN TRIM(program) IS NOT NULL THEN 'p:'||TRIM(program) END AS
       module_action_program
  FROM v_session
)
SELECT '-' AS sp,
       se.last_call_et,
       (SYSDATE - (se.last_call_et / 3600 / 24)) AS last_call_time,
       se.logon_age,
       se.logon_time,
       se.sid||','||se.serial# sid_serial,
       se.blocker,
       se.type,
       se.status,
       se.username,
       CASE WHEN se.taddr IS NOT NULL THEN 'TXN' END AS txn,
       se.timed_event,
       se.sql_id,
       (SELECT sql_text FROM v$sql sq WHERE sq.sql_id = se.sql_id AND ROWNUM = 1) sql_text,
       se.machine,
       se.module_action_program,
       c.name||'('||se.con_id||')' AS pdb_name
  FROM sessions se,
       v$containers c
 WHERE c.con_id(+) = se.con_id
   AND c.open_mode(+) = 'READ WRITE'
   AND se.last_call_et > 300
   AND se.logon_age > 300
   AND se.status = 'INACTIVE'
   AND se.taddr IS NOT NULL
 ORDER BY
       se.last_call_et, 
       se.logon_age,
       se.sid,
       se.serial#
/