SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT ON;

COL signature FOR 99999999999999999999;
COL sql_handle FOR A20;
COL plan_name FOR A30;
COL description FOR A100;
SELECT o.signature,
       t.sql_handle,
       o.plan_id,
       o.name plan_name,
       DECODE(BITAND(o.flags, 1),   0, 'NO', 'YES') enabled,
       DECODE(BITAND(o.flags, 2),   0, 'NO', 'YES') accepted,
       DECODE(BITAND(o.flags, 4),   0, 'NO', 'YES') fixed,
       DECODE(BITAND(o.flags, 64),  0, 'YES', 'NO') reproduced,
       DECODE(BITAND(o.flags, 256), 0, 'NO', 'YES') adaptive,
       TO_CHAR(o.last_executed, 'YYYY-MM-DD"T"HH24:MI:SS') last_executed
  FROM sqlobj$ o,
       sql$text t
 WHERE o.obj_type = 2
   AND BITAND(o.flags, 1) = 1 /* enabled */
   AND t.signature = o.signature
   AND NOT EXISTS 
       ( SELECT NULL
           FROM sqlobj$plan p
          WHERE p.signature = o.signature
            AND p.obj_type = o.obj_type
            AND p.plan_id = o.plan_id
        )
 ORDER BY
       o.signature,
       o.plan_id
/

DECLARE
  l_plans INTEGER;
  l_plans_t INTEGER := 0;
BEGIN
  FOR i IN (SELECT o.signature,
                   t.sql_handle,
                   o.plan_id,
                   o.name plan_name,
                   DECODE(BITAND(o.flags, 1),   0, 'NO', 'YES') enabled,
                   DECODE(BITAND(o.flags, 2),   0, 'NO', 'YES') accepted,
                   DECODE(BITAND(o.flags, 4),   0, 'NO', 'YES') fixed,
                   DECODE(BITAND(o.flags, 64),  0, 'YES', 'NO') reproduced,
                   DECODE(BITAND(o.flags, 256), 0, 'NO', 'YES') adaptive,
                   TO_CHAR(o.last_executed, 'YYYY-MM-DD"T"HH24:MI:SS') last_executed,
                   a.description
              FROM sqlobj$ o,
                   sql$text t,
                   sqlobj$auxdata a
             WHERE o.obj_type = 2
               AND BITAND(o.flags, 1) = 1 /* enabled */
               AND t.signature = o.signature
               AND a.obj_type = 2 /* 1=profile, 2=baseline, 3=patch */
               AND a.signature = o.signature
               AND a.plan_id = o.plan_id
               AND NOT EXISTS 
                   ( SELECT NULL
                       FROM sqlobj$plan p
                      WHERE p.signature = o.signature
                        AND p.obj_type = o.obj_type
                        AND p.plan_id = o.plan_id
                    )
             ORDER BY
                   o.signature,
                   o.plan_id)
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
      attribute_value => i.description||' ORA-06512 DISABLED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
    );
*/
    l_plans_t := l_plans_t + l_plans;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('PLANS:'||l_plans_t);
END;
/

