
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF6';
--
SELECT p.signature, o.name, DECODE(BITAND(o.flags, 1), 0, 'NO', 'YES') AS enabled, DECODE(BITAND(o.flags, 2), 0, 'NO', 'YES') AS accepted, d.created, d.last_modified, o.last_executed, d.last_verified, d.description
  FROM sys.sqlobj$plan p,
       sys.sqlobj$ o,
       sys.sqlobj$auxdata d
 WHERE p.obj_type = 2 
   --AND p.id = 1 
   AND p.other_xml IS NOT NULL 
   -- plan_hash_2 is like plan_hash_value, but ignoring transient object names, and it must be same than plan_id (else potential ORA-13831)
   AND p.plan_id <> NVL(TO_NUMBER(REGEXP_SUBSTR(p.other_xml, '[^\<]*', REGEXP_INSTR(p.other_xml, '"plan_hash_2">', 1, 1, 1))), -666)
   AND o.signature = p.signature
   AND o.category = p.category
   AND o.obj_type = p.obj_type
   AND o.plan_id = p.plan_id
   AND d.signature = p.signature
   AND d.category = p.category
   AND d.obj_type = p.obj_type
   AND d.plan_id = p.plan_id
/