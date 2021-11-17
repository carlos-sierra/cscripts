
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF6';
--
SELECT o.signature, o.name, DECODE(BITAND(o.flags, 1), 0, 'NO', 'YES') AS enabled, DECODE(BITAND(o.flags, 2), 0, 'NO', 'YES') AS accepted, d.created, d.last_modified, o.last_executed, d.last_verified, d.description
  FROM sys.sqlobj$ o,
       sys.sqlobj$auxdata d
 WHERE o.obj_type = 2 
   AND d.signature = o.signature
   AND d.category = o.category
   AND d.obj_type = o.obj_type
   AND d.plan_id = o.plan_id
   AND d.created < SYSDATE - 119
   AND (d.last_modified < SYSDATE - 119 OR d.last_modified IS NULL)
   AND (o.last_executed < SYSDATE - 119 OR o.last_executed IS NULL)
   AND (d.last_verified < SYSDATE - 119 OR d.last_verified IS NULL)
/