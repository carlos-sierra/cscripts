
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SELECT o.signature,
       t.sql_handle,
       o.name plan_name,
       a.description
  FROM sys.sqlobj$ o,
       sys.sql$text t,
       sys.sqlobj$auxdata a
 WHERE o.obj_type = 2
   --AND BITAND(o.flags, 1) = 1 /* enabled */
   AND t.signature = o.signature
   AND a.obj_type = o.obj_type
   AND a.signature = o.signature
   AND a.plan_id = o.plan_id
   AND a.parsing_schema_name NOT IN ('SYS', 'C##IOD')
   AND NOT EXISTS 
       ( SELECT NULL
           FROM sys.sqlobj$plan p
          WHERE p.signature = o.signature
            AND p.obj_type = o.obj_type
            AND p.plan_id = o.plan_id
        )
 ORDER BY
       o.signature,
       o.plan_id
/
