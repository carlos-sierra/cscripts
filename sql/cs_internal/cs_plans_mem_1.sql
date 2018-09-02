COL last_active_time FOR A19 HEA 'Last Active Time';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL child_number FOR 999999 HEA 'Child|Number';
COL obj_sta FOR A7 HEA 'Object|Status';
COL is_obsolete FOR A8 HEA 'Is|Obsolete';
COL is_shareable FOR A9 HEA 'Is|Shareable';
COL is_bind_aware FOR A9 HEA 'Is Bind|Aware';
COL is_bind_sensitive FOR A9 HEA 'Is Bind|Sensitive';
COL parsing_schema_name FOR A30 HEA 'Parsing Schema Name';
--
PRO
PRO PLANS IN MEMORY (v$sql)
PRO ~~~~~~~~~~~~~~~
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
       last_active_time DESC
)
SELECT TO_CHAR(last_active_time, '&&cs_datetime_full_format.') last_active_time,
       plan_hash_value,
       child_number,
       SUBSTR(object_status, 1, 7) obj_sta,
       is_obsolete,
       is_shareable,
       is_bind_aware,
       is_bind_sensitive,
       parsing_schema_name
  FROM ranked_child_cursors r
 WHERE r.row_number = 1
 ORDER BY
       last_active_time
/
--
