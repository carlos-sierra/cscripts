SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL pdb_name FOR A30 TRUNC;
COL sql_text FOR A100 TRUNC;
--
SELECT c.name AS pdb_name, s.sql_text
  FROM v$sqlstats s, v$containers c
 WHERE s.sql_text LIKE 'select dbms_service_prvt.get_topology%'
   AND c.con_id = s.con_id
 GROUP BY
       c.name, s.sql_text
 ORDER BY
       c.name, s.sql_text       
/
--
SELECT c.name AS pdb_name, COUNT(*) AS ash_samples
  FROM v$active_session_history h, v$containers c
 WHERE c.con_id = h.con_id
   AND (h.con_id, h.sql_id) IN (
SELECT s.con_id, s.sql_id
  FROM v$sqlstats s
 WHERE s.sql_text LIKE 'select dbms_service_prvt.get_topology%'
 )
 GROUP BY
       c.name
 ORDER BY
       c.name
/  
