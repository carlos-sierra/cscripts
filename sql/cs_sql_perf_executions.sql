----------------------------------------------------------------------------------------
--
-- File name:   cs_sql_perf_executions.sql
--
-- Purpose:     SQL Performance Executions longer than N seconds
--
-- Author:      Carlos Sierra
--
-- Version:     2019/01/26
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sql_perf_executions.sql
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
DEF cs_script_name = 'cs_sql_perf_executions';
DEF cs_hours_range_default = '24';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--COL cs2_pdb_name NEW_V cs2_pdb_name FOR A30 NOPRI;
--SELECT SYS_CONTEXT('USERENV', 'CON_NAME') cs2_pdb_name FROM DUAL;
--ALTER SESSION SET container = CDB$ROOT;
--
PRO
PRO 3. SQL_ID :
DEF cs_sql_id = '&3.';
/
PRO
PRO 4. MORE_THAN_SECS :
DEF more_than_secs = '&4.';
/
--
SELECT '&&cs_file_prefix._&&cs_sql_id._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&more_than_secs."
@@cs_internal/cs_spool_id.sql
--
PRO TIME_FROM    : &&cs_sample_time_from. (&&cs_snap_id_from.)
PRO TIME_TO      : &&cs_sample_time_to. (&&cs_snap_id_to.)
PRO SQL_ID       : "&&cs_sql_id."
PRO MORE_THAN_SEC: "&&more_than_secs."
--
COL sql_exec_id HEA 'Execution ID';
COL sql_exec_start FOR A19 HEA 'SQL Execution Start';
COL f_sample_time FOR A23 HEA 'First Sample Time';
COL l_sample_time FOR A23 HEA 'Last Sample Time';
COL seconds FOR 99,990.000 HEA 'Seconds';
--COL session_id FOR 99999 HEA 'SID';
--COL session_serial# FOR 9999999 HEA 'SERIAL#';
COL sid_serial FOR A13 HEA '  SID,SERIAL#'; 
COL xid FOR A16 HEA 'Transaction ID';
COL sql_plan_hash_value HEA 'Plan|Hash Value';
COL username FOR A30 HEA 'Username' TRUNC;
COL pdb_name FOR A30 HEA 'PDB Name' TRUNC;
--
BREAK ON pdb_name SKIP PAGE DUP;
--
PRO
PRO SQL Performance Executions (longer than &&more_than_secs. seconds)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
ash_raw AS (
SELECT /*+ NO_MERGE */
       h.sample_time,
       h.con_id,
       h.session_id,
       h.session_serial#,
       h.xid,
       h.sql_exec_id,
       h.sql_exec_start,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id
  FROM v$active_session_history h
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.sql_exec_id IS NOT NULL
   AND h.sql_exec_start IS NOT NULL
   AND h.sql_id IS NOT NULL
   AND h.sql_id = '&&cs_sql_id.'
   AND h.sql_plan_hash_value IS NOT NULL
 UNION
SELECT /*+ NO_MERGE */
       h.sample_time,
       h.con_id,
       h.session_id,
       h.session_serial#,
       h.xid,
       h.sql_exec_id,
       h.sql_exec_start,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id
  FROM dba_hist_active_sess_history h
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND h.sql_exec_id IS NOT NULL
   AND h.sql_exec_start IS NOT NULL
   AND h.sql_id IS NOT NULL
   AND h.sql_id = '&&cs_sql_id.'
   AND h.sql_plan_hash_value IS NOT NULL
),
ash_enum AS (
SELECT /*+ NO_MERGE */
       h.sample_time,
       h.con_id,
       h.session_id,
       h.session_serial#,
       h.xid,
       h.sql_exec_id,
       h.sql_exec_start,
       h.sql_id,
       h.sql_plan_hash_value,
       h.user_id,
       ROW_NUMBER() OVER (PARTITION BY h.con_id, h.session_id, h.session_serial#, h.xid, h.sql_exec_id, h.sql_exec_start, h.sql_id, h.sql_plan_hash_value ORDER BY h.sample_time ASC NULLS LAST) row_num_asc,
       ROW_NUMBER() OVER (PARTITION BY h.con_id, h.session_id, h.session_serial#, h.xid, h.sql_exec_id, h.sql_exec_start, h.sql_id, h.sql_plan_hash_value ORDER BY h.sample_time DESC NULLS LAST) row_num_desc
  FROM ash_raw h
),
ash_secs AS (
SELECT /*+ NO_MERGE */
       f.con_id,
       f.session_id,
       f.session_serial#,
       f.xid,
       f.sql_exec_id,
       f.sql_exec_start,
       f.sql_id,
       f.sql_plan_hash_value,
       f.user_id,
       NVL((86400 * EXTRACT(DAY FROM (l.sample_time - f.sql_exec_start))) + (3600 * EXTRACT(HOUR FROM (l.sample_time - f.sql_exec_start))) + (60 * EXTRACT(MINUTE FROM (l.sample_time - f.sql_exec_start))) + EXTRACT(SECOND FROM (l.sample_time - f.sql_exec_start)), 0) seconds,
       f.sample_time f_sample_time,
       l.sample_time l_sample_time
  FROM ash_enum f,
       ash_enum l
 WHERE f.row_num_asc = 1
   AND l.row_num_desc = 1
   AND l.con_id = f.con_id
   AND l.session_id = f.session_id
   AND l.session_serial# = f.session_serial#
   AND NVL(l.xid, UTL_RAW.CAST_TO_RAW('-666')) = NVL(f.xid, UTL_RAW.CAST_TO_RAW('-666'))
   AND l.sql_exec_id = f.sql_exec_id
   AND l.sql_exec_start = f.sql_exec_start
   AND l.sql_id = f.sql_id
   AND l.sql_plan_hash_value = f.sql_plan_hash_value
   AND l.user_id = f.user_id
)
SELECT h.sql_exec_id,
       TO_CHAR(h.sql_exec_start, '&&cs_datetime_full_format.') sql_exec_start,
       TO_CHAR(h.f_sample_time, '&&cs_timestamp_full_format.') f_sample_time,
       TO_CHAR(h.l_sample_time, '&&cs_timestamp_full_format.') l_sample_time,
       h.seconds,
       --h.session_id,
       --h.session_serial#,
       LPAD(h.session_id,5)||','||h.session_serial# sid_serial,
       h.xid,
       h.sql_plan_hash_value,
       u.username,
       c.name pdb_name
  FROM ash_secs h,
       v$containers c,
       cdb_users u
 WHERE c.con_id = h.con_id
   AND c.open_mode = 'READ WRITE'
   AND u.con_id = h.con_id
   AND u.user_id = h.user_id
   AND h.seconds > NVL(TO_NUMBER('&&more_than_secs.'), 0)
 ORDER BY 
       c.name,
       h.sql_exec_id
/
--
CLEAR BREAK;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&more_than_secs."
--
@@cs_internal/cs_spool_tail.sql
--
--ALTER SESSION SET CONTAINER = &&cs2_pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--