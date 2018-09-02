----------------------------------------------------------------------------------------
--
-- File name:   cs_inactive_or_blocking_sessions_report.sql
--
-- Purpose:     Inactive Sessions
--
-- Author:      Carlos Sierra
--
-- Version:     2018/08/21
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_inactive_or_blocking_sessions_report.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_inactive_or_blocking_sessions_report';
DEF cs_lock_seconds = '1';
DEF cs_inactive_seconds = '3600';
DEF cs_hours_range_default = '24';
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL cs2_pdb_name NEW_V cs2_pdb_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') cs2_pdb_name FROM DUAL;
ALTER SESSION SET container = CDB$ROOT;
--
PRO 3. Type (opt): [{ALL}|INACTIVE|LOCK]
DEF cs2_type = '&3';
COL cs2_type NEW_V cs2_type NOPRI;
SELECT NVL(UPPER(TRIM('&&cs2_type.')), 'ALL') cs2_type FROM DUAL;
--
SELECT machine, COUNT(*) row_count
  FROM c##iod.inactive_sessions_audit_trail
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
   AND CASE
       WHEN '&&cs2_type.' IN ('ALL', 'INACTIVE') AND pty IN (3, 4) THEN 1
       WHEN '&&cs2_type.' IN ('ALL', 'LOCK') AND pty IN (1, 2) THEN 1
       ELSE 0
       END = 1
   AND ((pty IN (1, 2) AND ctime >= TO_NUMBER('&&cs_lock_seconds.')) OR (pty IN (3, 4) AND last_call_et >= TO_NUMBER('&&cs_inactive_seconds.')))
 GROUP BY
       machine
 ORDER BY
       machine
/
PRO
PRO 4. Machine (opt): 
DEF cs2_machine = '&4';
--
COL sid_serial FOR A13 HEA '  SID,SERIAL#';
SELECT LPAD(sid,5)||','||serial# sid_serial, COUNT(*) row_count
  FROM c##iod.inactive_sessions_audit_trail
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
   AND machine LIKE '%'||TRIM('&&cs2_machine.')||'%'
   AND CASE
       WHEN '&&cs2_type.' IN ('ALL', 'INACTIVE') AND pty IN (3, 4) THEN 1
       WHEN '&&cs2_type.' IN ('ALL', 'LOCK') AND pty IN (1, 2) THEN 1
       ELSE 0
       END = 1
   AND ((pty IN (1, 2) AND ctime >= TO_NUMBER('&&cs_lock_seconds.')) OR (pty IN (3, 4) AND last_call_et >= TO_NUMBER('&&cs_inactive_seconds.')))
 GROUP BY
       LPAD(sid,5)||','||serial#
 ORDER BY
       LPAD(sid,5)||','||serial#
/
PRO
PRO 5. Sid,Serial (opt):
DEF cs2_sid_serial = '&5';
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_type." "&&cs2_machine." "&&cs2_sid_serial." 
@@cs_internal/cs_spool_id.sql
--
PRO TIME_FROM    : &&cs_sample_time_from. (&&cs_snap_id_from.)
PRO TIME_TO      : &&cs_sample_time_to. (&&cs_snap_id_to.)
PRO TYPE         : "&&cs2_type." [{ALL}|INACTIVE|LOCK]
PRO MACHINE      : "&&cs2_machine."
PRO SID_SERIAL#  : "&&cs2_sid_serial."
PRO LOCKS        : >= &&cs_lock_seconds. secs
PRO INACTIVE     : >= &&cs_inactive_seconds. secs
--
COL snap_time FOR A19 HEA 'CAPTURE_TIME';
COL type FOR A8;
COL sid_serial FOR A13 HEA '  SID,SERIAL#'; 
COL ctime FOR 9,999 HEA 'LOCK|SECS';
COL last_call_et FOR 999,999 HEA 'INACTIVE|SECS';
COL lmode FOR A11 HEA 'LOCK MODE';
COL killed FOR A6;
COL death_row FOR A9 HEA 'KILL|CANDIDATE';
COL logon_time FOR A19;
COL spid FOR 99999;
COL object_id FOR 999999999;
COL username FOR A30;
COL pdb_name FOR A30;
COL sql_exec_start FOR A19;
COL prev_exec_start FOR A19;
--
SELECT TO_CHAR(snap_time, '&&cs_datetime_full_format.') snap_time,
       --status,
       CASE
       WHEN pty IN (1, 2) THEN type||' LOCK'
       WHEN pty IN (3, 4) THEN 'INACTIVE'
       ELSE 'UNKNOWN' 
       END type,
       CASE lmode
       WHEN 0 THEN '0:none'
       WHEN 1 THEN '1:null'
       WHEN 2 THEN '2:row-S'
       WHEN 3 THEN '3:row-X'
       WHEN 4 THEN '4:share'
       WHEN 5 THEN '5:S/row-X'
       WHEN 6 THEN '6:exclusive'
       END lmode,
       machine,
       LPAD(sid,5)||','||serial# sid_serial,
       ctime,
       last_call_et,
       killed,
       death_row,
       object_id,
       sql_id,
       TO_CHAR(sql_exec_start, '&&cs_datetime_full_format.') sql_exec_start,
       prev_sql_id,
       TO_CHAR(prev_exec_start, '&&cs_datetime_full_format.') prev_exec_start,
       username,
       TO_CHAR(logon_time, '&&cs_datetime_full_format.') logon_time,
       spid,
       osuser,
       pdb_name
       --,program    
       --,module    
       --,client_info
       --,reason
       --,pty
       --,status
       --,service_name
  FROM c##iod.inactive_sessions_audit_trail
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
   AND machine LIKE '%'||TRIM('&&cs2_machine.')||'%'
   AND sid||','||serial# LIKE '%'||REPLACE('&&cs2_sid_serial.', ' ')||'%'
   AND CASE
       WHEN '&&cs2_type.' IN ('ALL', 'INACTIVE') AND pty IN (3, 4) THEN 1
       WHEN '&&cs2_type.' IN ('ALL', 'LOCK') AND pty IN (1, 2) THEN 1
       ELSE 0
       END = 1
   AND ((pty IN (1, 2) AND ctime >= TO_NUMBER('&&cs_lock_seconds.')) OR (pty IN (3, 4) AND last_call_et >= TO_NUMBER('&&cs_inactive_seconds.')))
 ORDER BY
       snap_time
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_type." "&&cs2_machine." "&&cs2_sid_serial." 
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs2_pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--