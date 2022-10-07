----------------------------------------------------------------------------------------
--
-- File name:   lr.sql | cs_latency_range.sql
--
-- Purpose:     SQL latency for a time range (elapsed time over executions) (AWR) - 15m Granularity
--
-- Author:      Carlos Sierra
--
-- Version:     2022/08/06
--
-- Usage:       Execute connected to PDB or CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_latency_range.sql
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
DEF cs_script_name = 'cs_latency_range';
DEF cs_script_acronym = 'lr.sql | ';
DEF cs_hours_range_default = '12';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
DEF cs_top_latency = '20';
DEF cs_top_load = '10';
DEF cs_ms_threshold_latency = '0.05';
DEF cs_aas_threshold_latency = '0.005';
DEF cs_aas_threshold_load = '0.05';
DEF cs_uncommon_col = 'NOPRINT';
DEF cs_execs_delta_h = '&&cs_from_to_seconds. secs';
-- DEF cs_execs_delta_h = '';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
-- @@cs_internal/&&cs_set_container_to_cdb_root.
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
@@cs_internal/cs_latency_internal_cols.sql
@@cs_internal/cs_latency_internal_query_4.sql
@@cs_internal/cs_latency_internal_foot.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
--
@@cs_internal/cs_spool_tail.sql
--
-- @@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--