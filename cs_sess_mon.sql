----------------------------------------------------------------------------------------
--
-- File name:   cs_sess_mon.sql
--
-- Purpose:     Monitored Sessions
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/25
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sess_mon.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sess_mon';
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL snap_time NEW_V snap_time;
COL sessions FOR 999,990;
COL blockers FOR 999,990;
COL blockees FOR 999,990;
COL blocker FOR 9999999;
COL et_secs FOR 999,999,990;
COL killed FOR 99,990;
COL lck_cnt FOR 99,990;
COL txn_cnt FOR 99,990;
COL chn_cnt FOR 99,990;
--COL lcp_cnt FOR 99,990;
--COL lcl_cnt FOR 99,990;
COL obj_cnt FOR 99,990;
COL api FOR A30 TRUNC;
COL pdb_name FOR A30 TRUNC;
COL pdbs FOR 9999;
--
DEF only_killed = 'N';
PRO
PRO Monitored Sessions (&&cs_tools_schema..sess_mon_session)
PRO ~~~~~~~~~~~~~~~~~~
--
WITH
sqf_session AS (
SELECT /*+ MATERIALIE NO_MERGE */
       m.snap_time,
       m.api,
       m.killed_flag,
       m.last_call_et,
       m.wait_time_micro,
       m.final_blocking_session,
       m.pdb_name
  FROM &&cs_tools_schema..sess_mon_session m
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', m.pdb_name)
),
sqf_lock AS (
SELECT /*+ MATERIALIE NO_MERGE */
       l.snap_time,
       l.api,
       COUNT(*) AS cnt
  FROM &&cs_tools_schema..sess_mon_lock l
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', l.pdb_name)
 GROUP BY
       l.snap_time,
       l.api
),
sqf_transaction AS (
SELECT /*+ MATERIALIE NO_MERGE */
       t.snap_time,
       t.api,
       COUNT(*) AS cnt
  FROM &&cs_tools_schema..sess_mon_transaction t
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', t.pdb_name)
 GROUP BY
       t.snap_time,
       t.api
),
sqf_wait_chains AS (
SELECT /*+ MATERIALIE NO_MERGE */
       w.snap_time,
       w.api,
       COUNT(*) AS cnt
  FROM &&cs_tools_schema..sess_mon_wait_chains w
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', w.pdb_name)
 GROUP BY
       w.snap_time,
       w.api
),
sqf_sessions_aggregate AS (
SELECT /*+ MATERIALIE NO_MERGE */
       m.snap_time,
       COUNT(*) AS sessions,
       SUM(CASE m.killed_flag WHEN 'Y' THEN 1 ELSE 0 END) AS killed,
       LEAST(MAX(m.last_call_et), MAX(m.wait_time_micro) / 1e6) AS et_secs, 
       COUNT(DISTINCT m.final_blocking_session) AS blockers, 
       CASE COUNT(DISTINCT m.final_blocking_session) WHEN 1 THEN MIN(m.final_blocking_session) END AS blocker, 
       SUM(CASE WHEN m.final_blocking_session IS NOT NULL THEN 1 ELSE 0 END) AS blockees, 
       l.cnt AS lck_cnt,
       t.cnt AS txn_cnt,
       w.cnt AS chn_cnt,
       m.api, 
       COUNT(DISTINCT m.pdb_name) AS pdbs
  FROM sqf_session m,
       sqf_lock l,
       sqf_transaction t,
       sqf_wait_chains w
 WHERE l.snap_time(+) = m.snap_time
   AND l.api(+) = m.api
   AND t.snap_time(+) = m.snap_time
   AND t.api(+) = m.api
   AND w.snap_time(+) = m.snap_time
   AND w.api(+) = m.api
 GROUP BY
       m.snap_time,
       m.api,
       l.cnt,
       t.cnt,
       w.cnt
)
SELECT snap_time,
       sessions,
       killed,
       et_secs, 
       blockers, 
       blocker, 
       blockees, 
       lck_cnt,
       txn_cnt,
       chn_cnt,
       api, 
       pdbs
  FROM sqf_sessions_aggregate
 WHERE '&&only_killed.' = 'N' OR killed > 0
 ORDER BY
       snap_time
