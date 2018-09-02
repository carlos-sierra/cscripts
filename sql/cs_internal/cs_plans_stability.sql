COL last_active_time FOR A19 HEA 'Last Active Time';
COL last_load_time FOR A19 HEA 'Last Load Time';
COL child_number FOR 999999 HEA 'Child|Number';
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash Value';
COL loads FOR 99999 HEA 'Loads';
COL invalidations FOR 99999 HEA 'Inval';
COL obj_sta FOR A7 HEA 'Object|Status';
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
SELECT TO_CHAR(last_active_time, '&&cs_datetime_full_format.') last_active_time,
       child_number,
       plan_hash_value,
       REPLACE(last_load_time, '/', 'T') last_load_time,
       loads,
       invalidations,
       SUBSTR(object_status, 1, 7) obj_sta, 
       is_obsolete,
       is_shareable,
       is_bind_aware,
       is_bind_sensitive,
       optimizer_cost, 
       optimizer_env_hash_value,
       sql_plan_baseline,
       sql_profile,
       sql_patch,
       REPLACE(first_load_time, '/', 'T') first_load_time,
       parsing_schema_name
  FROM v$sql
 WHERE sql_id = '&&cs_sql_id.'
   AND executions > 0
 ORDER BY
       last_active_time,
       child_number
/
--
