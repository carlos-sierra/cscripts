----------------------------------------------------------------------------------------
--
-- File name:   cs_sessions.sql
--
-- Purpose:     Simple list all current Sessions (all types and all statuses)
--
-- Author:      Carlos Sierra
--
-- Version:     2022/10/05
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sessions.sql
--
-- Notes:       Developed and tested on 12.1.0.2 and 19c.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sessions';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL status FOR A8 PRI;
COL last_call_et FOR 999,999,999,990 HEA 'LAST_CALL|ET_SECS';
COL logon_age FOR 999,999,990 HEA 'LOGON|AGE_SECS';
COL sid_serial FOR A12;
COL blocker FOR 9999990;
COL module_action_program FOR A50 TRUNC;
COL module FOR A40 TRUNC;
COL sql_text FOR A50 TRUNC;
COL pdb_name FOR A35 TRUNC;
COL timed_event FOR A60 HEA 'TIMED EVENT' TRUNC;
COL type FOR A10 TRUNC;
COL username FOR A20 TRUNC;
COL txn FOR A3;
COL last_call_time FOR A19;
COL logon_time FOR A19;
COL service_name FOR A50;
--
SET FEED ON;
DEF cs_session_type = 'BACKGROUND'
PRO
PRO SESSIONS: &&cs_session_type.
PRO ~~~~~~~~
WITH
v_session AS (
SELECT /*+ MATERIALIZE NO_MERGE */ * FROM v$session WHERE &&cs_con_id. IN (1, con_id) AND type = '&&cs_session_type.'
),
sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       sid,
       serial#,
       CASE WHEN final_blocking_session_status = 'VALID' THEN final_blocking_session END AS blocker,
       -- type,
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
       module_action_program,
       service_name
  FROM v_session
)
SELECT se.last_call_et,
       (SYSDATE - (se.last_call_et / 3600 / 24)) AS last_call_time,
       se.logon_age,
       se.logon_time,
       se.sid||','||se.serial# sid_serial,
       se.blocker,
       -- se.type,
       se.status,
       se.username,
       CASE WHEN se.taddr IS NOT NULL THEN 'TXN' END AS txn,
       se.timed_event,
       se.sql_id,
       (SELECT sql_text FROM v$sql sq WHERE sq.sql_id = se.sql_id AND ROWNUM = 1) sql_text,
       se.machine,
       se.module_action_program,
       c.name||'('||se.con_id||')' AS pdb_name,
       se.service_name
  FROM sessions se,
       v$containers c
 WHERE c.con_id(+) = se.con_id
   AND c.open_mode(+) = 'READ WRITE'
 ORDER BY
       se.last_call_et, 
       se.logon_age,
       se.sid,
       se.serial#
