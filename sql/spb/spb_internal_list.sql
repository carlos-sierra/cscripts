-- spb_internal_list
-- lists SPBs given a signature
-- this script is for internal use and only to be called from other scriprs

COL plan_name FOR A30;
COL created FOR A19;
COL last_executed FOR A19;
COL last_modified FOR A19;
COL description FOR A150;

SELECT TO_CHAR(created, 'YYYY-MM-DD"T"HH24:MI:SS') created, plan_name, 
       enabled, accepted, fixed, reproduced, adaptive, 
       origin, 
       TO_CHAR(last_executed, 'YYYY-MM-DD"T"HH24:MI:SS') last_executed, 
       TO_CHAR(last_modified, 'YYYY-MM-DD"T"HH24:MI:SS') last_modified, 
       description
FROM dba_sql_plan_baselines WHERE signature = &&signature.
ORDER BY created, plan_name
/

COL executions FOR 999,999,990;
COL et_per_exec_ms FOR 999,999,990.000;
COL cpu_per_exec_ms FOR 999,999,990.000;
COL buffers_per_exec FOR 999,999,999,990;
COL reads_per_exec FOR 999,999,999,990;
COL rows_per_exec FOR 999,999,999,990;
COL elapsed_time FOR 999,999,999,990;
COL cpu_time FOR 999,999,999,990;
COL buffer_gets FOR 999,999,999,990;
COL disk_reads FOR 999,999,999,990;
COL rows_processed FOR 999,999,999,990;

SELECT TO_CHAR(created, 'YYYY-MM-DD"T"HH24:MI:SS') created, plan_name, 
       enabled, accepted, fixed, reproduced, adaptive, 
       origin, 
       ROUND(elapsed_time/GREATEST(executions,1)/1e3,3) et_per_exec_ms,
       ROUND(cpu_time/GREATEST(executions,1)/1e3,3) cpu_per_exec_ms,
       ROUND(buffer_gets/GREATEST(executions,1),3) buffers_per_exec,
       ROUND(disk_reads/GREATEST(executions,1),3) reads_per_exec,
       ROUND(rows_processed/GREATEST(executions,1),3) rows_per_exec,
       executions,
       elapsed_time,
       cpu_time,
       buffer_gets,
       disk_reads,
       rows_processed
FROM dba_sql_plan_baselines WHERE signature = &&signature.
ORDER BY created, plan_name
/
 
SELECT TO_CHAR(a.created, 'YYYY-MM-DD"T"HH24:MI:SS') created,
       o.name plan_name,
       DECODE(BITAND(o.flags, 1),   0, 'NO', 'YES') enabled,
       DECODE(BITAND(o.flags, 2),   0, 'NO', 'YES') accepted,
       DECODE(BITAND(o.flags, 4),   0, 'NO', 'YES') fixed,
       DECODE(BITAND(o.flags, 64),  0, 'YES', 'NO') reproduced,
       DECODE(BITAND(o.flags, 256), 0, 'NO', 'YES') adaptive,
       p.plan_id,
       TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) plan_hash_2, -- plan_hash_value ignoring transient object names (must be same than plan_id)
       TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash"]')) plan_hash, -- normal plan_hash_value
       TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_full"]')) plan_hash_full, -- adaptive plan (must be different than plan_hash_2 on loaded plans)
       a.description
  FROM sqlobj$plan p,
       sqlobj$ o,
       sqlobj$auxdata a,
       sql$text t
 WHERE p.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND p.id = 1
   AND p.signature = &&signature.
   AND p.other_xml IS NOT NULL
   AND o.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND o.signature = p.signature
   AND o.plan_id = p.plan_id
   AND a.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND a.signature = p.signature
   AND a.plan_id = p.plan_id
   AND t.signature = p.signature
 ORDER BY
       a.created,
       o.name
/
