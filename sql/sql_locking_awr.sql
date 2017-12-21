----------------------------------------------------------------------------------------
--
-- File name:   sql_locking_awr.sql
--
-- Purpose:     For a range of dates, list SQL_IDs of sessions waiting on a LOCK from
--              other sessions. And list of SQL_IDs from sessions blocking others with
--              a LOCK.
--
-- Author:      Carlos Sierra
--
-- Version:     2017/08/21
--
-- Usage:       Latency of a critical transaction has gone south on a PDB and no clear
--              evidence is visible on OEM. Suspecting SQL regression or Locking.
--
--              Designed to be used on OLTP loads, where transaction rate is high.
--
--              This script uses ASH from AWR, which is usually available from 8 to 60
--              days. Granularity of samples is by default 10 second.
--
--              To investigate locks that happened more than 3 hours ago use:
--                sql_locking_awr.sql.
--              To investigate locks that happened within the last 3 hours use:
--                sql_locking_ash.sql.
--              To investigate locks that are happening now use:
--                sql_locking_ses.sql.
--              
--              Pass values (when asked) for range of dates to review.
--              Format is YYYY-MM-DD"T"HH24:MI:SS (i.e. 2017-08-17T12:30:00).
--              Default values for parameters is: last 1 day.
--
--              Execute connected into the CDB, or PDB of interest.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sql_locking_awr.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Use together with sql_regression.sql    .          
--
--              Developed and tested on 12.1.0.2.
--
--              To further dive into SQL performance diagnostics use SQLd360.
--             
---------------------------------------------------------------------------------------
--
ACC date_time_from PROMPT 'Date and Time FROM (i.e. 2017-08-17T12:39:00) default SYSDATE - 1 day: ';
ACC date_time_to PROMPT 'Date and Time TO (i.e. 2017-08-17T12:46:00) default SYSDATE: ';

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
BREAK ON inst SKIP 1 ON snap SKIP 1 ON end_time;
COMP SUM LAB 'Total' OF samples_count ON end_time;
COMP SUM LAB 'Total' OF average_active_sessions ON end_time;
COL inst FOR 9990 HEA 'Inst';
COL snap FOR 9999999 HEA 'Snap ID';
COL end_time FOR A19 HEA 'Snap End Date';
COL samples_count FOR 9999999 HEA 'ASH|Samples';
COL waiting_sessions_count FOR 99999999 HEA 'Waiting|Sessions';
COL blocking_sessions_count FOR 99999999 HEA 'Blocking|Sessions';
COL average_active_sessions FOR 9990.0 HEA 'AAS';
COL container_id FOR 999999 HEA 'CON_ID';
COL object_number FOR 999999999 HEA 'Object ID';
COL object_owner_and_name FOR A60 HEA 'Object Owner.Name(Type)';
COL sql_text_100_only FOR A100 HEA 'SQL Text';
COL missing_session_serial FOR A16 HEA 'Missing Blocking|Session,Serial';

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;
COL date_time_from NEW_V date_time_from;
COL date_time_to NEW_V date_time_to;
SELECT NVL('&&date_time_from.', TO_CHAR(SYSDATE - 1, 'YYYY-MM-DD"T"HH24:MI:SS')) date_time_from, NVL('&&date_time_to.', TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')) date_time_to FROM DUAL;
COL this_dbid NEW_V this_dbid;
SELECT dbid this_dbid FROM v$database;
COL snap_id_from NEW_V snap_id_from;
COL snap_id_to NEW_V snap_id_to;
SELECT NVL(MIN(snap_id),1) snap_id_from FROM dba_hist_snapshot WHERE dbid = &&this_dbid. AND TO_DATE('&&date_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') BETWEEN begin_interval_time AND end_interval_time;
SELECT NVL(MAX(snap_id),1e9) snap_id_to FROM dba_hist_snapshot WHERE dbid = &&this_dbid. AND TO_DATE('&&date_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS') BETWEEN begin_interval_time AND end_interval_time;

SPO sql_locking_awr_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO DATE_TIME_FROM: &&date_time_from.
PRO DATE_TIME_TO: &&date_time_to.

PRO
PRO SQL statements from sessions waiting on locks between &&date_time_from. and &&date_time_to.. Most recent first.
PRO

SELECT h.instance_number inst,
       h.snap_id snap,
       TO_CHAR(s.end_interval_time, 'YYYY-MM-DD"T"HH24:MI:SS') end_time,
       COUNT(*) samples_count,
       ROUND((10 * COUNT(*)) / (24 * 60 * 60 * (CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE))), 1) average_active_sessions,
       COUNT(DISTINCT h.session_id||','||h.session_serial#) waiting_sessions_count,
       COUNT(DISTINCT h.blocking_session||','||h.blocking_session_serial#) blocking_sessions_count,
       h.sql_id,
       h.con_id container_id,       
       h.current_obj# object_number,
       CASE 
         WHEN o.object_id = 0 THEN 'UNDO'
         WHEN o.object_id > 0 THEN o.owner||'.'||o.object_name||'('||o.object_type||')' 
       END object_owner_and_name,
       (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sql q WHERE q.sql_id = h.sql_id AND q.con_id = h.con_id AND ROWNUM = 1) sql_text_100_only
  FROM dba_hist_snapshot s,
       dba_hist_active_sess_history h,
       cdb_objects o
 WHERE s.dbid = &&this_dbid.
   AND s.snap_id BETWEEN &&snap_id_from. AND &&snap_id_to.
   -- outer join (+) into dba_hist_active_sess_history is just for performance
   AND h.snap_id(+) = s.snap_id
   AND h.dbid(+) = s.dbid
   AND h.instance_number(+) = s.instance_number
   AND h.session_state(+) = 'WAITING'
   AND h.blocking_session_status(+) = 'VALID'
   AND h.sql_id(+) > '0'
   AND h.con_id(+) > 2
   AND h.current_obj#(+) > -1
   AND h.sample_time(+) BETWEEN TO_DATE('&&date_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&date_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND h.user_id(+) > 0 -- excludes sys
   -- outer join (+) into cdb_objects is because we could have a dropped object
   AND o.object_id(+) = h.current_obj#
   AND o.con_id(+) = h.con_id
 GROUP BY
       h.snap_id,
       h.dbid,
       h.instance_number,
       s.begin_interval_time,
       s.end_interval_time,
       h.sql_id,
       h.con_id,
       h.current_obj#,
       o.object_id,
       o.owner,
       o.object_name,
       o.object_type
HAVING h.con_id > 2
 ORDER BY
       h.instance_number,
       h.snap_id DESC,
       s.end_interval_time DESC,
       samples_count DESC,
       waiting_sessions_count DESC,
       blocking_sessions_count DESC,
       h.sql_id,
       h.con_id,
       h.current_obj#,
       o.object_id,
       o.owner,
       o.object_name,
       o.object_type
/

PRO
PRO **********************************************************************************************************************************
PRO
PRO SQL statements from sessions blocking other sessions between &&date_time_from. and &&date_time_to.. Most recent first.
PRO

WITH
waiting AS (
SELECT h.snap_id,
       h.dbid,
       h.instance_number,
       h.session_id,
       h.session_serial#,
       h.blocking_session,
       h.blocking_session_serial#,
       --h.blocking_inst_id,
       h.con_id,
       h.current_obj#,
       o.object_id,
       o.owner,
       o.object_name,
       o.object_type,
       h.sample_id,
       h.sample_time,
       s.begin_interval_time,
       s.end_interval_time,
       COUNT(*) waiting_samples
  FROM dba_hist_snapshot s,
       dba_hist_active_sess_history h,
       cdb_objects o
 WHERE s.dbid = &&this_dbid.
   AND s.snap_id BETWEEN &&snap_id_from. AND &&snap_id_to.
   -- outer join (+) into dba_hist_active_sess_history is just for performance
   AND h.snap_id(+) = s.snap_id
   AND h.dbid(+) = s.dbid
   AND h.instance_number(+) = s.instance_number
   AND h.session_state(+) = 'WAITING'
   AND h.blocking_session_status(+) = 'VALID'
   AND h.sql_id(+) > '0'
   AND h.con_id(+) > 2
   AND h.current_obj#(+) > -1
   AND h.sample_time(+) BETWEEN TO_DATE('&&date_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&date_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND h.user_id(+) > 0 -- excludes sys
   -- outer join (+) into cdb_objects is because we could have a dropped object
   AND o.object_id(+) = h.current_obj#
   AND o.con_id(+) = h.con_id
 GROUP BY
       h.snap_id,
       h.dbid,
       h.instance_number,
       h.session_id,
       h.session_serial#,
       h.blocking_session,
       h.blocking_session_serial#,
       --h.blocking_inst_id,
       h.con_id,
       h.current_obj#,
       o.object_id,
       o.owner,
       o.object_name,
       o.object_type,
       h.sample_id,
       h.sample_time,
       s.begin_interval_time,
       s.end_interval_time
)
SELECT w.instance_number inst,
       w.snap_id snap,
       TO_CHAR(w.end_interval_time, 'YYYY-MM-DD"T"HH24:MI:SS') end_time,
       COUNT(*) samples_count,
       ROUND((10 * COUNT(*)) / (24 * 60 * 60 * (CAST(w.end_interval_time AS DATE) - CAST(w.begin_interval_time AS DATE))), 1) average_active_sessions,
       COUNT(DISTINCT w.session_id||','||w.session_serial#) waiting_sessions_count,
       COUNT(DISTINCT w.blocking_session||','||w.blocking_session_serial#) blocking_sessions_count,
       CASE WHEN h.sql_id IS NULL THEN w.blocking_session||','||w.blocking_session_serial# END missing_session_serial,
       h.sql_id,
       w.con_id container_id,       
       w.current_obj# object_number,
       CASE 
         WHEN w.object_id = 0 THEN 'UNDO'
         WHEN w.object_id > 0 THEN w.owner||'.'||w.object_name||'('||w.object_type||')' 
       END object_owner_and_name,
       (SELECT SUBSTR(q.sql_text, 1, 100) FROM v$sql q WHERE q.sql_id = h.sql_id AND q.con_id = w.con_id AND ROWNUM = 1) sql_text_100_only
  FROM waiting w,
       dba_hist_active_sess_history h
 WHERE h.snap_id(+) = w.snap_id 
   AND h.dbid(+) = w.dbid 
   AND h.instance_number(+) = w.instance_number -- non RAC
   AND h.session_id(+) = w.blocking_session -- missing session?
   AND h.session_serial#(+) = w.blocking_session_serial# -- missing session?
   AND h.con_id(+) = w.con_id
   AND h.sample_id(+) = w.sample_id -- non RAC
   AND h.sample_time(+) = w.sample_time -- non RAC
   AND h.dbid(+) = &&this_dbid.
   AND h.snap_id(+) BETWEEN &&snap_id_from. AND &&snap_id_to.
   AND h.sample_time(+) BETWEEN TO_DATE('&&date_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&date_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND h.user_id(+) > 0 -- excludes sys
 GROUP BY
       w.snap_id,
       w.dbid,
       w.instance_number,
       w.begin_interval_time,
       w.end_interval_time,
       CASE WHEN h.sql_id IS NULL THEN w.blocking_session||','||w.blocking_session_serial# END,
       h.sql_id,
       w.con_id,
       w.current_obj#,
       w.object_id,
       w.owner,
       w.object_name,
       w.object_type
HAVING w.con_id > 2
 ORDER BY
       w.instance_number,
       w.snap_id DESC,
       w.end_interval_time DESC,
       samples_count DESC,
       waiting_sessions_count DESC,
       blocking_sessions_count DESC,
       missing_session_serial,
       h.sql_id,
       w.con_id,
       w.current_obj#,
       w.object_id,
       w.owner,
       w.object_name,
       w.object_type
/

PRO
PRO Investigate blockers further using SQLd360, else planx.sql, else sqlperf.sql.
PRO 

SPO OFF;
UNDEF date_time_from, date_time_to;
CL BREAK;
