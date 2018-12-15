----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_zap_hist_report.sql
--
-- Purpose:     SQL Plan Baseline - Zapper History Report
--
-- Author:      Carlos Sierra
--
-- Version:     2018/09/19
--
-- Usage:       Execute connected to PDB.
--
--              Enter range of dates and SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_zap_hist_report.sql
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
DEF cs_script_name = 'cs_spbl_zap_hist_report';
--
COL cs2_pdb_name NEW_V cs2_pdb_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') cs2_pdb_name FROM DUAL;
ALTER SESSION SET container = CDB$ROOT;
--
DEF cs_hours_range_default = '24';
@@cs_internal/cs_sample_time_from_and_to.sql
--
PRO 3. SQL_ID: 
DEF cs_sql_id = '&3.';
--
@@cs_internal/cs_signature.sql
--
COL snap_id FOR 99999 HEA 'RUNID';
COL snap_time HEA 'ZAPPER_TIME';
COL zapper_aggressiveness FOR 99999 HEA 'LEVEL';
COL action_loaded HEA 'LOADED';
COL action_disabled HEA 'DISABLED';
COL action_fixed HEA 'FIXED';
COL action_null HEA 'NULL';
--
SELECT snap_id,
       zapper_aggressiveness,
       MIN(snap_time) zapper_time_from,
       MAX(snap_time) zapper_time_to,
       SUM(CASE zapper_action WHEN 'LOADED' THEN 1 ELSE 0 END) action_loaded,
       SUM(CASE zapper_action WHEN 'DISABLED' THEN 1 ELSE 0 END) action_disabled,
       SUM(CASE zapper_action WHEN 'FIXED' THEN 1 ELSE 0 END) action_fixed,
       SUM(CASE zapper_action WHEN 'NULL' THEN 1 ELSE 0 END) action_null,
       COUNT(*) total
  FROM c##iod.sql_plan_baseline_hist
 WHERE 1 = 1
   AND '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
   AND snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND sql_id = '&&cs_sql_id.'
 GROUP BY
       snap_id,
       zapper_aggressiveness
 ORDER BY
       snap_id,
       zapper_aggressiveness
/
PRO
PRO 4. RUNID (opt):
DEF cs_snap_id = '&4.';
--
SELECT '&&cs_file_prefix._&&cs_sql_id._&&cs_snap_id._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&cs_snap_id."
@@cs_internal/cs_spool_id.sql
--
PRO TIME_FROM    : &&cs_sample_time_from. 
PRO TIME_TO      : &&cs_sample_time_to. 
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO RUN_ID       : &&cs_snap_id.
PRO
--
SELECT snap_id,
       zapper_aggressiveness,
       MIN(snap_time) zapper_time_from,
       MAX(snap_time) zapper_time_to,
       SUM(CASE zapper_action WHEN 'LOADED' THEN 1 ELSE 0 END) action_loaded,
       SUM(CASE zapper_action WHEN 'DISABLED' THEN 1 ELSE 0 END) action_disabled,
       SUM(CASE zapper_action WHEN 'FIXED' THEN 1 ELSE 0 END) action_fixed,
       SUM(CASE zapper_action WHEN 'NULL' THEN 1 ELSE 0 END) action_null,
       COUNT(*) total
  FROM c##iod.sql_plan_baseline_hist
 WHERE 1 = 1
   AND '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
   AND snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND sql_id = '&&cs_sql_id.'
 GROUP BY
       snap_id,
       zapper_aggressiveness
 ORDER BY
       snap_id,
       zapper_aggressiveness
/
--
PRO
SET HEA OFF PAGES 0 RECSEP EA;
SELECT zapper_report
  FROM c##iod.sql_plan_baseline_hist
 WHERE 1 = 1
   AND '&&cs2_pdb_name.' IN (pdb_name, 'CDB$ROOT')
   AND snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND sql_id = '&&cs_sql_id.'
   AND (snap_id = TO_NUMBER('&&cs_snap_id.') OR '&&cs_snap_id.' IS NULL)
 ORDER BY
       snap_id,
       snap_time
/
SET HEA ON PAGES 100 RECSEP WR;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&cs_snap_id."
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs2_pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--