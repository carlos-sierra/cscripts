-- open_cursor.sql - Open Cursors and Count of Distinct SQL_ID per Session
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL module FOR A32 TRUNC;
COL sid_serial FOR A15 TRUNC;
COL cursors FOR 999,990;
COL sql_ids FOR 999,990;
--
WITH
  c AS (SELECT /*+ MATERIALIZE NO_MERGE */ * FROM v$open_cursor)
, s AS (SELECT /*+ MATERIALIZE NO_MERGE */ * FROM v$session)
SELECT s.module,
       s.machine,
       s.sid||','||s.serial# AS sid_serial,
       COUNT(*) AS cursors,
       COUNT(DISTINCT c.sql_id) AS sql_ids
  FROM c,
       s
 WHERE s.saddr = c.saddr
   AND s.sid = c.sid
 GROUP BY
       s.module,
       s.machine,
       s.sid,
       s.serial#
 ORDER BY
       s.module,
       s.machine,
       s.sid,
       s.serial#
/