/
--
SET TERM OFF;
SAVE /tmp/cs_sess_mon.tmp REPLACE;
SET TERM ON;
--
DEF only_killed = 'Y';
PRO
PRO Killed Sessions (&&cs_tools_schema..sess_mon_session)
PRO ~~~~~~~~~~~~~~~
/
--
PRO
PRO 1. Enter SNAP_TIME:
DEF snap_time_p = '&1.';
UNDEF 1;
SELECT COALESCE('&&snap_time_p.', '&&snap_time.') AS snap_time FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&snap_time."
@@cs_internal/cs_spool_id.sql
--
PRO SNAP_TIME    : &&snap_time.
--
DEF only_killed = 'N';
PRO
PRO Monitored Sessions (&&cs_tools_schema..sess_mon_session)
PRO ~~~~~~~~~~~~~~~~~~
@/tmp/cs_sess_mon.tmp
--
DEF only_killed = 'Y';
PRO
PRO Killed Sessions (&&cs_tools_schema..sess_mon_session)
PRO ~~~~~~~~~~~~~~~
/
--
HOS rm /tmp/cs_sess_mon.tmp
SELECT COALESCE('&&snap_time_p.', '&&snap_time.') AS snap_time FROM DUAL;
--
PRO
PRO Blocked Sessions (v$wait_chains)
PRO ~~~~~~~~~~~~~~~~
SET HEA OFF PAGES 0;
COL line FOR A500;
WITH 
sessions_in_tree AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       w.chain_id,
       w.sid,
       w.sess_serial#,
       s.machine,
       w.blocker_is_valid,
       w.blocker_sid,
       w.blocker_sess_serial#,
       w.blocker_chain_id,
       w.in_wait_secs,
       w.wait_event_text,
       w.pdb_name,       
       w.api,
       w.row_wait_obj#,
       w.chain_signature,
       CASE
         WHEN (SELECT COUNT(*)
                 FROM &&cs_tools_schema..sess_mon_wait_chains b -- blockee
                WHERE w.blocker_is_valid = 'FALSE'
                  AND '&&cs_con_name.' IN ('CDB$ROOT', b.pdb_name) 
                  AND b.snap_time = '&&snap_time.'
                  AND b.chain_is_cycle = 'FALSE'
                  AND b.chain_signature <> '<not in a wait>'
                  AND b.blocker_is_valid = 'TRUE'
                  AND b.blocker_sid = w.sid
                  AND b.blocker_sess_serial# = w.sess_serial#
                  AND b.pdb_name = w.pdb_name
                  AND b.api = w.api
                  AND b.chain_signature = w.chain_signature) >  0
         THEN 'TRUE'
         ELSE 'FALSE'
       END AS root_blocker,
       ROWNUM AS w_rownum
  FROM &&cs_tools_schema..sess_mon_wait_chains w,
       &&cs_tools_schema..sess_mon_session s
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', w.pdb_name) 
   AND w.snap_time = '&&snap_time.'
   AND w.chain_is_cycle = 'FALSE'
   AND w.chain_signature <> '<not in a wait>'
   AND s.snap_time(+) = w.snap_time
   AND s.api(+) = w.api
   AND s.sid(+) = w.sid
   AND s.serial#(+) = w.sess_serial#
),
sessions AS (
SELECT '| '||
       RPAD(LPAD(' ', 2 * (LEVEL - 1), ' ')||t.sid||','||t.sess_serial#, 25, ' ')||' | '||
       --RPAD(NVL(t.machine, ' '), 64, ' ')||' | '||
       RPAD(LPAD(' ', 2 * (LEVEL - 1), ' ')||NVL(t.machine, ' '), 64, ' ')||' | '||
       LPAD(NVL(TO_CHAR(t.in_wait_secs), ' '), 5, ' ')||' | '||
       RPAD(NVL(t.wait_event_text, ' '), 35, ' ')||' | '||
       RPAD(CASE 
         WHEN t.row_wait_obj# IS NOT NULL THEN
           ( SELECT o.object_name
               FROM &&cs_tools_schema..sess_mon_objects o 
              WHERE '&&cs_con_name.' IN ('CDB$ROOT', o.pdb_name) 
                AND o.snap_time = '&&snap_time.'
                AND o.object_id = t.row_wait_obj#
                AND o.pdb_name = t.pdb_name
                AND o.api = t.api )||
           '('||t.row_wait_obj#||')'
         ELSE ' '
       END, 35, ' ')||' | '||
       RPAD(NVL(t.pdb_name, ' '), 30, ' ')||' | '||
       RPAD(NVL(t.chain_signature, ' '), 200, ' ')||' |' AS line
  FROM sessions_in_tree t
 WHERE 'TRUE' IN (t.blocker_is_valid, t.root_blocker)
 START WITH t.root_blocker = 'TRUE'
 CONNECT BY t.blocker_sid = PRIOR t.sid 
        AND t.blocker_sess_serial# = PRIOR t.sess_serial#
 ORDER SIBLINGS BY NVL(t.in_wait_secs, 0) DESC
)
SELECT '+'||RPAD('-', 414, '-')||'+' AS line
  FROM DUAL
 UNION ALL
SELECT '| '||
       RPAD('SID,SERIAL#', 25, ' ')||' | '||
       RPAD('MACHINE', 64, ' ')||' | '||
       LPAD('SECS', 5, ' ')||' | '||
       RPAD('WAIT EVENT', 35, ' ')||' | '||
       RPAD('OBJECT', 35, ' ')||' | '||
       RPAD('PDB NAME', 30, ' ')||' | '||
       RPAD('CHAIN SIGNATURE', 200, ' ')||' |' AS line
  FROM DUAL
 UNION ALL
SELECT '+'||RPAD('-', 414, '-')||'+' AS line
  FROM DUAL
 UNION ALL
SELECT line FROM sessions
 UNION ALL
SELECT '+'||RPAD('-', 414, '-')||'+' AS line
  FROM DUAL
/
SET HEA ON PAGES 100;
PRO
PRO Wait Chains (v$wait_chains)
PRO ~~~~~~~~~~~~
COL id FOR 999;
COL chain_is_cycle FOR A5 HEA 'CYCLE';
COL sess FOR A12 HEA 'SESSION';
COL blocker FOR A12;
COL blocker_chain_id FOR 999 HEA 'ID';
COL chain_signature FOR A150;
COL secs FOR 9990;
COL wait_event_text FOR A30 TRUNC;
COL pdb_name FOR A30 TRUNC;
COL object_name FOR A30 TRUNC;
BREAK ON id SKIP PAGE ON chain_is_cycle ON chain_signature ON pdb_name;
WITH
w AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       w.chain_id AS id,
       w.chain_is_cycle,
       w.sid||','||w.sess_serial# AS sess,
       CASE WHEN w.blocker_sid IS NOT NULL THEN w.blocker_sid||','||w.blocker_sess_serial# END AS blocker,
       w.blocker_chain_id,
       w.in_wait_secs AS secs,
       w.wait_event_text,
       w.pdb_name,       
       w.api,
       w.row_wait_obj#,
       w.chain_signature,
       ROWNUM AS w_rownum
  FROM &&cs_tools_schema..sess_mon_wait_chains w
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', w.pdb_name) 
   AND w.snap_time = '&&snap_time.'
   AND w.chain_signature <> '<not in a wait>'
),
o AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT
       o.object_id,
       o.pdb_name,
       o.api,
       o.object_name
  FROM &&cs_tools_schema..sess_mon_objects o 
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', o.pdb_name) 
   AND o.snap_time = '&&snap_time.'
)
SELECT w.id,
       w.chain_is_cycle,
       w.sess,
       W.blocker,
       w.blocker_chain_id,
       w.secs,
       w.wait_event_text,
       o.object_name,
       w.pdb_name,       
       w.chain_signature
  FROM w, o
 WHERE o.object_id(+) = w.row_wait_obj#
   AND o.pdb_name(+) = w.pdb_name
   AND o.api(+) = w.api
 ORDER BY
       w.id,
       w.w_rownum
