----------------------------------------------------------------------------------------
--
-- File name:   cs_ash.sql
--
-- Purpose:     High-level view of Current Load at an Instance level based on ASH
--
-- Author:      Carlos Sierra
--
-- Version:     2019/09/11
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_ash.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2. Should also run on 11g.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL timed_event FOR A50 TRUNC;
COL percent FOR 990.0;
COL sql_text FOR A100 TRUNC;
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF percent ON REPORT;
--
PRO
PRO Database Time (per TIMED_EVENT)
PRO ~~~~~~~~~~~~~
SELECT ROUND(100 * COUNT(*) / (SUM(COUNT(*)) OVER()), 1) AS percent,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END AS timed_event
  FROM v$active_session_history h
 GROUP BY
       h.session_state,
       h.wait_class,
       h.event
 ORDER BY
       1 DESC,
       2
 FETCH FIRST 10 ROWS ONLY
/
PRO
PRO Database Time (per SQL_ID and TIMED_EVENT)
PRO ~~~~~~~~~~~~~
SELECT ROUND(100 * COUNT(*) / (SUM(COUNT(*)) OVER()), 1) AS percent,
       h.sql_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END AS timed_event,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = h.sql_id AND ROWNUM = 1) AS sql_text
  FROM v$active_session_history h
 GROUP BY
       h.sql_id,
       h.session_state,
       h.wait_class,
       h.event
 ORDER BY
       1 DESC,
       2
 FETCH FIRST 10 ROWS ONLY
/
--
PRO
PRO Max Concurrent Active Sessions (per SQL_ID)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
by_sample AS (
SELECT h.sql_id,
       h.sample_time,
       COUNT(*) AS sessions,
       ROW_NUMBER() OVER (PARTITION BY h.sql_id ORDER BY COUNT(*) DESC, h.sample_time) AS rn
  FROM v$active_session_history h
 WHERE h.sql_id IS NOT NULL
 GROUP BY
       h.sql_id,
       h.sample_time
)
SELECT h.sessions,
       CAST(h.sample_time AS DATE) AS sample_time,
       h.sql_id,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = h.sql_id AND ROWNUM = 1) AS sql_text
  FROM by_sample h
 WHERE h.rn = 1
 ORDER BY
       1 DESC,
       2
 FETCH FIRST 10 ROWS ONLY
/
--
PRO
PRO Max Concurrent Active Sessions (per SQL_ID and TIMED_EVENT)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
by_sample AS (
SELECT h.sql_id,
       CASE h.session_state WHEN 'ON CPU' THEN h.session_state ELSE h.wait_class||' - '||h.event END AS timed_event,
       h.sample_time,
       COUNT(*) AS sessions,
       ROW_NUMBER() OVER (PARTITION BY h.sql_id, h.session_state, h.wait_class, h.event ORDER BY COUNT(*) DESC, h.sample_time) AS rn
  FROM v$active_session_history h
 WHERE h.sql_id IS NOT NULL
 GROUP BY
       h.sql_id,
       h.session_state,
       h.wait_class,
       h.event,
       h.sample_time
)
SELECT h.sessions,
       CAST(h.sample_time AS DATE) AS sample_time,
       h.sql_id,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = h.sql_id AND ROWNUM = 1) AS sql_text,
       timed_event
  FROM by_sample h
 WHERE h.rn = 1
 ORDER BY
       1 DESC,
       2
 FETCH FIRST 10 ROWS ONLY
/
--