SET SERVEROUT ON;
DECLARE
  l_plans INTEGER;
BEGIN
  FOR i IN (SELECT sql_handle, plan_name, description FROM dba_sql_plan_baselines WHERE enabled = 'NO' AND accepted = 'YES' AND last_modified > SYSDATE - 1 AND sql_text LIKE '%performScanQuery(workflowInstances,I_GC_INDEX)%')
  LOOP
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'YES');
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => TRIM(i.description||' ENABLED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')));   
    DBMS_OUTPUT.put_line(l_plans);
  END LOOP;
END;
/
