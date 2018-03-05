SET SERVEROUT ON;
DECLARE
  l_plan VARCHAR2(128) := 'IOD_CDB_PLAN';
  l_count NUMBER;
  l_value VARCHAR2(4000);
BEGIN
  SELECT COUNT(*) INTO l_count FROM dba_cdb_rsrc_plans WHERE plan = l_plan;
  IF l_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('plan '||l_plan||' does not exist');
  ELSE
    SELECT value INTO l_value FROM v$parameter WHERE name = 'resource_manager_plan';
    DBMS_OUTPUT.PUT_LINE('current resource_manager_plan: '||l_value);
    IF l_value <> 'FORCE:'||l_plan THEN
      DBMS_OUTPUT.PUT_LINE('set resource_manager_plan to: "FORCE:'||l_plan||'"');
      EXECUTE IMMEDIATE 'ALTER SYSTEM SET resource_manager_plan = ''FORCE:'||l_plan||'''';
      SELECT value INTO l_value FROM v$parameter WHERE name = 'resource_manager_plan';
      DBMS_OUTPUT.PUT_LINE('new resource_manager_plan: '||l_value);
    END IF;
  END IF;
END;
/
