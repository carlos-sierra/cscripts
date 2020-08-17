COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL last_active_time FOR A19 HEA 'Last Active Time';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL child_number FOR 999999 HEA 'Child|Number';
COL object_status FOR A14 HEA 'Object Status';
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
       con_id,
       child_number,
       ROW_NUMBER () OVER (PARTITION BY con_id, plan_hash_value ORDER BY 
       CASE 
         WHEN object_status = 'VALID' AND is_obsolete = 'N' AND is_shareable = 'Y' THEN 1
         WHEN object_status = 'VALID' AND is_obsolete = 'N' AND is_shareable = 'N' THEN 2
         WHEN object_status = 'VALID' AND is_obsolete = 'Y' THEN 3
         ELSE 4
       END,
       last_active_time DESC) AS row_number,
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
)
SELECT TO_CHAR(r.last_active_time, '&&cs_datetime_full_format.') AS last_active_time,
       r.con_id,
       c.name AS pdb_name,
       r.child_number,
       r.object_status, 
       r.is_obsolete,
       r.is_shareable,
       r.is_bind_aware,
       r.is_bind_sensitive,
       r.parsing_schema_name,
       r.plan_hash_value
  FROM ranked_child_cursors r,
       v$containers c
 WHERE r.row_number <= 3 -- up to 3 most recently active child cursors per plan_hash_value
   AND c.con_id = r.con_id
 ORDER BY
       r.last_active_time,
       r.con_id,
       r.child_number   
/
--
