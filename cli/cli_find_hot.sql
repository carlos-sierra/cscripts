SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
COL name FOR A80 TRUNC;
COL property FOR A10;
COL con_id FOR 999999;
SELECT DISTINCT con_id, full_hash_value, property, name
  FROM v$db_object_cache
 WHERE namespace = 'SQL AREA'
   AND type = 'CURSOR'
   AND status = 'VALID'
   AND property IS NOT NULL
 ORDER BY
       con_id, full_hash_value, property, name
/
