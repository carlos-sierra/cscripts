@@&&stgtab_sqlbaseline_script.
--
COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL created FOR A26 HEA 'Created';
COL plan_name FOR A30 HEA 'Plan Name';
COL origin FOR A29 HEA 'Origin';
COL ori FOR 999 HEA 'Ori';
COL timestamp FOR A19 HEA 'Timestamp';
COL last_executed FOR A19 HEA 'Last Executed';
COL last_modified FOR A19 HEA 'Last Modified';
COL description FOR A125 HEA 'Description';
COL executions FOR 999,999,990 HEA 'Executions';
COL et_per_exec_ms FOR 999,999,990.000 HEA 'Elapsed Time|AVG (ms)';
COL cpu_per_exec_ms FOR 999,999,990.000 HEA 'CPU Time|AVG (ms)';
COL buffers_per_exec FOR 999,999,999,990 HEA 'Buffer Gets|AVG';
COL reads_per_exec FOR 999,999,999,990 HEA 'Disk Reads|AVG';
COL rows_per_exec FOR 999,999,999,990 HEA 'Rows Processed|AVG';
COL elapsed_time FOR 999,999,999,999,990 HEA 'Elapsed Time|Total (us)';
COL cpu_time FOR 999,999,999,999,990 HEA 'CPU Time|Total (us)';
COL buffer_gets FOR 999,999,999,990 HEA 'Buffer Gets|Total';
COL disk_reads FOR 999,999,999,990 HEA 'Disk Reads|Total';
COL rows_processed FOR 999,999,999,990 HEA 'Rows Processed|Total';
COL category FOR A10 HEA 'Category' TRUNC;
COL obj_plan FOR A10 HEA 'Obj Plan';
COL comp_data FOR A10 HEA 'Comp Data';
COL enabled FOR A10 HEA 'Enabled';
COL accepted FOR A10 HEA 'Accepted';
COL fixed FOR A10 HEA 'Fixed' PRI;
COL reproduced FOR A10 HEA 'Reproduced';
COL autopurge FOR A10 HEA 'Autopurge';
COL adaptive FOR A10 HEA 'Adaptive';
COL plan_id FOR 999999999990 HEA 'Plan ID';
COL plan_hash_2 FOR 999999999990 HEA 'Plan Hash 2';
COL plan_hash FOR 999999999990 HEA 'Plan Hash';
COL plan_hash_full FOR 999999999990 HEA 'Plan Hash|Full';
COL outline_hint FOR A125 HEA 'CBO Hints';
--
PRO
PRO SQL PLAN BASELINES - LIST (dba_sql_plan_baselines)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(s.created, '&&cs_timestamp_full_format.') AS created, 
       TO_CHAR(s.last_modified, '&&cs_datetime_full_format.') AS last_modified, 
       TO_CHAR(s.last_executed, '&&cs_datetime_full_format.') AS last_executed, 
       s.con_id,
       c.name AS pdb_name,
       s.plan_name, 
       CASE WHEN s.con_id > 2 THEN (CASE WHEN (SELECT COUNT(*) FROM sys.sqlobj$ o, sys.sqlobj$plan p WHERE o.signature = s.signature AND o.obj_type = 2 AND o.name = s.plan_name AND p.signature = o.signature AND p.obj_type = o.obj_type AND p.plan_id = o.plan_id) = 0 THEN 'NO' ELSE 'YES' END) END AS obj_plan,
       CASE WHEN s.con_id > 2 THEN (CASE WHEN (SELECT COUNT(*) FROM sys.sqlobj$ o, sys.sqlobj$data d WHERE o.signature = s.signature AND o.obj_type = 2 AND o.name = s.plan_name AND d.signature = o.signature AND d.obj_type = o.obj_type AND d.plan_id = o.plan_id AND d.comp_data IS NOT NULL) = 0 THEN 'NO' ELSE 'YES' END) END AS comp_data,
       s.enabled, s.accepted, s.fixed, s.reproduced, s.autopurge, s.adaptive, 
       s.origin, 
       s.description
  FROM cdb_sql_plan_baselines s,
       v$containers c
 WHERE s.signature = :cs_signature
   AND c.con_id = s.con_id
 ORDER BY 
       s.created, s.last_modified, s.last_executed, s.con_id, s.plan_name
/
PRO Note: If Obj Plan and Comp Data are both NO then Baseline is Corrupt
--
PRO
PRO SQL PLAN BASELINES - PERFORMANCE (dba_sql_plan_baselines)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(s.created, '&&cs_timestamp_full_format.') AS created, 
       TO_CHAR(s.last_modified, '&&cs_datetime_full_format.') AS last_modified, 
       s.con_id,
       c.name AS pdb_name,
       s.plan_name, 
       CASE WHEN s.con_id > 2 THEN (CASE WHEN (SELECT COUNT(*) FROM sys.sqlobj$ o, sys.sqlobj$plan p WHERE o.signature = s.signature AND o.obj_type = 2 AND o.name = s.plan_name AND p.signature = o.signature AND p.obj_type = o.obj_type AND p.plan_id = o.plan_id) = 0 THEN 'NO' ELSE 'YES' END) END AS obj_plan,
       CASE WHEN s.con_id > 2 THEN (CASE WHEN (SELECT COUNT(*) FROM sys.sqlobj$ o, sys.sqlobj$data d WHERE o.signature = s.signature AND o.obj_type = 2 AND o.name = s.plan_name AND d.signature = o.signature AND d.obj_type = o.obj_type AND d.plan_id = o.plan_id AND d.comp_data IS NOT NULL) = 0 THEN 'NO' ELSE 'YES' END) END AS comp_data,
       s.enabled, s.accepted, s.fixed, s.reproduced, s.autopurge, s.adaptive, 
       s.origin, 
       s.elapsed_time/GREATEST(s.executions,1)/1e3 AS et_per_exec_ms,
       s.cpu_time/GREATEST(s.executions,1)/1e3 AS cpu_per_exec_ms,
       s.buffer_gets/GREATEST(s.executions,1) AS buffers_per_exec,
       s.disk_reads/GREATEST(s.executions,1) AS reads_per_exec,
       s.rows_processed/GREATEST(s.executions,1) AS rows_per_exec,
       s.executions,
       s.elapsed_time,
       s.cpu_time,
       s.buffer_gets,
       s.disk_reads,
       s.rows_processed
  FROM cdb_sql_plan_baselines s,
       v$containers c
 WHERE s.signature = :cs_signature
   AND c.con_id = s.con_id
 ORDER BY 
       s.created, s.last_modified, s.con_id, s.plan_name
