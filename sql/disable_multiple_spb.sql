DECLARE
  l_plans INTEGER;
BEGIN
  FOR i IN (SELECT sql_handle, plan_name, DBMS_LOB.SUBSTR(sql_text, 1+DBMS_LOB.INSTR(sql_text, '*/'))  
              FROM dba_sql_plan_baselines 
             WHERE 1 = 1
               AND enabled = 'YES'
               AND DBMS_LOB.SUBSTR(sql_text, 1+DBMS_LOB.INSTR(sql_text, '*/')) IN 
             ORDER BY sql_handle, plan_name)
  LOOP
    --l_plans := DBMS_SPM.DROP_SQL_PLAN_BASELINE(sql_handle => i.sql_handle, plan_name => i.plan_name);
    l_plans := DBMS_SPM.ALTER_SQL_PLAN_BASELINE(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
  END LOOP;
END;
/

