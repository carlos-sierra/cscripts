----------------------------------------------------------------------------------------
--
-- File name:   cs_ash_awr_peaks_report.sql
--
-- Purpose:     ASH Peaks Report from AWR
--
-- Author:      Carlos Sierra
--
-- Version:     2022/05/25
--
-- Usage:       Execute connected to CDB or PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_ash_awr_peaks_report.sql
--
-- Notes:       Developed and tested on 19c.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_ash_awr_peaks_report';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF cs_hours_range_default = '24';
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO To report on Active Sessions over 1x the number of CPU Cores, then pass "1" (default) as Threshold value below
PRO
PRO 3. Threshold: [{1}|0-10] 
DEF times_cpu_cores = '&3.';
UNDEF 3;
COL times_cpu_cores NEW_V times_cpu_cores NOPRI;
SELECT CASE WHEN TO_NUMBER(REPLACE(UPPER('&&times_cpu_cores.'), 'X')) BETWEEN 0 AND 10 THEN REPLACE(UPPER('&&times_cpu_cores.'), 'X') ELSE '1' END AS times_cpu_cores FROM DUAL
/
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&times_cpu_cores."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO THRESHOLD    : "&&times_cpu_cores.x NUM_CPU_CORES"
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
-- DEF times_cpu_cores = '1';
DEF include_hist = 'Y';
DEF include_mem = 'N';
PRO
PRO Sum of Active Sessions per sampled time (when greater than &&times_cpu_cores.x CPU Cores)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET SERVEROUT ON;
@@cs_internal/cs_active_sessions_peaks_internal_v5.sql
@@cs_internal/cs_active_sessions_peaks_internal_v6.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&times_cpu_cores."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--