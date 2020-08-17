SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET SERVEROUT ON;
ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER SESSION SET "_px_cdb_view_enabled" = FALSE;
--
COL pdb_name FOR A30 TRUNC;
COL window_name FOR A20 TRUNC;
COL resource_plan FOR A30 TRUNC;
COL enabled FOR A7 TRUNC;
COL duration FOR A14 TRUNC;
COL repeat_interval FOR A80 TRUNC;
COL next_start_date FOR A40 TRUNC;
--
BREAK ON pdb_name SKIP PAGE DUPL;
--
SELECT c.name AS pdb_name, 
       w.window_name,
       w.resource_plan,
       w.enabled,
       w.duration,
       w.repeat_interval,
       w.next_start_date
  FROM cdb_scheduler_windows w, 
       v$containers c
 WHERE c.con_id = w.con_id
 ORDER BY
       c.name,
       w.window_name
/
--
CLEAR BREAK;