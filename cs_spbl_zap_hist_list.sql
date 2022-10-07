----------------------------------------------------------------------------------------
--
-- File name:   zl.sql | cs_spbl_zap_hist_list.sql
--
-- Purpose:     SQL Plan Baseline - Zapper History List
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/21
--
-- Usage:       Execute connected to PDB.
--
--              Enter range of dates and SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_zap_hist_list.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_spbl_zap_hist_list';
DEF cs_script_acronym = 'zl.sql | ';
--
DEF cs_hours_range_default = '168';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--   
PRO 3. SQL_ID: (opt)
DEF cs_sql_id = '&3.';
UNDEF 3;
--
PRO
PRO 4. Include NULL actions?: [{N}|Y] 
DEF cs_null = '&4.';
UNDEF 4;
COL cs_null NEW_V cs_null NOPRI;
SELECT NVL(UPPER(TRIM('&&cs_null.')),'N') AS cs_null FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&cs_null." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SQLHV        : &&cs_sqlid.
PRO SIGNATURE    : &&cs_signature.
PRO INCLUDE_NULL : "&&cs_null." [{N}|Y]
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
PRO
PRO ZAPPER-19 ENTRIES (&&cs_stgtab_owner..zapper_log)
PRO ~~~~~~~~~~~~~~~~~
PRO
@@cs_internal/cs_zapper_log_entries.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&cs_null." 
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--