/
PRO
@@cs_internal/cs_pr_internal.sql "SELECT * FROM &&cs_tools_schema..sess_mon_wait_chains WHERE ''&&cs_con_name.'' IN (''CDB$ROOT'', pdb_name) AND snap_time = TO_DATE(''&&snap_time.'')";
PRO
PRO Sessions (v$session)
PRO ~~~~~~~~
@@cs_internal/cs_pr_internal.sql "SELECT * FROM &&cs_tools_schema..sess_mon_session WHERE ''&&cs_con_name.'' IN (''CDB$ROOT'', pdb_name) AND snap_time = TO_DATE(''&&snap_time.'') ORDER BY final_blocking_session NULLS FIRST, sid";
PRO
PRO Locks (v$lock)
PRO ~~~~~
@@cs_internal/cs_pr_internal.sql "SELECT * FROM &&cs_tools_schema..sess_mon_lock WHERE ''&&cs_con_name.'' IN (''CDB$ROOT'', pdb_name) AND snap_time = TO_DATE(''&&snap_time.'') ORDER BY sid, type, id1";
PRO
PRO Transactions (v$transaction)
PRO ~~~~~~~~~~~~
@@cs_internal/cs_pr_internal.sql "SELECT * FROM &&cs_tools_schema..sess_mon_transaction WHERE ''&&cs_con_name.'' IN (''CDB$ROOT'', pdb_name) AND snap_time = TO_DATE(''&&snap_time.'') ORDER BY addr";
--PRO
--PRO Library Cache Pins (x$kglpn)
--PRO ~~~~~~~~~~~~~~~~~~
--@@cs_internal/cs_pr_internal.sql "SELECT * FROM &&cs_tools_schema..sess_mon_lc_pin WHERE snap_time = TO_DATE(''&&snap_time.'')";
--PRO
--PRO Library Cache Locks (x$kgllk)
--PRO ~~~~~~~~~~~~~~~~~~~
--@@cs_internal/cs_pr_internal.sql "SELECT * FROM &&cs_tools_schema..sess_mon_lc_lock WHERE snap_time = TO_DATE(''&&snap_time.'')";
PRO
PRO Objects (dba_objects)
PRO ~~~~~~~
@@cs_internal/cs_pr_internal.sql "SELECT * FROM &&cs_tools_schema..sess_mon_objects WHERE ''&&cs_con_name.'' IN (''CDB$ROOT'', pdb_name) AND snap_time = TO_DATE(''&&snap_time.'') ORDER BY object_id";
--
PRO
PRO SQL> @&&cs_script_name..sql "&&snap_time."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
