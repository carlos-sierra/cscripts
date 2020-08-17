COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL last_active_time FOR A19 HEA 'Last Active Time';
COL last_load_time FOR A19 HEA 'Last Load Time';
COL child_number FOR 999999 HEA 'Child|Number';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL loads FOR 99999 HEA 'Loads';
COL invalidations FOR 99999 HEA 'Inval';
COL object_status FOR A14 HEA 'Object Status';
COL is_obsolete FOR A8 HEA 'Is|Obsolete';
COL is_shareable FOR A9 HEA 'Is|Shareable';
COL is_bind_aware FOR A9 HEA 'Is Bind|Aware';
COL is_bind_sensitive FOR A9 HEA 'Is Bind|Sensitive';
COL optimizer_cost FOR 9999999999 HEA 'Optimizer|Cost';
COL optimizer_env_hash_value FOR 9999999999 HEA 'Optimizer|Hash Value';
COL sql_plan_baseline FOR A30 HEA 'SQL Plan Baseline';
COL sql_profile FOR A30 HEA 'SQL Profile';
COL sql_patch FOR A30 HEA 'SQL Patch';
COL first_load_time FOR A19 HEA 'First Load Time';
COL parsing_schema_name FOR A30 HEA 'Parsing Schema Name';
--
PRO
PRO PLANS STABILITY (v$sql)
PRO ~~~~~~~~~~~~~~~
SELECT s.con_id,
       c.name AS pdb_name,
       TO_CHAR(s.last_active_time, '&&cs_datetime_full_format.') AS last_active_time,
       s.child_number,
       s.plan_hash_value,
       REPLACE(s.last_load_time, '/', 'T') AS last_load_time,
       s.loads,
       s.invalidations,
       s.object_status,  
       s.is_obsolete,
       s.is_shareable,
       s.is_bind_aware,
       s.is_bind_sensitive,
       s.optimizer_cost, 
       s.optimizer_env_hash_value,
       s.sql_plan_baseline,
       s.sql_profile,
       s.sql_patch,
       REPLACE(s.first_load_time, '/', 'T') AS first_load_time,
       s.parsing_schema_name
  FROM v$sql s,
       v$containers c
 WHERE s.sql_id = '&&cs_sql_id.'
   AND c.con_id = s.con_id
 ORDER BY
       s.con_id,
       s.last_active_time,
       s.child_number
/
--
