----------------------------------------------------------------------------------------
--
-- File name:   cs_LGWR_report_iod.sql
--
-- Purpose:     Log Writer LGWR Slow Writes Duration Report - from historical IOD Table
--
-- Author:      Carlos Sierra
--
-- Version:     2022/10/03
--
-- Usage:       Execute connected to PDB or CDB
--
--              Enter range of dates when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_LGWR_report_iod.sql
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
DEF cs_script_name = 'cs_LGWR_report_iod';
DEF cs_hours_range_default = '168';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO 
PRO Log Writer LGWR Slow Writes Duration
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COL timestamp FOR A23 HEA 'Log Write|End|Timestamp' TRUNC;
COL write_duration_ms FOR 999,990 HEA 'Write|Duration|(ms)';
COL payload_size_kb FOR 999,999,990 HEA 'Payload|Size|KBs';
COL kbps FOR 999,999,990 HEA 'KBs|per|Sec';
COL host_name FOR A64 HEA 'Host|Name' TRUNC;
--
SELECT timestamp,
       write_duration_ms,
       payload_size_kb,
       ROUND(payload_size_kb / (write_duration_ms / POWER(10,3))) AS kbps,
       host_name
  FROM &&cs_tools_schema..iod_lgwr_t
 WHERE timestamp >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.')
   AND timestamp <= TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 ORDER BY
       timestamp
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--