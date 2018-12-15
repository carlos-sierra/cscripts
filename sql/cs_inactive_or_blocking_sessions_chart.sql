----------------------------------------------------------------------------------------
--
-- File name:   cs_inactive_or_blocking_sessions_chart.sql
--
-- Purpose:     Inactive Sessions
--
-- Author:      Carlos Sierra
--
-- Version:     2018/09/06
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_inactive_or_blocking_sessions_chart.sql
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
DEF cs_script_name = 'cs_inactive_or_blocking_sessions_chart';
DEF cs_lock_seconds = '1';
DEF cs_inactive_seconds = '3600';
DEF cs_hours_range_default = '24';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL cs2_pdb_name NEW_V cs2_pdb_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') cs2_pdb_name FROM DUAL;
ALTER SESSION SET container = CDB$ROOT;
--
PRO 3. Type: [{LOCK}|INACTIVE]
DEF cs2_type = '&3';
COL cs2_type NEW_V cs2_type NOPRI;
SELECT NVL(UPPER(TRIM('&&cs2_type.')), 'LOCK') cs2_type FROM DUAL;
--
COL avg_lock_secs FOR 999,990.0;
COL max_lock_secs FOR 999,990.0;
COL max_inactive_secs FOR 999,999,990.0;
--
SELECT machine, COUNT(*) row_count, AVG(ctime) avg_lock_secs, MAX(ctime) max_lock_secs, MAX(last_call_et) max_inactive_secs
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
BREAK ON machine SKIP 1;
COL sid_serial FOR A13 HEA '  SID,SERIAL#';
SELECT machine, LPAD(sid,5)||','||serial# sid_serial, COUNT(*) row_count, AVG(ctime) avg_lock_secs, MAX(ctime) max_lock_secs, MAX(last_call_et) max_inactive_secs
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
       machine, LPAD(sid,5)||','||serial#
 ORDER BY
       machine, LPAD(sid,5)||','||serial#
/
CLEAR BREAK;
PRO
PRO 5. Sid,Serial (opt):
DEF cs2_sid_serial = '&5';
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "Inactive or Blocking Sessions";
DEF chart_title = "&&cs2_type. &&cs2_machine. &&cs2_sid_serial.";
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to.";
DEF vaxis_title = "Seconds";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:0";
DEF vaxis_baseline = "";
--DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "&&cs_script_name..sql";
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'Max Duration'
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
my_query AS (
SELECT snap_time,
       MAX(
       CASE
       WHEN '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
        AND machine LIKE '%'||TRIM('&&cs2_machine.')||'%'
        AND sid||','||serial# LIKE '%'||REPLACE('&&cs2_sid_serial.', ' ')||'%'
        AND '&&cs2_type.' = 'LOCK' 
        AND pty IN (1, 2) 
        --AND ctime >= TO_NUMBER('&&cs_lock_seconds.')
       THEN ctime
       WHEN '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
        AND machine LIKE '%'||TRIM('&&cs2_machine.')||'%'
        AND sid||','||serial# LIKE '%'||REPLACE('&&cs2_sid_serial.', ' ')||'%'
        AND '&&cs2_type.' = 'INACTIVE' 
        AND pty IN (3, 4) 
        --AND last_call_et >= TO_NUMBER('&&cs_inactive_seconds.')
       THEN last_call_et
       ELSE 0
       END
       ) max_value
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
 GROUP BY
       snap_time
)
SELECT ', [new Date('||
       TO_CHAR(q.snap_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.snap_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.snap_time, 'DD')|| /* day */
       ','||TO_CHAR(q.snap_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.snap_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.snap_time, 'SS')|| /* second */
       ')'||
       ','||q.max_value|| 
       ']'
  FROM my_query q
 ORDER BY
       q.snap_time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area]
DEF cs_chart_type = 'Line';
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO scp &&cs_host_name.:&&cs_file_prefix._*_&&cs_reference_sanitized._*.* &&cs_local_dir.
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_type." "&&cs2_machine." "&&cs2_sid_serial." 
--
ALTER SESSION SET CONTAINER = &&cs2_pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--