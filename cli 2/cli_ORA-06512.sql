
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
   -- in old data model plan rows were on sqlobj$data.comp_data while on new data model they must be on sqlobj$plan
   AND NOT EXISTS (SELECT NULL FROM sys.sqlobj$plan p
                    WHERE p.signature = o.signature
                      AND p.obj_type = o.obj_type
                      AND p.plan_id = o.plan_id)
/