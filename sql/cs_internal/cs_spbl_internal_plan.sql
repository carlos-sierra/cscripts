PRO
PRO SQL PLAN BASELINES - DISPLAY (dbms_xplan.display_sql_plan_baseline)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- only works from PDB.
SET HEA OFF PAGES 0;
SELECT * FROM TABLE(DBMS_XPLAN.display_sql_plan_baseline('&&cs_sql_handle.', NULL, 'ADVANCED')) WHERE '&&cs_sql_handle.' IS NOT NULL;
SET HEA ON PAGES 100;
