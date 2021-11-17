SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET PAGES 300;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
COL con_id FOR 999990;
COL pdb_name FOR A30;
COL tables FOR 99,990;
COL days1 FOR 990.0;
COL days2 FOR 990.0;
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       '|' AS "|",
       t.con_id,
       c.name AS pdb_name,
       MAX(t.last_analyzed) AS last_analyzed,
       SYSDATE - MAX(t.last_analyzed) AS days1,
       PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY t.last_analyzed ASC) AS p90th,
       SYSDATE - PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY t.last_analyzed ASC) AS days2,
       COUNT(*) AS tables
  FROM cdb_tables t, cdb_users u, v$containers c
 WHERE t.con_id <> 2
   AND u.con_id = t.con_id
   AND u.username = t.owner
   AND u.oracle_maintained = 'N'
   AND u.common = 'NO'
   AND c.con_id = t.con_id
 GROUP BY
       t.con_id, c.name
 ORDER BY
       t.con_id, c.name
/