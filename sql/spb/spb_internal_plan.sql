-- spb_internal_plan.sql
-- displays SPB plans for a given a sql_handle
-- this script is for internal use and only to be called from other scriprs

SET HEA OFF PAGES 0;
SELECT * FROM TABLE(DBMS_XPLAN.display_sql_plan_baseline('&&sql_handle.', NULL, 'ADVANCED -PROJECTION -ALIAS'));
SET HEA ON PAGES 100;
