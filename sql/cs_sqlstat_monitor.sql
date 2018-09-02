----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlstat_monitor.sql
--
-- Purpose:     SQL with Performance Regression based on V$SQLSTATS
--
-- Author:      Carlos Sierra
--
-- Version:     2018/07/28
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlstat_monitor.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
DEF threshold = '2';
DEF min_aas_db = '0.002';
--
DEF awr_minutes = '0.016666666666667';
DEF instance_hours = '1';
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sqlstat_monitor';
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
PRO THRESHOLD    : &&threshold.x
PRO MIN_AAS_DB   : &&min_aas_db.
PRO INST_MINIMUM : &&instance_hours. (hours)
PRO AWR_MINIMUM  : &&awr_minutes. (minutes)
PRO INST_STARTUP : &&cs_startup_time. (&&cs_startup_days. days ago)
PRO LAST_AWR_SNAP: &&cs_max_snap_end_time. (&&cs_last_snap_mins. mins ago)
--
COL pdb_name FOR A30 HEA 'PDB Name';
COL username FOR A30 HEA 'User Name';
COL sql_id FOR A13;
COL plan_hash_value FOR 9999999999 HEA 'Plan|Hash|Value';
COL avg_et_ms_inst FOR 999,990.000 HEA 'Avg ET|(ms)|Inst';
COL avg_et_ms_awr FOR 999,990.000 HEA 'Avg ET|(ms)|AWR';
COL et_sec_awr FOR 990.0 HEA 'DB|(secs)|AWR';
COL aas_db FOR 990.000 HEA 'AAS|DB';
COL avg_cpu_ms_inst FOR 999,990.000 HEA 'Avg CPU|(ms)|Inst';
COL avg_cpu_ms_awr FOR 999,990.000 HEA 'Avg CPU|(ms)|AWR';
COL cpu_sec_awr FOR 990.0 HEA 'CPU|(secs)|AWR';
COL aas_cpu FOR 990.000 HEA 'AAS|CPU';
COL avg_bg_inst FOR 999,999,990 HEA 'Avg Buffer|Gets|Inst';
COL avg_bg_awr FOR 999,999,990 HEA 'Avg Buffer|Gets|AWR';
COL flag_et FOR 9999 HEA 'Flag|ET';
COL flag_cpu FOR 9999 HEA 'Flag|CPU';
COL flag_bg FOR 9999 HEA 'Flag|BG';
COL et_regr FOR A8 HEA ' ET Regr';
COL cpu_regr FOR A8 HEA 'CPU Regr';
COL bg_regr FOR A8 HEA ' BG Regr';
COL sql_text_100 FOR A100 HEA 'SQL Text';
--
WITH 
regressed_sql AS (
SELECT c.name pdb_name,
       s.con_id,
       s.sql_id,
       s.plan_hash_value,
       s.elapsed_time/1e3/s.executions avg_et_ms_inst,
       s.delta_elapsed_time/1e3/GREATEST(s.delta_execution_count,1) avg_et_ms_awr,
       s.delta_elapsed_time/1e6 et_sec_awr,
       s.cpu_time/1e3/s.executions avg_cpu_ms_inst,
       s.delta_cpu_time/1e3/GREATEST(s.delta_execution_count,1) avg_cpu_ms_awr,
       s.delta_cpu_time/1e6 cpu_sec_awr,
       s.buffer_gets/s.executions avg_bg_inst,
       s.delta_buffer_gets/GREATEST(s.delta_execution_count,1) avg_bg_awr,
       CASE WHEN s.delta_elapsed_time/GREATEST(s.delta_execution_count,1) > TO_NUMBER('&&threshold.')*s.elapsed_time/s.executions THEN 1 ELSE 0 END flag_et,
       CASE WHEN s.delta_cpu_time/GREATEST(s.delta_execution_count,1) > TO_NUMBER('&&threshold.')*s.cpu_time/s.executions THEN 1 ELSE 0 END flag_cpu,
       CASE WHEN s.delta_buffer_gets/GREATEST(s.delta_execution_count,1) > TO_NUMBER('&&threshold.')*s.buffer_gets/s.executions THEN 1 ELSE 0 END flag_bg,
       s.sql_text,
       (SELECT q.parsing_schema_id FROM v$sql q WHERE q.con_id = s.con_id AND q.sql_id = s.sql_id AND q.plan_hash_value = s.plan_hash_value /*AND q.parsing_schema_id <> 0*/ ORDER BY q.elapsed_time DESC FETCH FIRST 1 ROW ONLY) parsing_schema_id
  FROM v$sqlstats s,
       v$containers c
 WHERE s.executions > 0
   AND s.delta_elapsed_time/1e3/GREATEST(s.delta_execution_count,1) > 1 -- ms
   AND s.last_active_time > SYSDATE - 15/24/60 -- active during last 15 mins
   AND s.sql_text NOT LIKE '/* SQL Analyze(%'
   AND UPPER(s.sql_text) NOT LIKE 'BEGIN%'
   AND (   s.delta_elapsed_time/GREATEST(s.delta_execution_count,1) > TO_NUMBER('&&threshold.')*s.elapsed_time/s.executions
         OR s.delta_cpu_time/GREATEST(s.delta_execution_count,1) > TO_NUMBER('&&threshold.')*s.cpu_time/s.executions
         OR s.delta_buffer_gets/GREATEST(s.delta_execution_count,1) > TO_NUMBER('&&threshold.')*s.buffer_gets/s.executions
       )
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
),
appl_users AS (
SELECT con_id,
       user_id,
       username
  FROM cdb_users
 WHERE oracle_maintained = 'N'
)
SELECT s.pdb_name,
       u.username,
       s.sql_id,
       s.plan_hash_value,
       s.avg_et_ms_inst,
       s.avg_et_ms_awr,
       s.et_sec_awr,
       s.et_sec_awr/60/TO_NUMBER('&&cs_last_snap_mins.') aas_db,
       s.avg_cpu_ms_inst,
       s.avg_cpu_ms_awr,
       s.cpu_sec_awr,
       s.cpu_sec_awr/60/TO_NUMBER('&&cs_last_snap_mins.') aas_cpu,
       s.avg_bg_inst,
       s.avg_bg_awr,
       --s.flag_et,
       --s.flag_cpu,
       --s.flag_bg,
       CASE WHEN s.flag_et = 1 THEN LPAD(TRIM(TO_CHAR(s.avg_et_ms_awr/s.avg_et_ms_inst,'99,990'))||'x',8) END et_regr,
       CASE WHEN s.flag_cpu = 1 THEN LPAD(TRIM(TO_CHAR(s.avg_cpu_ms_awr/s.avg_cpu_ms_inst,'99,990'))||'x',8) END cpu_regr,
       CASE WHEN s.flag_bg = 1 THEN LPAD(TRIM(TO_CHAR(s.avg_bg_awr/s.avg_bg_inst,'99,990'))||'x',8) END bg_regr,
       --SUBSTR(s.sql_text, 1, 100) sql_text_100
       SUBSTR(CASE WHEN s.sql_text LIKE '/*'||CHR(37) THEN SUBSTR(s.sql_text, 1, INSTR(s.sql_text, '*/') + 1) ELSE s.sql_text END, 1, 100) sql_text_100
  FROM regressed_sql s,
       appl_users u
 WHERE (s.flag_et + s.flag_cpu + s.flag_bg) >= 1
   AND s.et_sec_awr/60/TO_NUMBER('&&cs_last_snap_mins.') > TO_NUMBER('&&min_aas_db.')
   AND TO_NUMBER('&&cs_last_snap_mins.') > TO_NUMBER('&&awr_minutes.')
   AND TO_NUMBER('&&cs_startup_days.')/24 > TO_NUMBER('&&instance_hours.')
   AND u.con_id = s.con_id
   AND u.user_id = s.parsing_schema_id
/
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--

 
