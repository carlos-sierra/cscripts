PRO
PRO PLANS IN MEMORY - DISPLAY (dbms_xplan.display_cursor)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
SET HEA OFF;
WITH
ranked_child_cursors AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id,
       child_number,
       ROW_NUMBER () OVER (PARTITION BY plan_hash_value ORDER BY 
       CASE 
         WHEN object_status = 'VALID' AND is_obsolete = 'N' AND is_shareable = 'Y' THEN 1
         WHEN object_status = 'VALID' AND is_obsolete = 'N' AND is_shareable = 'N' THEN 2
         WHEN object_status = 'VALID' AND is_obsolete = 'Y' THEN 3
         ELSE 4
       END,
       last_active_time DESC) row_number,
       plan_hash_value,
       last_active_time,
       object_status,
       is_obsolete,
       is_shareable,
       is_bind_aware,
       is_bind_sensitive,
       parsing_schema_name
  FROM v$sql 
 WHERE sql_id = '&&cs_sql_id.'
   AND ('&&cs_plan_hash_value.' IS NULL OR plan_hash_value = TO_NUMBER('&&cs_plan_hash_value.'))
 ORDER BY
       last_active_time
)
SELECT p.plan_table_output
  FROM ranked_child_cursors r,
       TABLE(DBMS_XPLAN.DISPLAY_CURSOR(r.sql_id, r.child_number, 'ADVANCED ALLSTATS LAST')) p
 WHERE r.row_number = 1
/
SET HEA ON;
--