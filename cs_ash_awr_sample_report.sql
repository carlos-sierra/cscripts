----------------------------------------------------------------------------------------
--
-- File name:   ah.sql | cs_ash_awr_sample_report.sql
--
-- Purpose:     ASH Samples from AWR
--
-- Author:      Carlos Sierra
--
-- Version:     2022/05/25
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter optional parameters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_ash_awr_sample_report.sql
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
SET PAGES 5000;
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_ash_awr_sample_report';
DEF cs_script_acronym = 'ah.sql | ';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF cs_hours_range_default = '24';
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO 3. Machine (opt): 
DEF cs2_machine = '&3.';
UNDEF 3;
--
PRO
PRO 4. SQL_ID (opt): 
DEF cs_sql_id = '&4.';
UNDEF 4;
--
PRO
PRO 5. SID,SERIAL (opt):
DEF cs_sid_serial = '&5.';
UNDEF 5;
--
PRO
PRO 6. Only LOB DEDUP TX 4 waiting sessions [{N}|Y]:
DEF cs_only_dedup = '&6.';
UNDEF 6;
COL cs_only_dedup NEW_V cs_only_dedup NOPRI;
SELECT CASE WHEN SUBSTR(TRIM(UPPER('&&cs_only_dedup.')), 1, 1) IN ('N', 'Y') THEN SUBSTR(TRIM(UPPER('&&cs_only_dedup.')), 1, 1) ELSE 'N' END AS cs_only_dedup FROM DUAL
/
--
PRO
PRO 7. Include PL/SQL Library Entry Point [{N}|Y]:
DEF cs_pl_sql = '&7.';
UNDEF 7;
COL cs_pl_sql NEW_V cs_pl_sql NOPRI;
COL cs_pl_sql_pri NEW_V cs_pl_sql_pri NOPRI;
SELECT CASE WHEN SUBSTR(TRIM(UPPER('&&cs_pl_sql.')), 1, 1) IN ('N', 'Y') THEN SUBSTR(TRIM(UPPER('&&cs_pl_sql.')), 1, 1) ELSE 'N' END AS cs_pl_sql, CASE SUBSTR(TRIM(UPPER('&&cs_pl_sql.')), 1, 1) WHEN 'Y' THEN 'PRI' ELSE 'NOPRI' END AS cs_pl_sql_pri FROM DUAL
/
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_machine." "&&cs_sql_id." "&&cs_sid_serial." "&&cs_only_dedup." "&&cs_pl_sql."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO MACHINE      : "&&cs2_machine."
PRO SQL_ID       : "&&cs_sql_id."
PRO SID,SERIAL   : "&&cs_sid_serial."
PRO ONLY_DEDUP   : "&&cs_only_dedup."
PRO INCL_PL_SQL  : "&&cs_pl_sql."
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
DEF times_cpu_cores = '1';
DEF include_hist = 'Y';
DEF include_mem = 'N';
PRO
PRO Sum of Active Sessions per sampled time (spikes greater than &&cs_num_cpu_cores. CPU Cores)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET SERVEROUT ON;
@@cs_internal/cs_active_sessions_peaks_internal_v5.sql
@@cs_internal/cs_active_sessions_peaks_internal_v6.sql
--
DEF times_cpu_cores = '0';
DEF include_hist = 'Y';
DEF include_mem = 'N';
PRO
PRO Sum of Active Sessions per sampled time 
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET SERVEROUT ON;
@@cs_internal/cs_active_sessions_peaks_internal_v5.sql
--
DEF times_cpu_cores = '1';
DEF include_hist = 'Y';
DEF include_mem = 'N';
-- @@cs_internal/cs_ash_block_chains.sql
--
--DEF ash_view = 'v$active_session_history';
--DEF ash_additional_predicate = '';
DEF ash_view = 'dba_hist_active_sess_history';
DEF ash_additional_predicate = ' AND h.dbid = &&cs_dbid. AND h.instance_number = &&cs_instance_number. AND h.snap_id BETWEEN &&cs_snap_id_from. AND &&cs_snap_id_to. ';
--
@@cs_internal/cs_ash_sample_detail.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_machine." "&&cs_sql_id." "&&cs_sid_serial." "&&cs_only_dedup." "&&cs_pl_sql."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--