----------------------------------------------------------------------------------------
--
-- File name:   ah.sql | cs_ash_awr_sample_report.sql
--
-- Purpose:     Detailed List of ASH samples from AWR
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/16
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter optional parameters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_ash_awr_sample_report.sql
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
SET PAGES 5000;
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_ash_awr_sample_report';
DEF cs_script_acronym = 'ah.sql | ';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF cs_hours_range_default = '24';
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO 3. Machine (opt): 
DEF cs2_machine = '&3.';
UNDEF 3;
--
PRO
PRO 4. SQL_ID (opt): 
DEF cs_sql_id = '&4.';
UNDEF 4;
--
PRO
PRO 5. SID,SERIAL (opt):
DEF cs_sid_serial = '&5.';
UNDEF 5;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_machine." "&&cs_sql_id." "&&cs_sid_serial."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO MACHINE      : "&&cs2_machine."
PRO SQL_ID       : "&&cs_sql_id."
PRO SID,SERIAL   : "&&cs_sid_serial."
--
CL BREAK
COL sql_text FOR A80 HEA 'SQL Text' TRUNC;
COL module_action_program FOR A80 HEA 'Module Action Program' TRUNC;
COL sample_date_time FOR A20 HEA 'Sample Date and Time';
COL samples FOR 9999,999 HEA 'Active|Sessions';
COL on_cpu_or_wait_class FOR A14 HEA 'ON CPU or|Wait Class';
COL on_cpu_or_wait_event FOR A50 HEA 'ON CPU or Timed Event';
COL session_serial FOR A16 HEA 'Session,Serial';
COL machine FOR A60 HEA 'Application Server';
COL con_id FOR 999999;
COL plans FOR 99999 HEA 'Plans';
COL sessions FOR 9999,999 HEA 'Sessions|this SQL';
COL pdb_name FOR A30 HEA 'PDB Name' TRUNC;
COL sql_id FOR A13 HEA 'Top|SQL_ID';
--
PRO
PRO ASH AWR spikes by sample time and top SQL (spikes higher than &&cs_num_cpu_cores. cpu cores)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
ash_by_sample_and_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.sql_id,
       c.name AS pdb_name,
       h.con_id,
       COUNT(*) samples,
       COUNT(DISTINCT h.sql_plan_hash_value) plans,
       ROW_NUMBER () OVER (PARTITION BY h.sample_time ORDER BY COUNT(*) DESC NULLS LAST, h.sql_id) row_number
  FROM dba_hist_active_sess_history h, v$containers c
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND ('&&cs2_machine.' IS NULL OR h.machine LIKE '%&&cs2_machine.%')
   AND ('&&cs_sql_id.' IS NULL OR h.sql_id = '&&cs_sql_id.')
   AND ('&&cs_sid_serial.' IS NULL OR h.session_id||','||h.session_serial# = '&&cs_sid_serial.')
   AND c.con_id(+) = h.con_id
 GROUP BY
       h.sample_time,
       h.sql_id,
       c.name,
       h.con_id
)
SELECT TO_CHAR(h.sample_time, '&&cs_datetime_full_format.') sample_date_time,
       SUM(h.samples) samples,
       '|' AS "|",
       MAX(CASE h.row_number WHEN 1 THEN h.sql_id END) sql_id,
       SUM(CASE h.row_number WHEN 1 THEN h.samples ELSE 0 END) sessions,
       MAX(CASE WHEN h.row_number = 1 AND h.sql_id IS NOT NULL THEN h.plans END) plans,
       MAX(CASE h.row_number WHEN 1 THEN h.con_id END) con_id,       
       MAX(CASE h.row_number WHEN 1 THEN h.pdb_name END) AS pdb_name,       
       MAX(CASE WHEN h.row_number = 1 AND h.sql_id IS NOT NULL THEN (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sqlstats q WHERE q.sql_id = h.sql_id AND ROWNUM = 1) END) sql_text
  FROM ash_by_sample_and_sql h
 GROUP BY
       h.sample_time
HAVING SUM(h.samples) >= &&cs_num_cpu_cores.
 ORDER BY
       h.sample_time
