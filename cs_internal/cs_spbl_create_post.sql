---------------------------------------------------------------------------------------
--
-- disable baselines on this sql if metadata is corrupt (ORA-13831)
--
DECLARE
  l_plans INTEGER;
  l_plans_t INTEGER := 0;
  l_description VARCHAR2(500);
BEGIN
  FOR i IN (SELECT t.sql_handle,
                   o.name plan_name,
                   a.description
              FROM sqlobj$plan p,
                   sqlobj$ o,
                   sqlobj$auxdata a,
                   sql$text t
             WHERE p.signature = :cs_signature
               AND p.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND p.id = 1
               AND p.other_xml IS NOT NULL
               -- plan_hash_value ignoring transient object names (must be same than plan_id for a baseline to be used)
               AND p.plan_id <> TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) 
               AND o.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND o.signature = p.signature
               AND o.plan_id = p.plan_id
               AND BITAND(o.flags, 1) = 1 /* enabled */
               AND a.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND a.signature = p.signature
               AND a.plan_id = p.plan_id
               AND a.created > TO_DATE('&&creation_time.', '&&cs_datetime_full_format.') - 1/1440
               AND t.signature = p.signature
             ORDER BY
                   t.sql_handle,
                   o.name)
  LOOP
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
    l_description := TRIM(i.description||' cs_spbl_create.sql ORA-13831 DISABLED='||TO_CHAR(SYSDATE, '&&cs_datetime_full_format.'));
    DBMS_OUTPUT.put_line('disable baseline since metadata is corrupt (ORA-13831): '||i.sql_handle||' '||i.plan_name||' '||l_description);
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => l_description);
    l_plans_t := l_plans_t + l_plans;
  END LOOP;
END;
/
--
---------------------------------------------------------------------------------------
--
-- disable baselines on this sql if metadata is corrupt (ORA-06512)
--
DECLARE
  l_plans INTEGER; 
  l_plans_t INTEGER := 0;
  l_description VARCHAR2(500);
BEGIN 
  FOR i IN (SELECT t.sql_handle, 
                   o.name plan_name, 
                   a.description 
              FROM sys.sqlobj$ o, 
                   sys.sql$text t, 
                   sys.sqlobj$auxdata a 
             WHERE o.signature = :cs_signature
               AND o.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND BITAND(o.flags, 1) = 1 /* enabled */ 
               AND t.signature = o.signature 
               AND a.obj_type = o.obj_type 
               AND a.signature = o.signature 
               AND a.plan_id = o.plan_id 
               AND a.created > TO_DATE('&&creation_time.', '&&cs_datetime_full_format.') - 1/1440
               AND NOT EXISTS  
                   ( SELECT NULL 
                       FROM sys.sqlobj$plan p 
                      WHERE p.signature = o.signature 
                        AND p.obj_type = o.obj_type 
                        AND p.plan_id = o.plan_id 
                    ) 
             ORDER BY 
                   o.plan_id) 
  LOOP 
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO'); 
    l_description := i.description||' cs_spbl_create.sql ORA-06512 DISABLED='||TO_CHAR(SYSDATE, '&&cs_datetime_full_format.');
    DBMS_OUTPUT.put_line('disable baseline since metadata is corrupt (ORA-06512): '||i.sql_handle||' '||i.plan_name||' '||l_description);
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => l_description); 
    l_plans_t := l_plans_t + l_plans;
  END LOOP; 
END;
/
--
---------------------------------------------------------------------------------------
--
-- fix Corrupt Baseline (DBPERF-6822)
--
MERGE INTO sys.sqlobj$plan t
    USING (SELECT o.signature,
                  o.category,
                  o.obj_type,
                  o.plan_id,
                  1 AS id
              FROM sys.sqlobj$ o
            WHERE o.category = 'DEFAULT'
              AND o.obj_type = 2
              AND o.signature = :cs_signature
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