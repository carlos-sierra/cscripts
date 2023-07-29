PRO
PRO Validate plan: "&&cs_plan_name."
SET SERVEROUT ON;
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
  l_plans INTEGER;
BEGIN
  FOR i IN (SELECT o.signature,
                  o.category,
                  o.obj_type,
                  o.plan_id,
                  o.name AS plan_name,
                  TO_CHAR(a.created, '&&cs_timestamp_full_format.') AS created,
                  TO_CHAR(a.last_modified, '&&cs_datetime_full_format.') AS last_modified, 
                  DECODE(BITAND(o.flags, 1),   0, 'NO', 'YES') AS enabled,
                  DECODE(BITAND(o.flags, 2),   0, 'NO', 'YES') AS accepted,
                  DECODE(BITAND(o.flags, 4),   0, 'NO', 'YES') AS fixed,
                  DECODE(BITAND(o.flags, 64),  0, 'YES', 'NO') AS reproduced,
                  DECODE(BITAND(o.flags, 128), 0, 'NO', 'YES') AS autopurge,
                  DECODE(BITAND(o.flags, 256), 0, 'NO', 'YES') AS adaptive, 
                  a.origin AS ori, 
                  t.sql_handle,
                  t.sql_text,
                  a.description
              FROM sys.sqlobj$ o,
                  sys.sqlobj$auxdata a,
                  sys.sql$text t
            WHERE o.signature = :cs_signature
              AND o.category = 'DEFAULT'
              AND o.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
              AND a.signature = o.signature
              AND a.category = o.category
              AND a.obj_type = o.obj_type
              AND a.plan_id = o.plan_id
              AND t.signature = o.signature
              AND NOT EXISTS (
                    SELECT NULL
                      FROM sys.sqlobj$plan p
                      WHERE p.signature = o.signature
                        AND p.category = o.category
                        AND p.obj_type = o.obj_type 
                        AND p.plan_id = o.plan_id
                        AND p.id = 1
                        AND ROWNUM = 1
              )
              AND NOT EXISTS (
                    SELECT NULL
                      FROM sys.sqlobj$data d
                      WHERE d.signature = o.signature
                        AND d.category = o.category
                        AND d.obj_type = o.obj_type 
                        AND d.plan_id = o.plan_id
                        AND d.comp_data IS NOT NULL
                        AND ROWNUM = 1
              )
            ORDER BY
                  o.signature, o.category, o.obj_type, o.plan_id)
  LOOP
    IF i.enabled = 'YES' THEN
      DBMS_OUTPUT.put_line('Disable Plan: '||i.plan_name);
      l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
    END IF;
    DBMS_OUTPUT.put_line('Fixing Corrupt Plan: '||i.plan_name);
    DELETE sys.sqlobj$plan WHERE signature = i.signature AND category = i.category AND obj_type = i.obj_type AND plan_id = i.plan_id AND id = 1;
    INSERT INTO sys.sqlobj$plan (signature, category, obj_type, plan_id, id) VALUES (i.signature, i.category, i.obj_type, i.plan_id, 1);
  END LOOP;
  COMMIT;
END;
/
WHENEVER SQLERROR CONTINUE;
SET SERVEROUT OFF;