/
--
PRO
PRO ASH by sample time and top SQL
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
ash_by_sample_and_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       h.sql_id,
       c.name AS pdb_name,
       h.con_id,
       COUNT(*) samples,
       COUNT(DISTINCT h.sql_plan_hash_value) plans,
       ROW_NUMBER () OVER (PARTITION BY h.sample_time ORDER BY COUNT(*) DESC NULLS LAST, h.sql_id) row_number
  FROM dba_hist_active_sess_history h, v$containers c
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND ('&&cs2_machine.' IS NULL OR h.machine LIKE '%&&cs2_machine.%')
   AND ('&&cs_sql_id.' IS NULL OR h.sql_id = '&&cs_sql_id.')
   AND ('&&cs_sid_serial.' IS NULL OR h.session_id||','||h.session_serial# = '&&cs_sid_serial.')
   AND c.con_id(+) = h.con_id
 GROUP BY
       h.sample_time,
       h.sql_id,
       c.name,
       h.con_id
)
SELECT TO_CHAR(h.sample_time, '&&cs_datetime_full_format.') sample_date_time,
       SUM(h.samples) samples,
       '|' AS "|",
       MAX(CASE h.row_number WHEN 1 THEN h.sql_id END) sql_id,
       SUM(CASE h.row_number WHEN 1 THEN h.samples ELSE 0 END) sessions,
       MAX(CASE WHEN h.row_number = 1 AND h.sql_id IS NOT NULL THEN h.plans END) plans,
       MAX(CASE h.row_number WHEN 1 THEN h.con_id END) con_id,       
       MAX(CASE h.row_number WHEN 1 THEN h.pdb_name END) AS pdb_name,       
       MAX(CASE WHEN h.row_number = 1 AND h.sql_id IS NOT NULL THEN (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sqlstats q WHERE q.sql_id = h.sql_id AND ROWNUM = 1) END) sql_text
  FROM ash_by_sample_and_sql h
 GROUP BY
       h.sample_time
 ORDER BY
       h.sample_time
