----------------------------------------------------------------------------------------
--
-- File name:   cs_latency_snapshot_extended.sql
--
-- Purpose:     Snapshot SQL latency (elapsed time over executions) - Extended
--
-- Author:      Carlos Sierra
--
-- Version:     2022/08/06
--
-- Usage:       Execute connected to PDB or CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_latency_snapshot_extended.sql
--
-- Notes:       Developed and tested on 19c
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_latency_snapshot_extended';
DEF cs_top_latency = '40';
DEF cs_top_load = '20';
DEF cs_ms_threshold_latency = '0.05';
DEF cs_aas_threshold_latency = '0.005';
DEF cs_aas_threshold_load = '0.05';
DEF cs_uncommon_col = 'PRINT';
DEF cs_default_snapshot_seconds = '15';
-- DEF cs_execs_delta_h = '&&cs_last_snap_mins. mins';
DEF cs_execs_delta_h = '';
-- -- [{AUTO}|MANUAL]
-- DEF cs_snap_type = 'AUTO';
-- -- [{-666}|sid]
-- DEF cs_sid = '-666';
--
DEF cs_snap_type = 'MANUAL';
COL cs_sid NEW_V cs_sid NOPRI;
SELECT SYS_CONTEXT('USERENV', 'SID') AS cs_sid FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
PRO
PRO 1. Snapshot Interval Seconds [{&&cs_default_snapshot_seconds.}|5-900]
DEF cs_snapshot_seconds = '&1.';
UNDEF 1;
COL cs_snapshot_seconds NEW_V cs_snapshot_seconds NOPRI;
SELECT CASE WHEN TRUNC(TO_NUMBER('&&cs_snapshot_seconds.')) BETWEEN 5 AND 900 THEN TO_CHAR(TRUNC(TO_NUMBER('&&cs_snapshot_seconds.'))) ELSE '&&cs_default_snapshot_seconds.' END AS cs_snapshot_seconds FROM DUAL
/
DEF cs_execs_delta_h = '&&cs_snapshot_seconds. secs';
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
@@cs_internal/cs_latency_internal_snapshot.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_snapshot_seconds."
@@cs_internal/cs_spool_id.sql
--
PRO SECONDS      : "&&cs_snapshot_seconds." [{&&cs_default_snapshot_seconds.}|5-900]
PRO TIME_FROM    : "&&cs_sample_time_from."  
PRO TIME_TO      : "&&cs_sample_time_to." 
--
@@cs_internal/cs_latency_internal_cols.sql
@@cs_internal/cs_latency_internal_query_5.sql
@@cs_internal/cs_latency_internal_foot.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_snapshot_seconds."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--