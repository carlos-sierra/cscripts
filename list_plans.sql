SPO list_plans.txt;

SET LIN 300;
COL created FOR A30;
SELECT b.created,
       b.plan_name,
       b.enabled,
       b.accepted,
       b.reproduced,
       b.fixed
  FROM dba_sql_plan_baselines b
 WHERE b.sql_handle = NVL('&&sql_handle.', b.sql_handle)
 ORDER BY
       b.created,
       b.sql_handle,
       b.plan_name;

SPO OFF;