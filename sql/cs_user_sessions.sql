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
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL sid_serial FOR A10;
COL module FOR A30;
COL last_call_et FOR 999,999,990 HEA 'LAST CALL SECS';
COL logon_age FOR 999,999,990 HEA 'LOGON AGE_SECS';
COL sql_text FOR A80 TRUNC;
COL sql_id FOR A13;
COL spid FOR 99999 HEA 'OS|SPID';
COL trace_filename FOR A80;
--
WITH
user_sessions AS (
SELECT /*+ NO_MERGE */
       sid,
       serial#,
       status,
       logon_time,
       last_call_et,
       COALESCE(sql_id, prev_sql_id) sql_id,
       machine
  FROM v$session
 WHERE type = 'USER'
  AND sid <> USERENV('SID')
)
SELECT us.last_call_et,
       (SYSDATE - us.logon_time) * 24 * 3600 logon_age,
       us.sid||','||us.serial# sid_serial,
       us.status,
       us.sql_id,
       (SELECT sql_text FROM v$sql sq WHERE sq.sql_id = us.sql_id AND ROWNUM = 1) sql_text,
       us.machine
  FROM user_sessions us
 ORDER BY
       us.last_call_et, 
       us.logon_time
/
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--