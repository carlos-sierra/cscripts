----------------------------------------------------------------------------------------
--
-- File name:   cs_user_sessions.sql
--
-- Purpose:     User Sessions 
--
-- Author:      Carlos Sierra
--
-- Version:     2018/07/28
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_user_sessions.sql
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
DEF cs_script_name = 'cs_user_sessions';
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL sid_serial FOR A10;
COL module FOR A30;
COL last_call_et FOR 999999 HEA 'LAST|CALL|SECS';
COL sql_text FOR A81;
COL sql_ids FOR A14 HEA 'SQL_ID CURR|SQL_ID PRIOR';
COL spid FOR 99999 HEA 'OS|SPID';
COL trace_filename FOR A80;
--
BREAK ON sid_serial SKIP 1;
--
SELECT se.last_call_et, se.sid||','||se.serial# sid_serial, se.status, -- TO_NUMBER(pr.spid) spid, --SUBSTR(module, 1, 30) module, 
       NVL(se.sql_id, '"null"')||CHR(10)||NVL(se.prev_sql_id, '"null"') sql_ids,
       (SELECT SUBSTR(sq.sql_text, 1, 80) FROM v$sql sq WHERE sq.sql_id = se.sql_id AND ROWNUM = 1)||CHR(10)||
       (SELECT SUBSTR(sq.sql_text, 1, 80) FROM v$sql sq WHERE sq.sql_id = se.prev_sql_id AND ROWNUM = 1) sql_text,
       d.value||'/'||i.instance_name||'_ora_'||spid||CASE WHEN pr.traceid IS NOT NULL THEN '_'||pr.traceid END||'.trc' trace_filename
  FROM v$session se, 
       v$process pr,
       v$instance i,
       v$diag_info d
 WHERE se.type = 'USER'
   AND se.sid <> USERENV('SID')
   AND pr.con_id = se.con_id
   AND pr.addr = se.paddr
   AND d.name = 'Diag Trace'
 ORDER BY
       se.last_call_et, se.sid, se.serial#
/
--
CLEAR BREAK;
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--