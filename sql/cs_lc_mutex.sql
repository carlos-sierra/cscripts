SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
COL cnt FOR 999999;
COL type FOR A30 TRUNC;
COL owner FOR A30 TRUNC;
COL name FOR A30 TRUNC;
SELECT COUNT(*) AS cnt, c.type, c.owner, c.name
  FROM v$session s,
       v$db_object_cache c
 WHERE s.event = 'library cache: mutex X'
   AND c.hash_value = s.p1
 GROUP BY
       c.type, c.owner, c.name
 ORDER BY 1 DESC
/
