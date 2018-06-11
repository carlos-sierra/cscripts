SET SERVEROUT ON
DECLARE 
  l_plans NUMBER;
  l_total_plans NUMBER := 0;
BEGIN
  FOR i IN (SELECT DISTINCT sql_handle FROM dba_sql_plan_baselines WHERE description LIKE 'IOD%')
  LOOP
    l_plans := DBMS_SPM.DROP_SQL_PLAN_BASELINE(i.sql_handle);
    l_total_plans := l_total_plans + l_plans;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('dropped '||l_total_plans||' plans');
END;
/
