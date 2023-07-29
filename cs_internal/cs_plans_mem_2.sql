PRO
PRO PLANS IN MEMORY - DISPLAY (dbms_xplan.display_cursor)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
PRO
SET HEA OFF PAGES 0;
WITH
ranked_child_cursors AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.con_id,
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
       is_bind_sensitive,
       is_bind_aware,
       parsing_schema_name,
       c.name AS pdb_name
  FROM v$sql s, v$containers c
 WHERE s.sql_id = '&&cs_sql_id.'
   AND ('&&cs_plan_hash_value.' IS NULL OR s.plan_hash_value = TO_NUMBER('&&cs_plan_hash_value.'))
   AND c.con_id = s.con_id
 ORDER BY
       s.last_active_time,
       s.con_id,
       s.child_number       
)
SELECT CASE WHEN p.plan_table_output LIKE 'SQL_ID  %' 
       THEN 
         'Last active time:'||TO_CHAR(r.last_active_time, '&&cs_datetime_full_format.')||
         ' '||REPLACE(REPLACE(p.plan_table_output, 'child number ', 'Child_Number:'), 'SQL_ID  ', 'SQL_ID:')||
         CASE WHEN r.object_status <> 'VALID' THEN ', Object_Status:'||r.object_status END||
         CASE WHEN r.is_obsolete <> 'N' THEN ', Is_Obsolete' END||
         CASE WHEN r.is_shareable <> 'Y' THEN ', Is_Not_Shareable' END||
         CASE WHEN r.is_bind_aware = 'Y' THEN ', Is_Bind_Aware' END||
         CASE WHEN r.is_bind_sensitive = 'Y' THEN ', Is_Bind_Sensitive' END||
         ', Con_ID:'||TRIM(TO_CHAR(r.con_id))||
         ', PDB_Name:'||r.pdb_name||
         ', Parsing_Schema:'||parsing_schema_name
       ELSE p.plan_table_output
       END AS plan_table_output
  FROM ranked_child_cursors r,
       TABLE(DBMS_XPLAN.display_cursor(r.sql_id, r.child_number, 'ADVANCED ALLSTATS LAST')) p
 WHERE r.row_number <= 3 -- up to N most recently active child cursors per plan_hash_value
/
SET HEA ON PAGES 100;
--