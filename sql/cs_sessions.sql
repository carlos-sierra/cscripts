----------------------------------------------------------------------------------------
--
-- File name:   cs_sessions.sql
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
--              SQL> @cs_sessions.sql
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
DEF cs_script_name = 'cs_sessions';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL last_call_et FOR 999,999,999,990 HEA 'LAST_CALL|ET_SECS';
COL logon_age FOR 999,999,990 HEA 'LOGON|AGE_SECS';
COL sid_serial FOR A12;
COL module_action_program FOR A50 TRUNC;
COL sql_text FOR A50 TRUNC;
COL pdb_name FOR A35 TRUNC;
COL timed_event FOR A60 HEA 'TIMED EVENT' TRUNC;
COL type FOR A10 TRUNC;
COL username FOR A20 TRUNC;
COL last_call_time FOR A19;
COL logon_time FOR A19;
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
       type,
       status,
       username,
       paddr,
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
SELECT se.last_call_et,
       (SYSDATE - (se.last_call_et / 3600 / 24)) AS last_call_time,
       se.logon_age,
       se.logon_time,
       se.sid||','||se.serial# sid_serial,
       se.type,
       se.status,
       se.username,
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
 ORDER BY
       se.last_call_et, 
       se.logon_age,
       se.sid,
       se.serial#
/
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--

