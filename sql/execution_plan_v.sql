/*
GRANT SELECT ON v_$session TO hr;
GRANT SELECT ON v_$sql TO hr;
GRANT SELECT ON v_$sql_plan TO hr;
GRANT SELECT ON v_$sql_plan_statistics_all TO hr;

SET LIN 300 PAGES 0;
SELECT * FROM execution_plan;
*/

CREATE OR REPLACE VIEW execution_plan AS
WITH prev AS (SELECT prev_sql_id sql_id, prev_child_number child_number FROM v$session WHERE sid = SYS_CONTEXT('USERENV', 'SID'))
SELECT plan.plan_table_output execution_plan FROM prev, TABLE(DBMS_XPLAN.DISPLAY_CURSOR(prev.sql_id, prev.child_number, 'ADVANCED ALLSTATS LAST ALIAS')) plan
/
