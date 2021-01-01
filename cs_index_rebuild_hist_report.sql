----------------------------------------------------------------------------------------
--
-- File name:   cs_index_rebuild_hist_report.sql
--
-- Purpose:     Index Rebuild History (IOD_REPEATING_SPACE_MAINTENANCE log)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/25
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter range of dates, and Table when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_index_rebuild_hist_report.sql
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
DEF cs_script_name = 'cs_index_rebuild_hist_report';
DEF cs_hours_range_default = '24';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
ALTER SESSION SET container = CDB$ROOT;
--
COL owner FOR A30 TRUNC;
SELECT DISTINCT h.owner
  FROM &&cs_tools_schema..index_rebuild_hist h,
       cdb_users u
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', h.pdb_name) 
   AND (h.ddl_begin_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') OR
        h.ddl_end_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.'))
   AND u.con_id = h.con_id
   AND u.username = h.owner
   AND u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
 ORDER BY 1
/
PRO
PRO 3. Index Owner (opt):
DEF cs2_index_owner = '&3.';
UNDEF 3;
COL cs2_index_owner NEW_V cs2_index_owner NOPRI;
SELECT UPPER(TRIM('&&cs2_index_owner.')) cs2_index_owner FROM DUAL
/
--
COL index_name FOR A30 TRUNC;
SELECT DISTINCT h.index_name
  FROM &&cs_tools_schema..index_rebuild_hist h,
       cdb_users u
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', h.pdb_name)
   AND h.owner = COALESCE('&&cs2_index_owner.', h.owner)
   AND (h.ddl_begin_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') OR
        h.ddl_end_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.'))
   AND u.con_id = h.con_id
   AND u.username = h.owner
   AND u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
 ORDER BY 1
/
PRO
PRO 4. Index Name (opt):
DEF cs2_index_name = '&4.';
UNDEF 4;
COL cs2_index_name NEW_V cs2_index_name NOPRI;
SELECT UPPER(TRIM('&&cs2_index_name.')) cs2_index_name FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_index_owner." "&&cs2_index_name."
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO INDEX_OWNER  : "&&cs2_index_owner."
PRO INDEX_NAME   : "&&cs2_index_name."
--
COL ddl_begin_time FOR A19;
COL ddl_end_time FOR A19;
COL seconds FOR 999,990 HEA 'DDL|SECONDS';
COL pdb_name FOR A30 TRUNC;
COL owner FOR A30 TRUNC;
COL index_name FOR A30 TRUNC;
COL size_mbs_before FOR 999,990.0 HEA 'SIZE_MBs|BEFORE';
COL size_mbs_after FOR 999,990.0 HEA 'SIZE_MBs|AFTER';
COL savings FOR 999,990.0 HEA 'SAVINGS|MBs';
COL perc FOR 999,990.0 HEA 'SAVINGS|PERC%';
COL ddl_statement FOR A100 TRUNC;
COL error_message FOR A100 TRUNC;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF seconds size_mbs_before size_mbs_after savings ON REPORT;
--
SELECT TO_CHAR(h.ddl_begin_time, '&&cs_datetime_full_format.') AS ddl_begin_time,
       TO_CHAR(h.ddl_end_time, '&&cs_datetime_full_format.') AS ddl_end_time,
       ROUND((h.ddl_end_time - h.ddl_begin_time) * 24 * 3600) AS seconds,
       h.pdb_name,
       h.owner,
       h.index_name,
       h.size_mbs_before,
       h.size_mbs_after,
       (h.size_mbs_before - h.size_mbs_after) AS savings,
       ROUND(100 * (h.size_mbs_before - h.size_mbs_after) / NULLIF(h.size_mbs_before, 0), 1) AS perc,
       h.ddl_statement,
       h.error_message
  FROM &&cs_tools_schema..index_rebuild_hist h,
       cdb_users u
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', h.pdb_name)
   AND h.owner = COALESCE('&&cs2_index_owner.', h.owner)
   AND h.index_name = COALESCE('&&cs2_index_name.', h.index_name)
   AND (h.ddl_begin_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') OR
        h.ddl_end_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.'))
   AND u.con_id = h.con_id
   AND u.username = h.owner
   AND u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
 ORDER BY
       h.snap_time,
       h.ddl_begin_time
/
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_index_owner." "&&cs2_index_name."
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--