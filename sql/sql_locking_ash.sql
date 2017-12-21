----------------------------------------------------------------------------------------
--
-- File name:   sql_locking_ash.sql
--
-- Purpose:     For last few minutes, list SQL_IDs of sessions waiting on a LOCK from
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
--              This script uses ASH in memory, which is usually available only for a few
--              hours. Granularity of samples is by default 1 second.
--              
--              To investigate locks that happened more than 3 hours ago use:
--                sql_locking_awr.sql.
--              To investigate locks that happened within the last 3 hours use:
--                sql_locking_ash.sql.
--              To investigate locks that are happening now use:
--                sql_locking_ses.sql.
--              
--              Pass value (when asked) for last few minutes of ASH from memory.
--              Default value is: most recent 15 minutes of ASH from memory.
--              Maximum value is 180 minutes. 
--
--              Execute connected into the CDB, or PDB of interest.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sql_locking_ash.sql
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
ACC minutes_of_history PROMPT 'Minutes of ASH history to consider (default 15, max 180): ';

SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL samples_count FOR 9999999 HEA 'ASH|Samples';
COL waiting_sessions_count FOR 99999999 HEA 'Waiting|Sessions';
COL blocking_sessions_count FOR 99999999 HEA 'Blocking|Sessions';
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
COL minutes_of_history NEW_V minutes_of_history;
SELECT NVL('&&minutes_of_history.','15') minutes_of_history FROM DUAL;
COL date_time_from NEW_V date_time_from;
COL date_time_to NEW_V date_time_to;
SELECT TO_CHAR(SYSDATE - (&&minutes_of_history. / 60 / 24), 'YYYY-MM-DD"T"HH24:MI:SS') date_time_from, TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS') date_time_to FROM DUAL;
COL this_dbid NEW_V this_dbid;
SELECT dbid this_dbid FROM v$database;

SPO sql_locking_ash_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO HISTORY: &&minutes_of_history. minutes
PRO DATE_TIME_FROM: &&date_time_from.
PRO DATE_TIME_TO: &&date_time_to.

PRO
PRO SQL statements from sessions waiting on locks between &&date_time_from. and &&date_time_to..
PRO

SELECT COUNT(*) samples_count,
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
  FROM v$active_session_history h,
       cdb_objects o
 WHERE h.session_state = 'WAITING'
   AND h.blocking_session_status = 'VALID'
   AND h.sql_id > '0'
   AND h.con_id > 2
   AND h.current_obj# > -1
   AND h.sample_time BETWEEN TO_DATE('&&date_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&date_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND h.user_id > 0 -- excludes sys
   -- outer join (+) into cdb_objects is because we could have a dropped object
   AND o.object_id(+) = h.current_obj#
   AND o.con_id(+) = h.con_id
 GROUP BY
       h.sql_id,
       h.con_id,
       h.current_obj#,
       o.object_id,
       o.owner,
       o.object_name,
       o.object_type
 ORDER BY
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
PRO SQL statements from sessions blocking other sessions between &&date_time_from. and &&date_time_to..
PRO

WITH
waiting AS (
SELECT h.session_id,
       h.session_serial#,
       h.blocking_session,
       h.blocking_session_serial#,
       h.con_id,       
       h.current_obj#,
       o.object_id,
       o.owner,
       o.object_name,
       o.object_type,
       h.sample_id,
       h.sample_time,
       COUNT(*) waiting_samples
  FROM v$active_session_history h,
       cdb_objects o
 WHERE h.session_state = 'WAITING'
   AND h.blocking_session_status = 'VALID'
   AND h.sql_id > '0'
   AND h.con_id > 2
   AND h.current_obj# > -1
   AND h.sample_time BETWEEN TO_DATE('&&date_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&date_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND h.user_id > 0 -- excludes sys
   -- outer join (+) into cdb_objects is because we could have a dropped object
   AND o.object_id(+) = h.current_obj#
   AND o.con_id(+) = h.con_id
 GROUP BY
       h.session_id,
       h.session_serial#,
       h.blocking_session,
       h.blocking_session_serial#,
       h.con_id,
       h.current_obj#,
       o.object_id,
       o.owner,
       o.object_name,
       o.object_type,
       h.sample_id,
       h.sample_time
)
SELECT COUNT(*) samples_count,
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
       v$active_session_history h
 WHERE h.session_id(+) = w.blocking_session -- missing session?
   AND h.session_serial#(+) = w.blocking_session_serial# -- missing session?
   AND h.con_id(+) = w.con_id
   AND h.sample_id(+) = w.sample_id -- non RAC
   AND h.sample_time(+) = w.sample_time -- non RAC
   AND h.sample_time(+) BETWEEN TO_DATE('&&date_time_from.', 'YYYY-MM-DD"T"HH24:MI:SS') AND TO_DATE('&&date_time_to.', 'YYYY-MM-DD"T"HH24:MI:SS')
   AND h.user_id(+) > 0 -- excludes sys
 GROUP BY
       CASE WHEN h.sql_id IS NULL THEN w.blocking_session||','||w.blocking_session_serial# END,
       h.sql_id,
       w.con_id,
       w.current_obj#,
       w.object_id,
       w.owner,
       w.object_name,
       w.object_type
 ORDER BY
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
UNDEF minutes_of_history, date_time_from, date_time_to;

