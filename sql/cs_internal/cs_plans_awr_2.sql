PRO
PRO PLANS IN AWR - DISPLAY (dbms_xplan.display_awr)
PRO ~~~~~~~~~~~~~~~~~~~~~~
SET HEA OFF;
WITH 
plans_by_timestamp AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id,
       plan_hash_value
  FROM dba_hist_sql_plan
 WHERE sql_id = '&&cs_sql_id.'
   AND ('&&cs_plan_hash_value.' IS NULL OR plan_hash_value = TO_NUMBER('&&cs_plan_hash_value.'))
   AND id = 0
 ORDER BY
       timestamp
)
SELECT p.plan_table_output
  FROM plans_by_timestamp h,
       TABLE(DBMS_XPLAN.DISPLAY_AWR(h.sql_id, h.plan_hash_value, NULL, 'ADVANCED')) p
/
SET HEA ON;
--