/
--
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
COL is_sqlid_current FOR A4 HEA 'Is|SQL|Exec';
COL blocking_session_serial FOR A16 HEA 'Blocker|Session,Serial';
COL blocking2_session_serial FOR A16 HEA 'Blocker(2)|Session,Serial';
COL blocking3_session_serial FOR A16 HEA 'Blocker(3)|Session,Serial';
COL blocking4_session_serial FOR A16 HEA 'Blocker(4)|Session,Serial';
COL blocking5_session_serial FOR A16 HEA 'Blocker(5)|Session,Serial';
COL blocking_machine FOR A60 HEA 'Application Server (blocker)';
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
PRO
PRO ASH by sample time, appl server, session and SQL_ID
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
sess_proc AS (
SELECT /*+ MATERIALIZE NO_MERGE */ DISTINCT s.sid, s.serial#, p.spid, p.pname FROM v$session s, v$process p WHERE p.addr = s.paddr    
),
sqlstats AS (
SELECT /*+ MATERIALIZE NO_MERGE */ DISTINCT s.sql_id, s.sql_text FROM v$sqlstats s
),
ash AS (
SELECT /*+ MATERIALIZE NO_MERGE */ h.*, c.name AS pdb_name
  FROM dba_hist_active_sess_history h, v$containers c
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND ('&&cs2_machine.' IS NULL OR h.machine LIKE '%&&cs2_machine.%')
   AND ('&&cs_sql_id.' IS NULL OR h.sql_id = '&&cs_sql_id.')
   AND c.con_id(+) = h.con_id
),
sess AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       session_id,
       session_serial#,
       MAX(machine) machine
  FROM ash
 GROUP BY
       session_id,
       session_serial#
)
SELECT /*+ MONITOR GATHER_PLAN_STATISTICS */
       TO_CHAR(h.sample_time, '&&cs_datetime_full_format.') sample_date_time,
       h.machine,
       h.con_id,
       h.pdb_name,
       sp.pname,
       sp.spid,
       's:'||h.session_id||','||h.session_serial# session_serial,
       h.blocking_session_status,
       CASE WHEN (h.session_id, h.session_serial#) IN ((b.blocking_session, b.blocking_session_serial#), (b2.blocking_session, b2.blocking_session_serial#)) THEN 'DL?' END deadlock,
       CASE WHEN h.blocking_session IS NOT NULL THEN 'b:'||h.blocking_session||','||h.blocking_session_serial# END blocking_session_serial,
       CASE WHEN b.blocking_session IS NOT NULL THEN 'b2:'||b.blocking_session||','||b.blocking_session_serial# END blocking2_session_serial,
       CASE WHEN b2.blocking_session IS NOT NULL THEN 'b3:'||b2.blocking_session||','||b2.blocking_session_serial# END blocking3_session_serial,
       CASE WHEN b3.blocking_session IS NOT NULL THEN 'b4:'||b3.blocking_session||','||b3.blocking_session_serial# END blocking4_session_serial,
       CASE WHEN b4.blocking_session IS NOT NULL THEN 'b5:'||b4.blocking_session||','||b4.blocking_session_serial# END blocking5_session_serial,
       CASE
       WHEN b4.blocking_session IS NOT NULL THEN (SELECT s.machine FROM sess s WHERE s.session_id = b4.blocking_session AND s.session_serial# = b4.blocking_session_serial#) 
       WHEN b3.blocking_session IS NOT NULL THEN (SELECT s.machine FROM sess s WHERE s.session_id = b3.blocking_session AND s.session_serial# = b3.blocking_session_serial#) 
       WHEN b2.blocking_session IS NOT NULL THEN (SELECT s.machine FROM sess s WHERE s.session_id = b2.blocking_session AND s.session_serial# = b2.blocking_session_serial#) 
       WHEN b.blocking_session IS NOT NULL THEN (SELECT s.machine FROM sess s WHERE s.session_id = b.blocking_session AND s.session_serial# = b.blocking_session_serial#) 
       WHEN h.blocking_session IS NOT NULL THEN (SELECT s.machine FROM sess s WHERE s.session_id = h.blocking_session AND s.session_serial# = h.blocking_session_serial#) 
       END blocking_machine,
       h.sql_id,
       h.is_sqlid_current,
       h.sql_plan_hash_value,
       h.sql_plan_line_id,
       h.sql_child_number,
       h.sql_exec_id,
       h.xid,
       h.top_level_sql_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END on_cpu_or_wait_event,
       st.sql_text,
       SUBSTR(
       CASE WHEN TRIM(h.module) IS NOT NULL THEN 'm:'||TRIM(h.module)||' ' END||
       CASE WHEN TRIM(h.action) IS NOT NULL THEN 'a:'||TRIM(h.action)||' ' END||
       CASE WHEN TRIM(h.program) IS NOT NULL THEN 'p:'||TRIM(h.program) END
       , 1, 100) AS module_action_program,
       h.current_obj#,
       h.current_file#,
       h.current_block#,
       h.current_row#,
       h.in_connection_mgmt,
       h.in_parse,
       h.in_hard_parse,
       h.in_sql_execution,
       h.in_plsql_execution,
       h.in_plsql_rpc,
       h.in_plsql_compilation,
       h.in_java_execution,
       h.in_bind,
       h.in_cursor_close,
       h.in_sequence_load,
       CASE WHEN h.event LIKE 'enq:%' AND h.p1text LIKE 'name|mode%' AND h.p1 > 0 THEN CHR(BITAND(h.p1,-16777216)/16777215)||CHR(BITAND(h.p1, 16711680)/65535) END AS lock_type,
       CASE WHEN h.event LIKE 'enq:%' AND h.p1text LIKE 'name|mode%' AND h.p1 > 0 THEN TO_CHAR(BITAND(h.p1, 65535)) END AS lock_mode,
       NVL2(TRIM(h.p1text), h.p1text||':'||h.p1, NULL)||NVL2(TRIM(h.p2text), ', '||h.p2text||':'||h.p2, NULL)||NVL2(TRIM(h.p3text), ', '||h.p3text||':'||h.p3, NULL) p1_p2_p3
  FROM ash h,
       ash b,
       ash b2,
       ash b3,
       ash b4,
       sess_proc sp,
       sqlstats st
 WHERE b.sample_id(+) = h.sample_id
   AND b.session_id(+) = h.blocking_session
   AND b.session_serial#(+) = h.blocking_session_serial#
   AND b2.sample_id(+) = b.sample_id
   AND b2.session_id(+) = b.blocking_session
   AND b2.session_serial#(+) = b.blocking_session_serial#
   AND b3.sample_id(+) = b2.sample_id
   AND b3.session_id(+) = b2.blocking_session
   AND b3.session_serial#(+) = b2.blocking_session_serial#
   AND b4.sample_id(+) = b3.sample_id
   AND b4.session_id(+) = b3.blocking_session
   AND b4.session_serial#(+) = b3.blocking_session_serial#
   AND (    '&&cs_sid_serial.' IS NULL 
         OR h.session_id||','||h.session_serial# = '&&cs_sid_serial.' 
         OR h.blocking_session||','||h.blocking_session_serial# = '&&cs_sid_serial.' 
         OR b.blocking_session||','||b.blocking_session_serial# = '&&cs_sid_serial.' 
         OR b2.blocking_session||','||b2.blocking_session_serial# = '&&cs_sid_serial.' 
         OR b3.blocking_session||','||b3.blocking_session_serial# = '&&cs_sid_serial.' 
         OR b4.blocking_session||','||b4.blocking_session_serial# = '&&cs_sid_serial.'
       )
  AND sp.sid(+) = h.session_id
  AND sp.serial#(+) = h.session_serial# 
  AND st.sql_id(+) = h.sql_id 
 ORDER BY
       h.sample_time,
       h.machine,
       h.con_id,
       h.session_id,
       h.session_serial#,
       h.sql_id
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_machine." "&&cs_sql_id." "&&cs_sid_serial."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--