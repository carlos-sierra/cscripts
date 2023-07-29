-- only works from PDB. do not use CONTAINERS(table_name) since it causes ORA-00600: internal error code, arguments: [kkdolci1], [], [], [], [], [], [],
SELECT TO_CHAR(a.created, '&&cs_timestamp_full_format.') AS created,
       TO_CHAR(a.last_modified, '&&cs_datetime_full_format.') AS last_modified, 
       o.name AS plan_name,
       o.category,
       CASE WHEN p.plan_hash_2 IS NULL THEN 'NO' ElSE 'YES' END AS obj_plan,
       CASE WHEN d.comp_data IS NULL THEN 'NO' ElSE 'YES' END AS comp_data,
       DECODE(BITAND(o.flags, 1),   0, 'NO', 'YES') AS enabled,
       DECODE(BITAND(o.flags, 2),   0, 'NO', 'YES') AS accepted,
       DECODE(BITAND(o.flags, 4),   0, 'NO', 'YES') AS fixed,
       DECODE(BITAND(o.flags, 64),  0, 'YES', 'NO') AS reproduced,
       DECODE(BITAND(o.flags, 128), 0, 'NO', 'YES') AS autopurge,
       DECODE(BITAND(o.flags, 256), 0, 'NO', 'YES') AS adaptive, 
       a.origin AS ori, 
       p.plan_hash, -- normal plan_hash_value
       p.plan_hash_2, -- plan_hash_value ignoring transient object names (must be same than plan_id for a baseline to be used) 
       o.plan_id,
       p.plan_hash_full, -- adaptive plan (must be different than plan_hash_2 on loaded plans) 
       TO_CHAR(p.timestamp, '&&cs_datetime_full_format.') AS timestamp,
       a.description
  FROM sys.sqlobj$ o,
       sys.sqlobj$auxdata a,
       sys.sql$text t
       OUTER APPLY (
         SELECT TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash"]')) AS plan_hash, -- normal plan_hash_value
                TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash_2"]')) AS plan_hash_2, -- plan_hash_value ignoring transient object names (must be same than plan_id for a baseline to be used) 
                TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash_full"]')) AS plan_hash_full, -- adaptive plan (must be different than plan_hash_2 on loaded plans) 
                p.timestamp
           FROM sys.sqlobj$plan p
          WHERE p.signature = o.signature
            AND p.category = o.category
            AND p.obj_type = o.obj_type 
            AND p.plan_id = o.plan_id
            AND p.other_xml IS NOT NULL
            AND ROWNUM = 1
       ) p
       OUTER APPLY (
         SELECT d.comp_data
           FROM sys.sqlobj$data d
          WHERE d.signature = o.signature
            AND d.category = o.category
            AND d.obj_type = o.obj_type 
            AND d.plan_id = o.plan_id
            AND ROWNUM = 1
       ) d
 WHERE o.signature = :cs_signature
   AND o.category = 'DEFAULT'
   AND o.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND a.signature = o.signature
   AND a.category = o.category
   AND a.obj_type = o.obj_type
   AND a.plan_id = o.plan_id
   AND t.signature = a.signature
 ORDER BY
       a.created, a.last_modified, o.name
/
PRO Note: If Obj Plan and Comp Data are both NO then Baseline is Corrupt