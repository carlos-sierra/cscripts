COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL last_active_time FOR A19 HEA 'Last Active Time';
COL last_load_time FOR A19 HEA 'Last Load Time';
COL child_number FOR 999999 HEA 'Child|Number';
COL plan_hash_value FOR 9999999999 HEA 'Plan Hash|Value';
COL plan_hash_value_2 FOR 9999999999 HEA 'Plan Hash|Value 2';
COL full_plan_hash_value FOR 9999999999 HEA 'Full Plan|Hash Value';
COL executions FOR 999,999,990 HEA 'Executions';
COL loads FOR 99999 HEA 'Loads';
COL invalidations FOR 99999 HEA 'Inval';
COL object_status FOR A14 HEA 'Object Status';
COL is_obsolete FOR A8 HEA 'Is|Obsolete';
COL is_shareable FOR A9 HEA 'Is|Shareable';
COL is_bind_aware FOR A9 HEA 'Is Bind|Aware';
COL is_bind_sensitive FOR A9 HEA 'Is Bind|Sensitive';
COL optimizer_cost FOR 9999999999 HEA 'Optimizer|Cost';
COL optimizer_env_hash_value FOR 9999999999 HEA 'Optimizer|Hash Value';
COL baseline_repro_fail FOR A8 HEA 'Failed|Baseline';
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
      --  p.plan_hash_value_2,
       s.full_plan_hash_value,
       REPLACE(s.last_load_time, '/', 'T') AS last_load_time,
       s.executions,
       s.loads,
       s.invalidations,
       s.object_status,  
       s.is_obsolete,
       s.is_shareable,
       s.is_bind_aware,
       s.is_bind_sensitive,
       s.optimizer_cost, 
       s.optimizer_env_hash_value,
      --  p.baseline_repro_fail,
       s.sql_plan_baseline,
       s.sql_profile,
       s.sql_patch,
       REPLACE(s.first_load_time, '/', 'T') AS first_load_time,
       s.parsing_schema_name
  FROM v$sql s,
       v$containers c
      --  had to remove this part due to performance issues on sql with hcv (e.g.: DBPERF-7505)
      --  OUTER APPLY ( -- could be CROSS APPLY since we expect one and only one row 
      --    SELECT TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash_2"]')) AS plan_hash_value_2,
      --           UPPER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "baseline_repro_fail"]')) AS baseline_repro_fail
      --      FROM v$sql_plan p
      --     WHERE p.con_id = s.con_id
      --       AND p.address = s.address
      --       AND p.hash_value = s.hash_value
      --       AND p.sql_id = s.sql_id
      --       AND p.plan_hash_value = s.plan_hash_value
      --       AND p.child_address = s.child_address
      --       AND p.child_number = s.child_number
      --       AND p.other_xml IS NOT NULL
      --       --AND p.id = 1
      --       -- AND TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash_2"]')) >= 0
      --       AND ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
      --     ORDER BY
      --           p.timestamp DESC, p.id
      --     FETCH FIRST 1 ROW ONLY -- redundant. expecting one and only one row 
      --  ) p
 WHERE s.sql_id = '&&cs_sql_id.'
   AND c.con_id = s.con_id
 ORDER BY
       s.con_id,
       s.last_active_time,
       s.child_number
/
--