/
--
DEF cs_session_type = 'USER'
PRO
PRO SESSIONS: &&cs_session_type.
PRO ~~~~~~~~
/
SET FEED OFF;
--
COL pdb FOR A35;
COL total_pdbs FOR 9,990 HEA 'TOTAL|PDBs';
COL total_sessions FOR 99999999 HEA 'TOTAL|SESSIONS';
COL status_active FOR 999999 HEA 'STATUS|ACTIVE';
COL status_inactive FOR 99999999 HEA 'STATUS|INACTIVE';
COL type_user FOR 999999 HEA 'TYPE|USER';
COL type_background FOR 9999999999 HEA 'TYPE|BACKGROUND';
COL type_recursive FOR 9999999999 HEA 'TYPE|RECURSIVE';
COL user_active FOR 999999 HEA 'USER|ACTIVE';
COL user_inactive FOR 99999999 HEA 'USER|INACTIVE';
COL user_active_cpu FOR 999999 HEA 'USER|ACTIVE|ON_CPU';
COL user_active_txn FOR 999999 HEA 'USER|ACTIVE|TXN';
COL user_inactive_txn FOR 999999 HEA 'USER|INACTIVE|TXN';
COL user_active_waiting FOR 9999999 HEA 'USER|ACTIVE|WAITING';
COL user_scheduler FOR 999999999 HEA 'USER|ACTIVE|WAITING|SCHEDULER';
COL user_io FOR 99999999 HEA 'USER|ACTIVE|WAITING|USER_I/O';
COL user_application FOR 99999999999 HEA 'USER|ACTIVE|WAITING|APPLICATION';
COL user_concurency FOR 99999999999 HEA 'USER|ACTIVE|WAITING|CONCURRENCY';
COL user_commit FOR 9999999 HEA 'USER|ACTIVE|WAITING|COMMIT';
COL last_call_secs FOR 999,999,990 HEA 'LAST_CALL|SECONDS';
COL avg_last_call_secs FOR 999,999,990 HEA 'AVG_LAST_CALL|SECONDS';
--
-- COL pdb FOR A35;
-- COL total_sessions FOR 99999999 HEA 'TOTAL|SESSIONS';
-- COL status_active FOR 999999 HEA 'STATUS|ACTIVE';
-- COL status_inactive FOR 99999999 HEA 'STATUS|INACTIVE';
-- COL type_user FOR 999999 HEA 'TYPE|USER';
-- COL type_background FOR 9999999999 HEA 'TYPE|BACKGROUND';
-- COL type_recursive FOR 9999999999 HEA 'TYPE|RECURSIVE';
-- COL user_active FOR 999999 HEA 'USER|ACTIVE';
-- COL user_inactive FOR 99999999 HEA 'USER|INACTIVE';
-- COL user_active_cpu FOR 999999 HEA 'USER|ACTIVE|ON_CPU';
-- COL user_active_txn FOR 999999 HEA 'USER|ACTIVE|TXN';
-- COL user_inactive_txn FOR 999999 HEA 'USER|INACTIVE|TXN';
-- COL user_active_waiting FOR 9999999 HEA 'USER|ACTIVE|WAITING';
-- COL user_scheduler FOR 999999999 HEA 'USER|ACTIVE|WAITING|SCHEDULER';
-- COL user_io FOR 99999999 HEA 'USER|ACTIVE|WAITING|USER_I/O';
-- COL user_application FOR 99999999999 HEA 'USER|ACTIVE|WAITING|APPLICATION';
-- COL user_concurency FOR 99999999999 HEA 'USER|ACTIVE|WAITING|CONCURRENCY';
-- COL user_commit FOR 9999999 HEA 'USER|ACTIVE|WAITING|COMMIT';
-- COL last_call_secs FOR 999,999,990 HEA 'LAST_CALL|SECONDS';
-- COL avg_last_call_secs FOR 999,999,990 HEA 'AVG_LAST_CALL|SECONDS';
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF total_sessions status_active status_inactive type_user type_background type_recursive user_active user_inactive user_active_txn user_inactive_txn user_active_cpu user_active_waiting user_scheduler user_io user_application user_concurency user_commit ON REPORT;
--
PRO
PRO MACHINE and MODULE SUMMARY
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
all_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */ * FROM v$session WHERE &&cs_con_id. IN (1, con_id)
),
sessions
AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       machine,
       module,
       COUNT(DISTINCT con_id) AS total_pdbs,
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
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND taddr IS NOT NULL THEN 1 ELSE 0 END) user_active_txn,
       SUM(CASE WHEN type = 'USER' AND status = 'INACTIVE' AND taddr IS NOT NULL THEN 1 ELSE 0 END) user_inactive_txn,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'Scheduler' THEN 1 ELSE 0 END) user_scheduler,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'User I/O' THEN 1 ELSE 0 END) user_io,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'Application' THEN 1 ELSE 0 END) user_application,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'Concurrency' THEN 1 ELSE 0 END) user_concurency,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'Commit' THEN 1 ELSE 0 END) user_commit,
       MIN(last_call_et) last_call_secs,
       ROUND(AVG(last_call_et)) avg_last_call_secs
  FROM all_sessions
 GROUP BY
       machine,
       module
)
SELECT s.machine,
       s.module,
       s.total_pdbs,
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
       s.user_active_txn,
       s.user_inactive_txn,
       s.user_scheduler,
       s.user_io,
       s.user_application,
       s.user_concurency,
       s.user_commit,
       s.last_call_secs,
       s.avg_last_call_secs
  FROM sessions s
 ORDER BY
       s.machine,
       s.module
/
PRO
PRO MACHINE SUMMARY
PRO ~~~~~~~~~~~~~~~
WITH
all_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */ * FROM v$session WHERE &&cs_con_id. IN (1, con_id)
),
sessions
AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       machine,
       COUNT(DISTINCT con_id) AS total_pdbs,
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
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND taddr IS NOT NULL THEN 1 ELSE 0 END) user_active_txn,
       SUM(CASE WHEN type = 'USER' AND status = 'INACTIVE' AND taddr IS NOT NULL THEN 1 ELSE 0 END) user_inactive_txn,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'Scheduler' THEN 1 ELSE 0 END) user_scheduler,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'User I/O' THEN 1 ELSE 0 END) user_io,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'Application' THEN 1 ELSE 0 END) user_application,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'Concurrency' THEN 1 ELSE 0 END) user_concurency,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND state = 'WAITING' AND wait_class = 'Commit' THEN 1 ELSE 0 END) user_commit,
       MIN(last_call_et) last_call_secs,
       ROUND(AVG(last_call_et)) avg_last_call_secs
  FROM all_sessions
 GROUP BY
       machine
)
SELECT s.machine,
       s.total_pdbs,
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
       s.user_active_txn,
       s.user_inactive_txn,
       s.user_scheduler,
       s.user_io,
       s.user_application,
       s.user_concurency,
       s.user_commit,
       s.last_call_secs,
       s.avg_last_call_secs
  FROM sessions s
 ORDER BY
       s.machine
/
PRO
PRO PDB SUMMARY
PRO ~~~~~~~~~~~
WITH
all_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */ * FROM v$session WHERE &&cs_con_id. IN (1, con_id)
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
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' AND taddr IS NOT NULL THEN 1 ELSE 0 END) user_active_txn,
       SUM(CASE WHEN type = 'USER' AND status = 'INACTIVE' AND taddr IS NOT NULL THEN 1 ELSE 0 END) user_inactive_txn,
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
       s.user_active_txn,
       s.user_inactive_txn,
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
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--