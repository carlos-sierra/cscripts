PRO
PRO SQL PLAN BASELINES - DISPLAY (dbms_xplan.display_sql_plan_baseline)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET HEA OFF;
SELECT * FROM TABLE(DBMS_XPLAN.display_sql_plan_baseline('&&cs_sql_handle.', NULL, 'ADVANCED'));
SET HEA ON;
