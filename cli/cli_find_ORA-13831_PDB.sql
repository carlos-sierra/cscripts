SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SELECT p.signature,
       t.sql_handle,
       o.name plan_name,
       p.plan_id,
       CASE WHEN p.other_xml IS NOT NULL THEN TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) END plan_hash_2,
       a.description
  FROM sys.sqlobj$plan p,
       sys.sqlobj$ o,
       sys.sqlobj$auxdata a,
       sys.sql$text t
 WHERE p.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
   AND p.id = 1
   AND p.other_xml IS NOT NULL
   -- phv2 is a plan_hash_value ignoring transient object names (must be same than plan_id for a baseline to be used)
   AND p.plan_id <> CASE WHEN p.other_xml IS NOT NULL THEN TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) END
   AND o.obj_type = 2  /* 1=profile, 2=baseline, 3=patch */
   AND o.signature = p.signature
   AND o.plan_id = p.plan_id
   --AND BITAND(o.flags, 1) = 1 /* enabled */
   AND a.obj_type = o.obj_type
   AND a.signature = p.signature
   AND a.plan_id = p.plan_id
   AND a.parsing_schema_name NOT IN ('SYS', 'C##IOD')
   AND t.signature = p.signature
 ORDER BY
       t.sql_handle,
       o.name
/
