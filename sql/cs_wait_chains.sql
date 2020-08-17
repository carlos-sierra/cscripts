----------------------------------------------------------------------------------------
--
-- File name:   cs_wait_chains.sql
--
-- Purpose:     Execution Plans and SQL performance metrics for a given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2019/12/02
--
-- Usage:       Execute connected to PDB or CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_wait_chains.sql
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
DEF cs_script_name = 'cs_wait_chains';
--
--ALTER SESSION SET container = CDB$ROOT;
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
COL obj_cnt FOR 99,990;
COL api FOR A30 TRUNC;
COL pdb_name FOR A30 TRUNC;
COL pdbs FOR 9999;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql
@@cs_internal/cs_spool_id.sql
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
       c.con_id,
       c.name AS pdb_name,
       w.row_wait_obj#,
       w.chain_signature,
       CASE
         WHEN (SELECT COUNT(*)
                 FROM v$wait_chains b -- blockee
                WHERE w.blocker_is_valid = 'FALSE'
                  AND b.chain_is_cycle = 'FALSE'
                  AND b.chain_signature <> '<not in a wait>'
                  AND b.blocker_is_valid = 'TRUE'
                  AND b.blocker_sid = w.sid
                  AND b.blocker_sess_serial# = w.sess_serial#
                  AND b.con_id = w.con_id
                  AND b.chain_signature = w.chain_signature) >  0
         THEN 'TRUE'
         ELSE 'FALSE'
       END AS root_blocker,
       ROWNUM AS w_rownum
  FROM v$wait_chains w,
       v$session s,
       v$containers c
 WHERE w.chain_is_cycle = 'FALSE'
   AND w.chain_signature <> '<not in a wait>'
   AND s.sid = w.sid
   AND s.serial# = w.sess_serial#
   AND '&&cs_con_id' IN ('1', s.con_id)
   AND c.con_id = s.con_id
),
sessions AS (
SELECT '| '||
       RPAD(LPAD(' ', 2 * (LEVEL - 1), ' ')||t.sid||','||t.sess_serial#, 25, ' ')||' | '||
       RPAD(LPAD(' ', 2 * (LEVEL - 1), ' ')||NVL(t.machine, ' '), 64, ' ')||' | '||
       LPAD(NVL(TO_CHAR(t.in_wait_secs), ' '), 5, ' ')||' | '||
       RPAD(NVL(t.wait_event_text, ' '), 35, ' ')||' | '||
       RPAD(CASE 
         WHEN /*'&&cs_con_id' <> '1' AND*/ t.row_wait_obj# IS NOT NULL THEN
           ( SELECT o.object_name
               FROM cdb_objects o 
              WHERE o.con_id = t.con_id
                AND o.object_id = t.row_wait_obj# )||
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
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
