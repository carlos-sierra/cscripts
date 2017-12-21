----------------------------------------------------------------------------------------
--
-- File name:   sql_locking_ses.sql
--
-- Purpose:     List SQL_IDs of sessions waiting on a LOCK from other sessions. 
--              And list of SQL_IDs from sessions blocking others with a LOCK.
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
--              This script iterates 100x over v$session in order to capture short-lived
--              waits, together with their blocker.
--              
--              To investigate locks that happened more than 3 hours ago use:
--                sql_locking_awr.sql.
--              To investigate locks that happened within the last 3 hours use:
--                sql_locking_ash.sql.
--              To investigate locks that are happening now use:
--                sql_locking_ses.sql.
--              
--              Execute connected into the CDB, or PDB of interest.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sql_locking_ses.sql
--
-- Notes:       Use together with sql_regression.sql    .          
--
--              Developed and tested on 12.1.0.2.
--
--              To further dive into SQL performance diagnostics use SQLd360.
--             
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL container_id FOR 999999 HEA 'CON_ID';
COL object_number FOR 999999999 HEA 'Object ID';
COL object_owner_and_name FOR A60 HEA 'Object Owner.Name(Type)';
COL sql_text_100_only FOR A101 HEA 'SQL Text';
COL waiter_or_blocker FOR A7 HEA 'Type';
COL wb_session_serial FOR A16 HEA 'Session,Serial';
COL wb_spid FOR A6 HEA 'SPID';
COL wb_sql_id FOR A17 HEA 'SQL_ID';
COL wb_con_id FOR A6 HEA 'CON_ID';

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

SPO sql_locking_ses_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.

PRO
PRO SQL statements (C)urrent or (P)revious from sessions waiting on locks held by other sessions (blockers).
PRO
  
SELECT 'Wait:'||CHR(10)||'Block:' waiter_or_blocker,
       w.sid||','||w.serial#||CHR(10)||
       w.blocking_session||','||b.serial# wb_session_serial,
       wp.spid||CHR(10)||bp.spid wb_spid,
       CASE WHEN w.sql_id IS NULL THEN w.prev_sql_id||'(P)' ELSE w.sql_id||'(C)' END||CHR(10)||
       CASE WHEN b.sql_id IS NULL THEN b.prev_sql_id||'(P)' ELSE b.sql_id||'(C)' END wb_sql_id,
       w.con_id||CHR(10)||b.con_id wb_con_id,
       w.row_wait_obj# object_number,
       CASE 
         WHEN o.object_id = 0 THEN 'UNDO'
         WHEN o.object_id > 0 THEN o.owner||'.'||o.object_name||'('||o.object_type||')' 
       END object_owner_and_name,
       (SELECT SUBSTR(q1.sql_text, 1, 100) FROM v$sql q1 WHERE q1.sql_id = NVL(w.sql_id, w.prev_sql_id) AND q1.con_id = w.con_id AND ROWNUM = 1)||CHR(10)||
       (SELECT SUBSTR(q2.sql_text, 1, 100) FROM v$sql q2 WHERE q2.sql_id = NVL(b.sql_id, b.prev_sql_id) AND q2.con_id = b.con_id AND ROWNUM = 1) sql_text_100_only
  FROM v$session w,
       v$session b,
       v$process wp,
       v$process bp,
       cdb_objects o
 WHERE w.state = 'WAITING'
   AND w.blocking_session_status = 'VALID'
   AND NVL(w.sql_id, w.prev_sql_id) IS NOT NULL
   AND w.con_id > 2
   AND w.row_wait_obj# > -1
   AND w.user# > 0 -- excludes sys
   -- blocking session should be there, but if not still display waiter
   AND b.sid(+) = w.blocking_session
   AND b.con_id(+) = w.con_id
   --AND b.user#(+) > 0 -- excludes sys
   -- waiting process
   AND wp.addr = w.paddr
   -- blocker process
   AND bp.addr = b.paddr
   -- object should be there, but if not still display waiter
   AND o.object_id(+) = w.row_wait_obj#
   AND o.con_id(+) = w.con_id
 ORDER BY
       w.blocking_session,
       b.serial# NULLS FIRST,
       w.sid,
       w.serial#
-- first 25 out of 200
/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

-- next 25 out of 200
/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

-- next 25 out of 200
/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

-- last 25 out of first 100
/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

-- next 25 out of 200
/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

-- next 25 out of 200
/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

-- next 25 out of 200
/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

-- last 25 out of 200
/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

/
/
/
/
/

PRO
PRO Investigate blockers further using SQLd360, else planx.sql, else sqlperf.sql.
PRO 

SPO OFF;

