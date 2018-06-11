SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT ON;

COL signature FOR 99999999999999999999;
COL sql_handle FOR A20;
COL plan_name FOR A30;
COL description FOR A100;
SELECT p.signature,
       t.sql_handle,
       o.name plan_name,
       p.plan_id,
       TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) plan_hash_2, -- plan_hash_value ignoring transient object names (must be same than plan_id)
       TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash"]')) plan_hash, -- normal plan_hash_value
       TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_full"]')) plan_hash_full, -- adaptive plan (must be different than plan_hash_2 on loaded plans)
       DECODE(BITAND(o.flags, 1),   0, 'NO', 'YES') enabled,
       DECODE(BITAND(o.flags, 2),   0, 'NO', 'YES') accepted,
       DECODE(BITAND(o.flags, 4),   0, 'NO', 'YES') fixed,
       DECODE(BITAND(o.flags, 64),  0, 'YES', 'NO') reproduced,
       DECODE(BITAND(o.flags, 256), 0, 'NO', 'YES') adaptive,
       TO_CHAR(a.created, 'YYYY-MM-DD"T"HH24:MI:SS') created,
       a.description
  FROM sqlobj$plan p,
       sqlobj$ o,
       sqlobj$auxdata a,
       sql$text t
 WHERE p.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND p.id = 1
   AND p.other_xml IS NOT NULL
   AND p.plan_id <> TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]'))
   --AND TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_full"]')) = TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]'))
   AND o.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND o.signature = p.signature
   AND o.plan_id = p.plan_id
   --AND BITAND(o.flags, 1) = 1 /* enabled */
   AND a.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND a.signature = p.signature
   AND a.plan_id = p.plan_id
   AND t.signature = p.signature
/

DECLARE
  l_plans INTEGER;
  l_plans_t INTEGER := 0;
BEGIN
  FOR i IN (SELECT t.sql_handle,
                   o.name plan_name,
                   a.description
              FROM sqlobj$plan p,
                   sqlobj$ o,
                   sqlobj$auxdata a,
                   sql$text t
             WHERE p.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND p.id = 1
               AND p.other_xml IS NOT NULL
               -- plan_hash_value ignoring transient object names (must be same than plan_id)
               AND p.plan_id <> TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]'))
               -- adaptive plan (must be different than plan_hash_2 on loaded plans)
               --AND TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_full"]')) = TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]'))
               AND o.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND o.signature = p.signature
               AND o.plan_id = p.plan_id
               AND BITAND(o.flags, 1) = 1 /* enabled */
               AND a.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND a.signature = p.signature
               AND a.plan_id = p.plan_id
               AND t.signature = p.signature
             ORDER BY
                   t.sql_handle,
                   o.name)
  LOOP
  /*
    l_plans :=
    DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
      sql_handle      => i.sql_handle,
      plan_name       => i.plan_name,
      attribute_name  => 'ENABLED',
      attribute_value => 'NO'
    );
    l_plans :=
    DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
      sql_handle      => i.sql_handle,
      plan_name       => i.plan_name,
      attribute_name  => 'DESCRIPTION',
      attribute_value => i.description||' ORA-13831 DISABLED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
    );
*/
    l_plans_t := l_plans_t + l_plans;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('PLANS:'||l_plans_t);
END;
/

