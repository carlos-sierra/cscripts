----------------------------------------------------------------------------------------
--
-- File name:   la.sql | l.sql | cs_latency.sql
--
-- Purpose:     Current SQL latency (elapsed time over executions)
--
-- Author:      Carlos Sierra
--
-- Version:     2022/02/20
--
-- Usage:       Execute connected to PDB or CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_latency.sql
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
DEF cs_script_name = 'cs_latency';
DEF cs_script_acronym = 'la.sql | l.sql | ';
DEF cs_top_latency = '20';
DEF cs_top_load = '10';
DEF cs_ms_threshold_latency = '0.05';
DEF cs_aas_threshold_latency = '0.005';
DEF cs_aas_threshold_load = '0.05';
DEF cs_uncommon_col = 'NOPRINT';
DEF cs_execs_delta_h = '&&cs_last_snap_mins. mins';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_latency_internal_cols.sql
@@cs_internal/cs_latency_internal_query_1.sql
@@cs_internal/cs_latency_internal_foot.sql
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
