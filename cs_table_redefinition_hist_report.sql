----------------------------------------------------------------------------------------
--
-- File name:   cs_table_redefinition_hist_report.sql
--
-- Purpose:     Table Redefinition History Report (IOD_REPEATING_SPACE_MAINTENANCE log)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/10/18
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_table_redefinition_hist_report.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_table_redefinition_hist_report';
DEF cs_hours_range_default = '48';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
SELECT DISTINCT owner table_owner
  FROM &&cs_tools_schema..table_redefinition_hist
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
 ORDER BY 1
/
PRO
PRO 3. Table Owner (opt):
DEF table_owner = '&3.';
UNDEF 3;
--
SELECT DISTINCT table_name
  FROM &&cs_tools_schema..table_redefinition_hist
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
   AND owner = NVL(UPPER(TRIM('&&table_owner.')), owner)
 ORDER BY 1
/
PRO
PRO 4. Table Name (opt):
DEF table_name = '&4.';
UNDEF 4;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&table_owner." "&&table_name." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO TIME_TO      : &&cs_sample_time_to. (&&cs_snap_id_to.)
PRO TABLE_OWNER  : "&&table_owner." 
PRO TABLE_NAME   : "&&table_name."
--
COL snap_time FOR A19 HEA 'CAPTURE_TIME';
COL ddl_begin_time FOR A19;
COL ddl_end_time FOR A19;
COL ddl_secs FOR 999,990;
COL pdb_name FOR A35;
COL owner FOR A30;
COL table_name FOR A30;
COL total_saved_percent FOR 999,990.0 HEA 'Total|Saved|Percent';
COL total_size_mbs_before FOR 999,990 HEA 'Total|Size (MBs)|Before';
COL total_size_mbs_after FOR 999,990 HEA 'Total|Size (MBs)|After';
COL table_saved_percent FOR 999,990.0 HEA 'Table|Saved|Percent';
COL table_size_mbs_before FOR 999,990 HEA 'Table|Size (MBs)|Before';
COL table_size_mbs_after FOR 999,990 HEA 'Table|Size (MBs)|After';
COL indexes_saved_percent FOR 999,990.0 HEA 'Index(es)|Saved|Percent';
COL all_index_size_mbs_before FOR 999,990 HEA 'Index(es)|Size (MBs)|Before';
COL all_index_size_mbs_after FOR 999,990 HEA 'Index(es)|Size (MBs)|After';
COL lobs_saved_percent FOR 999,990.0 HEA 'Lob(s)|Saved|Percent';
COL all_lobs_size_mbs_before FOR 999,990 HEA 'Lob(s)|Size (MBs)|Before';
COL all_lobs_size_mbs_after FOR 999,990 HEA 'Lob(s)|Size (MBs)|After';
COL error_message FOR A120 HEA 'Error Message';
--
WITH
hist AS (
SELECT snap_time,
       ddl_begin_time,
       ddl_end_time,
       pdb_name,
       con_id,
       owner,
       table_name,
       NVL(table_size_mbs_before, 0) + NVL(all_index_size_mbs_before, 0) + NVL(all_lobs_size_mbs_before, 0) total_size_mbs_before,       
       table_size_mbs_before,
       all_index_size_mbs_before,
       all_lobs_size_mbs_before,
       NVL(table_size_mbs_after, 0) + NVL(all_index_size_mbs_after, 0) + NVL(all_lobs_size_mbs_after, 0) total_size_mbs_after,       
       table_size_mbs_after,
       all_index_size_mbs_after,
       all_lobs_size_mbs_after,
       error_message
  FROM &&cs_tools_schema..table_redefinition_hist
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
   AND snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND owner = NVL(UPPER(TRIM('&&table_owner.')), owner)
   AND table_name = NVL(UPPER(TRIM('&&table_name.')), table_name)
)
SELECT snap_time,
       ddl_begin_time,
       ddl_end_time,
       (ddl_end_time - ddl_begin_time) * 24 * 3600 ddl_secs,
       pdb_name||'('||con_id||')' pdb_name,
       owner,
       table_name,
       100 * (total_size_mbs_before - total_size_mbs_after) / NULLIF(total_size_mbs_before, 0) total_saved_percent,
       total_size_mbs_before,
       total_size_mbs_after,
       100 * (table_size_mbs_before - table_size_mbs_after) / NULLIF(table_size_mbs_before, 0) table_saved_percent,
       table_size_mbs_before,
       table_size_mbs_after,
       100 * (all_index_size_mbs_before - all_index_size_mbs_after) / NULLIF(all_index_size_mbs_before, 0) indexes_saved_percent,
       all_index_size_mbs_before,
       all_index_size_mbs_after,
       100 * (all_lobs_size_mbs_before - all_lobs_size_mbs_after) / NULLIF(all_lobs_size_mbs_before, 0) lobs_saved_percent,
       all_lobs_size_mbs_before,
       all_lobs_size_mbs_after,
       error_message
  FROM hist
 ORDER BY
       snap_time,
       ddl_begin_time
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&table_owner." "&&table_name." 
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--