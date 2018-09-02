----------------------------------------------------------------------------------------
--
-- File name:   cs_trace_session.sql
--
-- Purpose:     Traces one session
--
-- Author:      Carlos Sierra
--
-- Version:     2018/08/23
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter SID and SERIAL# when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_trace_session.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_trace_session';
--
PRO
PRO 1. sid,serial:
DEF sid_serial = '&1';
PRO
PRO 2. seconds:
DEF seconds = '&2';
PRO
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
PRO SID,SERIAL#  : &&sid_serial.
PRO SECONDS      : &&seconds.
--
EXEC DBMS_MONITOR.session_trace_enable(session_id => TO_NUMBER(SUBSTR('&&sid_serial.', 1, INSTR('&&sid_serial.', ',') - 1)), serial_num => TO_NUMBER(SUBSTR('&&sid_serial.', INSTR('&&sid_serial.', ',') + 1)), waits => TRUE, binds => TRUE, plan_stat => 'ALL_EXECUTIONS');
--
COL trace_filename NEW_V trace_filename FOR A80;
SELECT d.value||'/'||i.instance_name||'_ora_'||spid||CASE WHEN pr.traceid IS NOT NULL THEN '_'||pr.traceid END||'.trc' trace_filename
  FROM v$session se, 
       v$process pr,
       v$instance i,
       v$diag_info d
 WHERE se.type = 'USER'
   AND se.sid||','||se.serial# LIKE '%'||REPLACE('&&sid_serial.', ' ')||'%'
   AND pr.con_id = se.con_id
   AND pr.addr = se.paddr
   AND d.name = 'Diag Trace'
/
--
PRO
PRO tracing session &&sid_serial. for &&seconds. seconds...
PRO
EXEC DBMS_LOCK.sleep(seconds => &&seconds.);
EXEC DBMS_MONITOR.session_trace_disable(session_id => TO_NUMBER(SUBSTR('&&sid_serial.', 1, INSTR('&&sid_serial.', ',') - 1)), serial_num => TO_NUMBER(SUBSTR('&&sid_serial.', INSTR('&&sid_serial.', ',') + 1)));
--
PRO
PRO &&trace_filename.
PRO
PAUSE Trace completed. Press RETURN to display trace
PRO
HOST chmod 666 &&trace_filename.
HOST cat &&trace_filename.
PRO
PRO &&trace_filename.
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
PRO scp &&cs_host_name.:&&trace_filename. &&cs_local_dir.
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--