/
PRO Note: If Obj Plan and Comp Data are both NO then Baseline is Corrupt
--
PRO
PRO SQL PLAN BASELINES - IDS (dba_sql_plan_baselines)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
-- only works from PDB. do not use CONTAINERS(table_name) since it causes ORA-00600: internal error code, arguments: [kkdolci1], [], [], [], [], [], [],
SELECT TO_CHAR(a.created, '&&cs_timestamp_full_format.') AS created,
       TO_CHAR(a.last_modified, '&&cs_datetime_full_format.') AS last_modified, 
       o.name AS plan_name,
       o.category,
       CASE WHEN p.plan_hash_2 IS NULL THEN 'NO' ElSE 'YES' END AS obj_plan,
       CASE WHEN d.comp_data IS NULL THEN 'NO' ElSE 'YES' END AS comp_data,
       DECODE(BITAND(o.flags, 1),   0, 'NO', 'YES') AS enabled,
       DECODE(BITAND(o.flags, 2),   0, 'NO', 'YES') AS accepted,
       DECODE(BITAND(o.flags, 4),   0, 'NO', 'YES') AS fixed,
       DECODE(BITAND(o.flags, 64),  0, 'YES', 'NO') AS reproduced,
       DECODE(BITAND(o.flags, 128), 0, 'NO', 'YES') AS autopurge,
       DECODE(BITAND(o.flags, 256), 0, 'NO', 'YES') AS adaptive, 
       a.origin AS ori, 
       p.plan_hash, -- normal plan_hash_value
       p.plan_hash_2, -- plan_hash_value ignoring transient object names (must be same than plan_id for a baseline to be used) 
       o.plan_id,
       p. plan_hash_full, -- adaptive plan (must be different than plan_hash_2 on loaded plans) 
       TO_CHAR(p.timestamp, '&&cs_datetime_full_format.') AS timestamp,
       a.description
  FROM sys.sqlobj$ o,
       sys.sqlobj$auxdata a,
       sys.sql$text t
       OUTER APPLY (
         SELECT TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash"]')) AS plan_hash, -- normal plan_hash_value
                TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash_2"]')) AS plan_hash_2, -- plan_hash_value ignoring transient object names (must be same than plan_id for a baseline to be used) 
                TO_NUMBER(EXTRACTVALUE(XMLTYPE(p.other_xml),'/*/info[@type = "plan_hash_full"]')) AS plan_hash_full, -- adaptive plan (must be different than plan_hash_2 on loaded plans) 
                p.timestamp
           FROM sys.sqlobj$plan p
          WHERE p.signature = o.signature
            AND p.category = o.category
            AND p.obj_type = o.obj_type 
            AND p.plan_id = o.plan_id
            AND p.other_xml IS NOT NULL
            AND ROWNUM = 1
       ) p
       OUTER APPLY (
         SELECT d.comp_data
           FROM sys.sqlobj$data d
          WHERE d.signature = o.signature
            AND d.category = o.category
            AND d.obj_type = o.obj_type 
            AND d.plan_id = o.plan_id
            AND ROWNUM = 1
       ) d
 WHERE o.signature = :cs_signature
   AND o.category = 'DEFAULT'
   AND o.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND a.signature = o.signature
   AND a.category = o.category
   AND a.obj_type = o.obj_type
   AND a.plan_id = o.plan_id
   AND t.signature = a.signature
 ORDER BY
       a.created, a.last_modified, o.name
/
PRO Note: If Obj Plan and Comp Data are both NO then Baseline is Corrupt
--
-- PRO
-- PRO CBO_HINTS (sqlobj$plan)
-- PRO ~~~~~~~~~
-- -- only works from PDB. do not use CONTAINERS(table_name) since it causes ORA-00600: internal error code, arguments: [kkdolci1], [], [], [], [], [], [],
-- BREAK ON plan_id SKIP PAGE DUPL;
-- SELECT d.plan_id, d.category, x.outline_hint
--   FROM sys.sqlobj$plan d, XMLTABLE('other_xml/outline_data/hint' PASSING XMLTYPE(d.other_xml) COLUMNS outline_hint VARCHAR2(500) PATH '.') x
--  WHERE d.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */ 
--    AND d.other_xml IS NOT NULL
--    AND d.signature = :cs_signature
-- /
-- CLEAR BREAK;