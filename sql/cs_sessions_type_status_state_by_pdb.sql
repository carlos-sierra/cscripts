SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
COL host NEW_V host NOPRI;
SELECT SYS_CONTEXT('USERENV','HOST') host FROM DUAL;
COL pdb FOR A35;
COL total_sessions FOR 99999999 HEA 'TOTAL|SESSIONS';
COL status_active FOR 999999 HEA 'STATUS|ACTIVE';
COL status_inactive FOR 99999999 HEA 'STATUS|INACTIVE';
COL type_user FOR 999999 HEA 'TYPE|USER';
COL type_background FOR 9999999999 HEA 'TYPE|BACKGROUND';
COL type_recursive FOR 9999999999 HEA 'TYPE|RECURSIVE';
COL user_active FOR 999999 HEA 'USER|ACTIVE';
COL user_inactive FOR 99999999 HEA 'USER|INACTIVE';
COL user_active_cpu FOR 999999 HEA 'USER|ACTIVE|ON_CPU';
COL user_active_waiting FOR 9999999 HEA 'USER|ACTIVE|WAITING';
COL user_scheduler FOR 999999999 HEA 'USER|ACTIVE|WAITING|SCHEDULER';
COL user_io FOR 99999999 HEA 'USER|ACTIVE|WAITING|USER_I/O';
COL user_application FOR 99999999999 HEA 'USER|ACTIVE|WAITING|APPLICATION';
COL user_concurency FOR 99999999999 HEA 'USER|ACTIVE|WAITING|CONCURRENCY';
COL user_commit FOR 9999999 HEA 'USER|ACTIVE|WAITING|COMMIT';
COL last_call_secs FOR 999,999,990 HEA 'LAST_CALL|SECONDS';
COL avg_last_call_secs FOR 999,999,990 HEA 'AVG_LAST_CALL|SECONDS';
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF total_sessions status_active status_inactive type_user type_background type_recursive user_active user_inactive user_active_cpu user_active_waiting user_scheduler user_io user_application user_concurency user_commit ON REPORT;
--
PRO HOST: &&host.
PRO ~~~~~
WITH
all_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */ * FROM v$session
),
sessions
AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       COUNT(*) total_sessions,
       SUM(CASE WHEN type = 'USER' THEN 1 ELSE 0 END) type_user,
       SUM(CASE WHEN type = 'BACKGROUND' THEN 1 ELSE 0 END) type_background,
       --SUM(CASE WHEN type = 'RECURSIVE' THEN 1 ELSE 0 END) type_recursive,
       SUM(CASE WHEN status = 'ACTIVE' THEN 1 ELSE 0 END) status_active,
       SUM(CASE WHEN status = 'INACTIVE' THEN 1 ELSE 0 END) status_inactive,
       SUM(CASE WHEN status = 'ACTIVE' AND type = 'USER' THEN 1 ELSE 0 END) user_active,
       SUM(CASE WHEN status = 'INACTIVE' AND type = 'USER' THEN 1 ELSE 0 END) user_inactive,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state <> 'WAITING' THEN 1 ELSE 0 END) user_active_cpu,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' THEN 1 ELSE 0 END) user_active_waiting,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'Scheduler' THEN 1 ELSE 0 END) user_scheduler,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'User I/O' THEN 1 ELSE 0 END) user_io,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'Application' THEN 1 ELSE 0 END) user_application,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'Concurrency' THEN 1 ELSE 0 END) user_concurency,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'Commit' THEN 1 ELSE 0 END) user_commit,
       MIN(last_call_et) last_call_secs,
       ROUND(AVG(last_call_et)) avg_last_call_secs
  FROM all_sessions
 GROUP BY
       con_id
)
SELECT CASE WHEN c.name IS NULL THEN 'CDB' ELSE c.name END||'('||s.con_id||')' pdb,
       s.total_sessions,
       s.type_user,
       s.type_background,
       --s.type_recursive,
       s.status_active,
       s.status_inactive,
       s.user_active,
       s.user_inactive,
       s.user_active_cpu,
       s.user_active_waiting,
       s.user_scheduler,
       s.user_io,
       s.user_application,
       s.user_concurency,
       s.user_commit,
       s.last_call_secs,
       s.avg_last_call_secs
  FROM sessions s,
       v$containers c
 WHERE c.con_id(+) = s.con_id
   AND c.open_mode(+) = 'READ WRITE'
 ORDER BY
       CASE WHEN c.name IS NULL THEN 'CDB' ELSE c.name END
/
--