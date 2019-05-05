----------------------------------------------------------------------------------------
--
-- File name:   cs_index_rebuild_hist_report.sql
--
-- Purpose:     Index Rebuild History Report
--
-- Author:      Carlos Sierra
--
-- Version:     2018/10/24
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_index_rebuild_hist_report.sql
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
DEF cs_script_name = 'cs_index_rebuild_hist_report';
DEF cs_hours_range_default = '48';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
ALTER SESSION SET container = CDB$ROOT;
--
SELECT DISTINCT owner index_owner
  FROM c##iod.index_rebuild_hist
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
 ORDER BY 1
/
PRO
PRO 3. Index Owner (opt):
DEF index_owner = '&3.';
--
SELECT DISTINCT index_name
  FROM c##iod.index_rebuild_hist
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
   AND owner = NVL(UPPER(TRIM('&&index_owner.')), owner)
 ORDER BY 1
/
PRO
PRO 4. Index Name (opt):
DEF index_name = '&4.';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&index_owner." "&&index_name." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO INDEX_OWNER  : "&&index_owner." 
PRO INDEX_NAME   : "&&index_name."
--
COL snap_time FOR A19 HEA 'CAPTURE_TIME';
COL ddl_begin_time FOR A19;
COL ddl_end_time FOR A19;
COL ddl_secs FOR 999,990;
COL pdb_name FOR A35;
COL owner FOR A30;
COL index_name FOR A30;
COL saved_percent FOR 999,990.0 HEA 'Saved|Percent';
COL size_mbs_before FOR 999,990 HEA 'Size (MBs)|Before';
COL size_mbs_after FOR 999,990 HEA 'Size (MBs)|After';
--
WITH
hist AS (
SELECT snap_time,
       ddl_begin_time,
       ddl_end_time,
       pdb_name,
       con_id,
       owner,
       index_name,
       size_mbs_before,
       size_mbs_after
  FROM c##iod.index_rebuild_hist
 WHERE '&&cs_con_name.' IN (pdb_name, 'CDB$ROOT')
   AND snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND owner = NVL(UPPER(TRIM('&&index_owner.')), owner)
   AND index_name = NVL(UPPER(TRIM('&&index_name.')), index_name)
)
SELECT snap_time,
       ddl_begin_time,
       ddl_end_time,
       (ddl_end_time - ddl_begin_time) * 24 * 3600 ddl_secs,
       pdb_name||'('||con_id||')' pdb_name,
       owner,
       index_name,
       100 * (size_mbs_before - size_mbs_after) / NULLIF(size_mbs_before, 0) saved_percent,
       size_mbs_before,
       size_mbs_after
  FROM hist
 ORDER BY
       snap_time,
       ddl_begin_time
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&index_owner." "&&index_name." 
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--