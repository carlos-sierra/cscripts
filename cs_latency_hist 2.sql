----------------------------------------------------------------------------------------
--
-- File name:   lah.sql | lh.sql | cs_latency_hist.sql
--
-- Purpose:     Current and Historical SQL latency (cpu time over executions)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/05/24
--
-- Usage:       Execute connected to PDB or CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_latency_hist.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_latency_hist';
DEF cs_script_acronym = 'lah.sql | lh.sql | ';
DEF cs_top = '20';
@@cs_internal/cs_latency_hist_internal_1.sql
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_latency_hist_internal_2.sql
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
