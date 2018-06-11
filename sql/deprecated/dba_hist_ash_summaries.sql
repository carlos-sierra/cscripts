----------------------------------------------------------------------------------------
--
-- File name:   dba_hist_ash_summaries.sql
--
-- Purpose:     ASH summaries by timed events then by plan operation
--
-- Author:      Carlos Sierra
--
-- Version:     2013/12/19
--
-- Usage:       This script presents several summaries of historical ASH data in order
--              to provide a general view of how the DB time is consumed.
--
-- Example:     @dba_hist_ash_summaries.sql
--
--  Notes:      Developed and tested on 11.2.0.3 
--             
---------------------------------------------------------------------------------------
--
SPO dba_hist_ash_summaries.txt;
SET ECHO OFF VER OFF NEWP NONE PAGES 50 LINES 32767 TRIMS ON;

COL total_samples NEW_V total_samples FOR 999,999,999,999,999;
SELECT COUNT(*) total_samples
  FROM dba_hist_active_sess_history;

PRO
PRO DBA_HIST_ACTIVE_SESS_HISTORY (rollup by session_state, wait_class and event)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET PAGES 50000;
COL samples FOR 999,999,999,999,999;
COL percent FOR A10;
COL state FOR A7;
COL wait_class FOR A14;
COL event FOR A70;
COL total FOR A17;
SELECT --GROUPING(session_state), GROUPING(wait_class), GROUPING(event),
       COUNT(*) samples,
       TO_CHAR(ROUND(COUNT(*) * 100 / &&total_samples., 1), '9,990.0')||' %' percent,
       CASE 
       WHEN GROUPING(session_state) = 1 THEN 'Total'
       WHEN GROUPING(wait_class) = 1 THEN '  Sub Total'
       WHEN GROUPING(event) = 1 THEN '    Sub Sub Total'
       END total,
       session_state state, wait_class, event
  FROM dba_hist_active_sess_history
 GROUP BY
       ROLLUP(session_state, wait_class, event)
HAVING COUNT(*) * 100 / &&total_samples. > 0.05
   AND (session_state = 'WAITING' OR GROUPING(wait_class) = 1);

PRO
PRO DBA_HIST_ACTIVE_SESS_HISTORY (group by operation)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET PAGES 50;
COL operation FOR A40;
SELECT COUNT(*) samples,
       TO_CHAR(ROUND(COUNT(*) * 100 / &&total_samples., 1), '9,990.0')||' %' percent,
       SUBSTR(sql_plan_operation||' '||sql_plan_options, 1, 40) operation
  FROM dba_hist_active_sess_history
 WHERE sql_plan_operation IS NOT NULL
 GROUP BY
       sql_plan_operation,
       sql_plan_options
HAVING COUNT(*) * 100 / &&total_samples. > 0.05
 ORDER BY
       sql_plan_operation,
       sql_plan_options;

PRO
PRO DBA_HIST_ACTIVE_SESS_HISTORY (group by operation and session_state)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COL session_state FOR A13;
SELECT COUNT(*) samples,
       TO_CHAR(ROUND(COUNT(*) * 100 / &&total_samples., 1), '9,990.0')||' %' percent,
       SUBSTR(sql_plan_operation||' '||sql_plan_options, 1, 40) operation,
       session_state
  FROM dba_hist_active_sess_history
 WHERE sql_plan_operation IS NOT NULL
 GROUP BY
       sql_plan_operation,
       sql_plan_options,
       session_state 
HAVING COUNT(*) * 100 / &&total_samples. > 0.05
 ORDER BY
       sql_plan_operation,
       sql_plan_options,
       session_state;

PRO
PRO DBA_HIST_ACTIVE_SESS_HISTORY (group by operation, session_state and wait_class)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COL wait_class FOR A24;
SELECT COUNT(*) samples,
       TO_CHAR(ROUND(COUNT(*) * 100 / &&total_samples., 1), '9,990.0')||' %' percent,
       SUBSTR(sql_plan_operation||' '||sql_plan_options, 1, 40) operation,
       session_state||' '||wait_class wait_class
  FROM dba_hist_active_sess_history
 WHERE sql_plan_operation IS NOT NULL
 GROUP BY
       sql_plan_operation,
       sql_plan_options,
       session_state, 
       wait_class
HAVING COUNT(*) * 100 / &&total_samples. > 0.05
 ORDER BY
       sql_plan_operation,
       sql_plan_options,
       session_state, 
       wait_class;

PRO
PRO DBA_HIST_ACTIVE_SESS_HISTORY (group by operation, session_state, wait_class and event)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COL event FOR A70;
SELECT COUNT(*) samples,       
       TO_CHAR(ROUND(COUNT(*) * 100 / &&total_samples., 1), '9,990.0')||' %' percent,
       SUBSTR(sql_plan_operation||' '||sql_plan_options, 1, 40) operation,
       session_state||' '||wait_class||' '||
       CASE WHEN event IS NOT NULL THEN '"'||event||'"' END event
  FROM dba_hist_active_sess_history
 WHERE sql_plan_operation IS NOT NULL
 GROUP BY
       sql_plan_operation,
       sql_plan_options,
       session_state, 
       wait_class, 
       event
HAVING COUNT(*) * 100 / &&total_samples. > 0.05
 ORDER BY
       sql_plan_operation,
       sql_plan_options,
       session_state, 
       wait_class, 
       event;

PRO
PRO DBA_HIST_ACTIVE_SESS_HISTORY I/O waits (group by operation, wait_class, event and obj#)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COL object_name FOR A30;
SELECT COUNT(*) samples,
       TO_CHAR(ROUND(COUNT(*) * 100 / &&total_samples., 1), '9,990.0')||' %' percent,
       SUBSTR(sql_plan_operation||' '||sql_plan_options, 1, 40) operation,
       SUBSTR(wait_class||' '||
       CASE WHEN event IS NOT NULL THEN '"'||event||'"' END, 1, 60) event,
       current_obj#,
       (SELECT object_name FROM dba_objects WHERE data_object_id = current_obj# AND ROWNUM = 1) object_name
  FROM dba_hist_active_sess_history
 WHERE sql_plan_operation IS NOT NULL
   AND session_state = 'WAITING'
   AND wait_class IN ('Application', 'Cluster', 'Concurrency', 'User I/O')
   AND current_obj# IS NOT NULL
 GROUP BY
       sql_plan_operation,
       sql_plan_options,
       wait_class, 
       event,
       current_obj#
HAVING COUNT(*) * 100 / &&total_samples. > 0.05
 ORDER BY
       sql_plan_operation,
       sql_plan_options,
       wait_class, 
       event,
       current_obj#;

SET NEWP 1 PAGES 14 LINES 80 TRIMS OFF;
SPO OFF;

