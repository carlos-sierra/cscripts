SET FEED ON;
MERGE INTO sys.sqlobj$plan t
    USING (SELECT o.signature,
                   o.category,
                   o.obj_type,
                   o.plan_id,
                   1 AS id
               FROM sys.sqlobj$ o
             WHERE o.category = 'DEFAULT'
               AND o.obj_type = 2
               AND NOT EXISTS (
                     SELECT NULL
                       FROM sys.sqlobj$plan p
                       WHERE p.signature = o.signature
                         AND p.category = o.category
                         AND p.obj_type = o.obj_type 
                         AND p.plan_id = o.plan_id
                         AND p.id = 1
               )
               AND NOT EXISTS (
                     SELECT NULL
                       FROM sys.sqlobj$data d
                       WHERE d.signature = o.signature
                         AND d.category = o.category
                         AND d.obj_type = o.obj_type 
                         AND d.plan_id = o.plan_id
                         AND d.comp_data IS NOT NULL
               )) s
ON (t.signature = s.signature AND t.category = s.category AND t.obj_type = s.obj_type AND t.plan_id = s.plan_id AND t.id = s.id)
WHEN NOT MATCHED THEN
  INSERT (signature, category, obj_type, plan_id, id) 
  VALUES (s.signature, s.category, s.obj_type, s.plan_id, s.id)
/
COMMIT
/