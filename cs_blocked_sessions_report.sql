----------------------------------------------------------------------------------------
--
-- File name:   bs.sql | cs_blocked_sessions_report.sql
--
-- Purpose:     Blocked Sessions Report
--
-- Author:      Carlos Sierra
--
-- Version:     2022/05/25
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter optional parameters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_blocked_sessions_report.sql
--
-- Notes:       Developed and tested on 19c
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
SET PAGES 5000;
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_blocked_sessions_report';
DEF cs_script_acronym = 'bs.sql | ';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF cs_hours_range_default = '24';
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL snap_time NEW_V snap_time;
@@cs_internal/&&cs_set_container_to_cdb_root.
SELECT snap_time,
       COUNT(*) AS sessions,
       SUM(CASE WHEN blocking_session_status = 'VALID' OR final_blocking_session_status = 'VALID' THEN 1 ELSE 0 END) AS blockees,
       SUM(CASE WHEN blocking_session_status = 'VALID' OR final_blocking_session_status = 'VALID' THEN 0 ELSE 1 END) AS final_blockers
  FROM &&cs_tools_schema..iod_blocked_session
 WHERE snap_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND snap_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 GROUP BY
       snap_time
 ORDER BY
       snap_time
/
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO 3. Snap Time:
DEF cs_snap_time = '&3.';
UNDEF 3;
SELECT NVL('&&cs_snap_time.', '&&snap_time.') AS snap_time FROM DUAL
/
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&snap_time."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO SNAP_TIME    : "&&snap_time."
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL sql_text FOR A70 HEA 'SQL Text' TRUNC;
COL procedure_name FOR A70 HEA 'PL/SQL Library Entry Point' TRUNC;
COL module_action_program FOR A70 HEA 'Module Action Program' TRUNC;
COL sample_date_time FOR A23 HEA 'Sample Date and Time';
COL samples FOR 9999,999 HEA 'Active|Sessions';
COL on_cpu_or_wait_class FOR A14 HEA 'ON CPU or|Wait Class';
COL on_cpu_or_wait_event FOR A50 HEA 'ON CPU or Timed Event';
COL sid FOR A10 HEA 'Session';
COL machine FOR A60 HEA 'Machine or Application Server';
COL con_id FOR 999999;
COL plans FOR 99999 HEA 'Plans';
COL sessions FOR 9999,999 HEA 'Sessions|this SQL';
COL pdb_name FOR A30 HEA 'PDB Name' TRUNC;
COL sql_id FOR A13 HEA 'SQL_ID';
COL blocking_session_status FOR A11 HEA 'Blocker|Session|Status';
COL sql_plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL sql_plan_line_id FOR 9999 HEA 'Plan|Line';
COL sql_child_number FOR 999999 HEA 'Child|Number';
COL sql_exec_id FOR 99999999 HEA 'Exec ID';
COL xid FOR A16 HEA 'Transaction ID';
COL current_obj# FOR 9999999999 HEA 'Current|Obj#';
COL current_file# FOR 9999999999 HEA 'Current|File#';
COL current_block# FOR 9999999999 HEA 'Current|Block#';
COL current_row# FOR 9999999999 HEA 'Current|Row#';
COL in_connection_mgmt FOR A6 HEA 'In|Connec|Mgmt';
COL in_parse FOR A6 HEA 'In|Parse';
COL in_hard_parse FOR A6 HEA 'In|Hard|Parse';
COL in_sql_execution FOR A6 HEA 'In|SQL|Exec';
COL in_plsql_execution FOR A6 HEA 'In|PLSQL|Exec';
COL in_plsql_rpc FOR A6 HEA 'In|PLSQL|RPC';
COL in_plsql_compilation FOR A6 HEA 'In|PLSQL|Compil';
COL in_java_execution FOR A6 HEA 'In|Java|Exec';
COL in_bind FOR A6 HEA 'In|Bind';
COL in_cursor_close FOR A6 HEA 'In|Cursor|Close';
COL in_sequence_load FOR A6 HEA 'In|Seq|Load';
COL top_level_sql_id FOR A13 HEA 'Top Level|SQL_ID';
COL blocking_session FOR A10 HEA 'Blocker|Session';
COL blocking2_session FOR A10 HEA 'Blocker(2)|Session';
COL blocking3_session FOR A10 HEA 'Blocker(3)|Session';
COL blocking4_session FOR A10 HEA 'Blocker(4)|Session';
COL blocking5_session FOR A10 HEA 'Blocker(5)|Session';
COL blocking_machine FOR A60 HEA 'Machine or Application Server (blocker)';
COL deadlock FOR A4 HEA 'Dead|Lock';
COL lock_type FOR A4 HEA 'Lock';
COL lock_mode FOR A4 HEA 'Mode';
COL p1_p2_p3 FOR A100 HEA 'P1, P2, P3';
COL current_object_name FOR A40 HEA 'Current|Object Name (Object Type)' TRUNC;
COL secs_waited FOR 990.000 HEA 'Secs|Waited';
COL spid FOR A6;
COL pname FOR A5;
--
BREAK ON sample_date_time SKIP PAGE ON machine SKIP 1;
--
PRO
PRO
PRO Blockee(s) and Blocker(s) Sessions as of &&snap_time. (&&cs_tools_schema..iod_blocked_session)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
sqlstats AS (
SELECT /*+ MATERIALIZE NO_MERGE */ DISTINCT s.sql_id, s.sql_text FROM v$sqlstats s WHERE ROWNUM >= 1
),
procedures AS (
SELECT DISTINCT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */ p.con_id, p.object_id, p.subprogram_id, p.owner, p.object_name, p.procedure_name FROM cdb_procedures p WHERE ROWNUM >= 1
),
snapped_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */ h.*, c.name AS pdb_name
  FROM &&cs_tools_schema..iod_blocked_session h, v$containers c
 WHERE 1 = 1
   AND (TO_NUMBER('&&cs_con_id.') IN (0, 1, h.con_id) OR h.con_id IN (0, 1))
   AND h.snap_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.snap_time < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.snap_time = TO_DATE('&&snap_time.', '&&cs_datetime_full_format.')
   AND c.con_id(+) = h.con_id
   AND ROWNUM >= 1
),
sess AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sid,
       MAX(machine) machine
  FROM snapped_sessions
 WHERE ROWNUM >= 1
 GROUP BY
       sid
)
SELECT /*+ MONITOR GATHER_PLAN_STATISTICS ORDERED */
       TO_CHAR(h.snap_time, '&&cs_datetime_full_format.') AS sample_date_time,
       h.machine,
       h.con_id,
       h.pdb_name,
       's:'||h.sid AS sid,
       h.blocking_session_status,
       CASE WHEN h.sid IN (b.blocking_session, b2.blocking_session) THEN 'DL?' END deadlock,
       CASE WHEN h.blocking_session IS NOT NULL THEN 'b:'||h.blocking_session END blocking_session,
       CASE WHEN b.blocking_session IS NOT NULL THEN 'b2:'||b.blocking_session END blocking2_session,
       CASE WHEN b2.blocking_session IS NOT NULL THEN 'b3:'||b2.blocking_session END blocking3_session,
       CASE WHEN b3.blocking_session IS NOT NULL THEN 'b4:'||b3.blocking_session END blocking4_session,
       CASE WHEN b4.blocking_session IS NOT NULL THEN 'b5:'||b4.blocking_session END blocking5_session,
       CASE
       WHEN b4.blocking_session IS NOT NULL THEN (SELECT s.machine FROM sess s WHERE s.sid = b4.blocking_session) 
       WHEN b3.blocking_session IS NOT NULL THEN (SELECT s.machine FROM sess s WHERE s.sid = b3.blocking_session) 
       WHEN b2.blocking_session IS NOT NULL THEN (SELECT s.machine FROM sess s WHERE s.sid = b2.blocking_session) 
       WHEN b.blocking_session IS NOT NULL THEN (SELECT s.machine FROM sess s WHERE s.sid = b.blocking_session) 
       WHEN h.blocking_session IS NOT NULL THEN (SELECT s.machine FROM sess s WHERE s.sid = h.blocking_session) 
       END blocking_machine,
       h.sql_id,
       h.sql_child_number,
       h.sql_exec_id,
       h.taddr AS xid,
       h.wait_class||' - '||h.event on_cpu_or_wait_event,
       st.sql_text,
       pr.owner||
       CASE WHEN pr.object_name IS NOT NULL THEN '.'||pr.object_name END||
       CASE WHEN pr.procedure_name IS NOT NULL THEN '.'||pr.procedure_name END
       AS procedure_name,
       CASE WHEN TRIM(h.module) IS NOT NULL THEN 'm:'||TRIM(h.module)||' ' END||
       CASE WHEN TRIM(h.action) IS NOT NULL THEN 'a:'||TRIM(h.action)||' ' END||
       CASE WHEN TRIM(h.program) IS NOT NULL THEN 'p:'||TRIM(h.program) END
       AS module_action_program,
       h.row_wait_obj# current_obj#,
       h.row_wait_file# current_file#,
       h.row_wait_block# current_block#,
       h.row_wait_row# current_row#,
       CASE WHEN h.event LIKE 'enq:%' AND h.p1text LIKE 'name|mode%' AND h.p1 > 0 THEN CHR(BITAND(h.p1,-16777216)/16777215)||CHR(BITAND(h.p1, 16711680)/65535) END AS lock_type,
       CASE WHEN h.event LIKE 'enq:%' AND h.p1text LIKE 'name|mode%' AND h.p1 > 0 THEN TO_CHAR(BITAND(h.p1, 65535)) END AS lock_mode,
       NVL2(TRIM(h.p1text), h.p1text||':'||h.p1, NULL)||NVL2(TRIM(h.p2text), ', '||h.p2text||':'||h.p2, NULL)||NVL2(TRIM(h.p3text), ', '||h.p3text||':'||h.p3, NULL) p1_p2_p3
  FROM snapped_sessions h,
       snapped_sessions b,
       snapped_sessions b2,
       snapped_sessions b3,
       snapped_sessions b4,
       sqlstats st,
       procedures pr
 WHERE b.sid(+) = h.blocking_session
   AND b2.sid(+) = b.blocking_session
   AND b3.sid(+) = b2.blocking_session
   AND b4.sid(+) = b3.blocking_session
   AND st.sql_id(+) = h.sql_id
   AND pr.con_id(+) = h.con_id
   AND pr.object_id(+) = h.plsql_entry_object_id
   AND pr.subprogram_id(+) = h.plsql_entry_subprogram_id
 ORDER BY
       h.snap_time,
       CASE WHEN h.machine LIKE '%iod-%' THEN 1 ELSE 2 END,
       h.machine,
       h.con_id,
       h.sid,
       h.serial#,
       h.sql_id
/
--
PRO
PRO Note: for furher details on a session, execute at CDB: SELECT * FROM &&cs_tools_schema..iod_blocked_session WHERE snap_time = TO_DATE('&&snap_time.', '&&cs_datetime_full_format.') AND sid = &&double_ampersand.sid.; followed by @pr.sql
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&snap_time."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--