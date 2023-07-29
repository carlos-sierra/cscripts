VAR cs_execution_plan CLOB;
EXEC :cs_execution_plan := NULL;
-- SET SERVEROUT ON;
BEGIN
  FOR i IN (SELECT plan_table_output FROM TABLE(DBMS_XPLAN.display_cursor(sql_id => '&&cs_sql_id.', cursor_child_no => (SELECT child_number FROM v$sql WHERE sql_id = '&&cs_sql_id.' ORDER BY last_active_time DESC FETCH FIRST 1 ROW ONLY), format => 'TYPICAL -NOTE -PREDICATE')))
  LOOP
    IF :cs_execution_plan IS NOT NULL AND LENGTH(i.plan_table_output) > 1 THEN
      -- DBMS_OUTPUT.put_line(i.plan_table_output);
      DBMS_LOB.writeappend(:cs_execution_plan, LENGTH(i.plan_table_output) + 1, i.plan_table_output||CHR(10));
    END IF;
    IF i.plan_table_output LIKE 'Plan hash value:%' THEN
      :cs_execution_plan := i.plan_table_output||CHR(10);
    END IF;
  END LOOP;
END;
/
PRO
PRO LATEST PLAN IN MEMORY - DISPLAY (dbms_xplan.display_cursor)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
SET HEA OFF PAGES 0;
PRINT :cs_execution_plan
SET HEA ON PAGES 100;
--