SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET PAGES 1000;
--
DEF days = '60';
DEF height = '36';
--
DEF sql_id = '3hahc9c3zmc6d';
DEF sql_id = '';
--
-- [WAITING|ON CPU]
DEF session_state = 'ON CPU';
DEF session_state = 'WAITING';
--
-- [Application|Commit|Concurrency|Configuration|Network|Other|Scheduler|System I/O|User I/O]
DEF wait_class = 'Other';
DEF event = 'flashback log switch';
--
DEF wait_class = 'Concurrency';
DEF event = 'library cache';
--
COL pdb_name FOR A30;
COL date_hour NOPRI;
COL date_time FOR A19;
COL aas FOR 99,999;
COL top FOR 999;
COL sql_text FOR A60 TRUNC;
COL machines FOR 999,990;
--BREAK ON date_hour SKIP 1 DUP;
--
WITH
over_height AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.con_id, h.sql_id,
       h.sample_time,
       COUNT(*) AS aas,
       COUNT(DISTINCT machine) AS machines,
       (CAST(h.sample_time AS DATE) - LAG(CAST(h.sample_time AS DATE)) OVER (ORDER BY h.sample_time)) * 24 * 3600 AS secs_from_prior
  FROM dba_hist_active_sess_history h
 WHERE 1 = 1
   AND h.session_state = '&&session_state.' 
   AND h.wait_class = '&&wait_class.' 
   AND h.event LIKE '%&&event.%'
   AND h.con_id >= 0 
   AND h.sql_id IS NOT NULL
  --  AND h.sql_id = '&&sql_id.'
   --AND (h.session_state = '&&session_state.' OR '&&session_state.' IS NULL)
   --AND (h.wait_class = '&&wait_class.' OR '&&wait_class.' IS NULL)
   --AND (h.session_state = 'ON CPU' OR h.wait_class = 'Scheduler') -- CPU Demand
   --AND h.sample_time > SYSDATE - &&days.
 GROUP BY
       h.con_id, h.sql_id,
       h.sample_time
HAVING COUNT(*) > &&height.
)
SELECT --TO_CHAR(h.sample_time, 'YYYY-MM-DD"T"HH24') AS date_hour,
       TO_CHAR(h.sample_time, 'YYYY-MM-DD"T"HH24:MI:SS') AS date_time,
       h.aas,
       c.name AS pdb_name,
       h.machines,
       h.sql_id,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = h.sql_id AND ROWNUM = 1) AS sql_text
  FROM over_height h, v$containers c
  WHERE c.con_id = h.con_id
 ORDER BY
       h.sample_time
/
--
--CLEAR BREAK COLUMNS;
--
