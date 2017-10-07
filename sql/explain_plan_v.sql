/*
SET LIN 300 PAGES 0;
SELECT * FROM explain_plan;
*/

CREATE OR REPLACE VIEW explain_plan AS
SELECT plan_table_output explain_plan 
FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', NULL, 'ALL'))
/
