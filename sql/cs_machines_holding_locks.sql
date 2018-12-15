----------------------------------------------------------------------------------------
--
-- File name:   cs_machines_holding_locks.sql
--
-- Purpose:     List of Machines (applicatuon servers) holding locks
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
--              SQL> @cs_machines_holding_locks.sql
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
DEF cs_script_name = 'cs_machines_holding_locks';
DEF cs_lock_seconds_min = '1';
DEF cs_lock_seconds_max = '2';
DEF cs_hours_range_default = '24';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL cs2_pdb_name NEW_V cs2_pdb_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') cs2_pdb_name FROM DUAL;
ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."
@@cs_internal/cs_spool_id.sql
--
PRO TIME_FROM    : &&cs_sample_time_from. (&&cs_snap_id_from.)
PRO TIME_TO      : &&cs_sample_time_to. (&&cs_snap_id_to.)
PRO LOCKS_MIN    : >= &&cs_lock_seconds_min. sec
PRO LOCKS_MAX    : >= &&cs_lock_seconds_max. sec
--
COL pdb_name FOR A30;
COL avg_secs FOR 990.0;
COL min_snap_time FOR A19 HEA 'MIN_CAPTURE_TIME';
COL max_snap_time FOR A19 HEA 'MAX_CAPTURE_TIME';
--
SELECT pdb_name,
       machine,
       COUNT(*) samples_cnt,
       ROUND(AVG(ctime),1) avg_secs,
       MAX(ctime) max_secs,
       TO_CHAR(MIN(snap_time), '&&cs_datetime_full_format.') min_snap_time,
       TO_CHAR(MAX(snap_time), '&&cs_datetime_full_format.') max_snap_time
  FROM c##iod.inactive_sessions_audit_trail
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
   AND pty IN (1, 2)
   AND ctime >= TO_NUMBER('&&cs_lock_seconds_min.')
 GROUP BY
       pdb_name,
       machine
HAVING MAX(ctime) >= TO_NUMBER('&&cs_lock_seconds_max.')
 ORDER BY
       pdb_name,
       machine
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs2_pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--