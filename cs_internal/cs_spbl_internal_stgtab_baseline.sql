COL created FOR A26 HEA 'Created';
COL plan_name FOR A30 HEA 'Plan Name';
COL origin FOR A29 HEA 'Origin';
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
--
PRO
PRO SQL PLAN BASELINES ON STAGING TABLE - LIST (&&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(created, '&&cs_timestamp_full_format.') AS created, 
       TO_CHAR(last_modified, '&&cs_datetime_full_format.') AS last_modified, 
       TO_CHAR(last_executed, '&&cs_datetime_full_format.') AS last_executed, 
       obj_name AS plan_name,  
       DECODE(BITAND(status, 1),   0, 'NO', 'YES') AS enabled,
       DECODE(BITAND(status, 2),   0, 'NO', 'YES') AS accepted,
       DECODE(BITAND(status, 4),   0, 'NO', 'YES') AS fixed,
       DECODE(BITAND(status, 64),  0, 'YES', 'NO') AS reproduced,
       DECODE(BITAND(status, 128), 0, 'NO', 'YES') AS autopurge,
       DECODE(BITAND(status, 256), 0, 'NO', 'YES') AS adaptive,
       origin, 
       description
  FROM &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline
 WHERE signature = :cs_signature
   AND other_xml IS NOT NULL 
 ORDER BY 
       created, last_modified, last_executed, obj_name
/
--
PRO
PRO SQL PLAN BASELINES ON STAGING TABLE - PERFORMANCE (&&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(created, '&&cs_timestamp_full_format.') AS created, 
       TO_CHAR(last_modified, '&&cs_datetime_full_format.') AS last_modified, 
       obj_name AS plan_name,  
       DECODE(BITAND(status, 1),   0, 'NO', 'YES') AS enabled,
       DECODE(BITAND(status, 2),   0, 'NO', 'YES') AS accepted,
       DECODE(BITAND(status, 4),   0, 'NO', 'YES') AS fixed,
       DECODE(BITAND(status, 64),  0, 'YES', 'NO') AS reproduced,
       DECODE(BITAND(status, 128), 0, 'NO', 'YES') AS autopurge,
       DECODE(BITAND(status, 256), 0, 'NO', 'YES') AS adaptive,
       origin, 
       elapsed_time/GREATEST(executions,1)/1e3 AS et_per_exec_ms,
       cpu_time/GREATEST(executions,1)/1e3 AS cpu_per_exec_ms,
       buffer_gets/GREATEST(executions,1) AS buffers_per_exec,
       disk_reads/GREATEST(executions,1) AS reads_per_exec,
       rows_processed/GREATEST(executions,1) AS rows_per_exec,
       executions,
       elapsed_time,
       cpu_time,
       buffer_gets,
       disk_reads,
       rows_processed
  FROM &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline
 WHERE signature = :cs_signature
   AND other_xml IS NOT NULL 
 ORDER BY 
       created, last_modified, last_executed, obj_name
/
--
PRO
PRO SQL PLAN BASELINES ON STAGING TABLE - IDS (&&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- only works from PDB. do not use CONTAINERS(table_name) since it causes ORA-00600: internal error code, arguments: [kkdolci1], [], [], [], [], [], [],
SELECT TO_CHAR(created, '&&cs_timestamp_full_format.') AS created, 
       TO_CHAR(last_modified, '&&cs_datetime_full_format.') AS last_modified, 
       obj_name AS plan_name,  
       DECODE(BITAND(status, 1),   0, 'NO', 'YES') AS enabled,
       DECODE(BITAND(status, 2),   0, 'NO', 'YES') AS accepted,
       DECODE(BITAND(status, 4),   0, 'NO', 'YES') AS fixed,
       DECODE(BITAND(status, 64),  0, 'YES', 'NO') AS reproduced,
       DECODE(BITAND(status, 128), 0, 'NO', 'YES') AS autopurge,
       DECODE(BITAND(status, 256), 0, 'NO', 'YES') AS adaptive,
       origin, 
       TO_NUMBER(extractvalue(xmltype(other_xml),'/*/info[@type = "plan_hash"]')) plan_hash, -- normal plan_hash_value
       TO_NUMBER(extractvalue(xmltype(other_xml),'/*/info[@type = "plan_hash_2"]')) plan_hash_2, -- plan_hash_value ignoring transient object names (must be same than plan_id for a baseline to be used)
       plan_id,
       TO_NUMBER(extractvalue(xmltype(other_xml),'/*/info[@type = "plan_hash_full"]')) plan_hash_full, -- adaptive plan (must be different than plan_hash_2 on loaded plans) 
       TO_CHAR(timestamp, '&&cs_datetime_full_format.') timestamp,
       description
  FROM &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline
 WHERE signature = :cs_signature
   AND other_xml IS NOT NULL 
 ORDER BY 
       created, last_modified, last_executed, obj_name
/
--