SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
COL pdb_name FOR A30;
WITH details AS (
SELECT (SELECT c.name FROM v$containers c WHERE c.con_id = cach.con_id AND ROWNUM = 1) AS pdb_name, 
       cach.sid, cach.value cache_hits, prs.value all_parses -- , round((cach.value/prs.value)*100,2) as "% found in cache"
  FROM v$sesstat cach, v$sesstat prs, v$statname nm1, v$statname nm2
 WHERE cach.statistic# = nm1.statistic#
   AND nm1.name = 'session cursor cache hits'
   AND prs.statistic#=nm2.statistic#
   AND nm2.name= 'parse count (total)'
   AND prs.sid= cach.sid
   AND prs.con_id = cach.con_id
   AND prs.value > cach.value
   AND prs.value > 10000
   AND cach.con_id > 2
)
SELECT pdb_name, ROUND(100*SUM(cache_hits)/SUM(all_parses)) AS "Cache Hit %", COUNT(*) AS sessions
  FROM details
 WHERE pdb_name IS NOT NULL
 GROUP BY pdb_name
 ORDER BY
       2,1
/