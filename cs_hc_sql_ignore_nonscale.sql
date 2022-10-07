----------------------------------------------------------------------------------------
--
-- File name:   cs_hc_sql_ignore_nonscale.sql
--
-- Purpose:     Add SQL_ID to NONSCALE exclusion list (HC SQL to ignore such SQL_ID)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/11/22
--
-- Usage:       Connecting into PDB or CDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_hc_sql_ignore_nonscale.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
--@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_hc_sql_ignore_nonscale';
--
COL def_ms_per_exec_threshold NEW_V def_ms_per_exec_threshold NOPRI;
COL def_aas_tot_threshold NEW_V def_aas_tot_threshold NOPRI;
SELECT TO_CHAR(ms_per_exec_threshold) AS def_ms_per_exec_threshold, TO_CHAR(aas_tot_threshold, '990.0') AS def_aas_tot_threshold FROM &&cs_tools_schema..non_scalable_plan_config
/
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
PRO
PRO To exclude a SQL_ID from NONSCALE HC, both Thresholds - Milliseconds per Execution and Average Active Sessions on DB Time should exceed threshold below.
PRO
PRO 2. Milliseconds per Execution Threshold: [{&&def_ms_per_exec_threshold.}]
DEF cs_ms_per_exec_threshold = '&2.';
UNDEF 2;
COL cs_ms_per_exec_threshold NEW_V cs_ms_per_exec_threshold NOPRI;
SELECT NVL('&&cs_ms_per_exec_threshold.', '&&def_ms_per_exec_threshold.') AS cs_ms_per_exec_threshold FROM DUAL
/
PRO
PRO 3. Average Active Sessions Threshold: [{&&def_aas_tot_threshold.}]
DEF cs_aas_tot_threshold = '&3.';
UNDEF 3;
COL cs_aas_tot_threshold NEW_V cs_aas_tot_threshold NOPRI;
SELECT NVL('&&cs_aas_tot_threshold.', '&&def_aas_tot_threshold.') AS cs_aas_tot_threshold FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_ms_per_exec_threshold." "&&cs_aas_tot_threshold."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO MS_PER_EXEC  : "&&cs_ms_per_exec_threshold." [{&&def_ms_per_exec_threshold.}]
PRO AAS_DB_TIME  : "&&cs_aas_tot_threshold." [{&&def_aas_tot_threshold.}]
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
MERGE INTO &&cs_tools_schema..non_scalable_plan_ignore_sql o
  USING (SELECT TRIM('&&cs_sql_id.') AS sql_id, TO_NUMBER(NVL(TRIM('&&cs_ms_per_exec_threshold.'), '&&def_ms_per_exec_threshold.')) AS ms_per_exec_threshold, TO_NUMBER(NVL(TRIM('&&cs_aas_tot_threshold.'), '&&def_aas_tot_threshold.')) AS aas_tot_threshold, '&&cs_reference.' AS reference FROM DUAL WHERE LENGTH(TRIM('&&cs_sql_id.')) = 13) i
  ON (o.sql_id = i.sql_id)
WHEN MATCHED THEN
  UPDATE SET 
  o.ms_per_exec_threshold = i.ms_per_exec_threshold,
  o.aas_tot_threshold = i.aas_tot_threshold,
  o.reference = i.reference
WHEN NOT MATCHED THEN
  INSERT (sql_id, ms_per_exec_threshold, aas_tot_threshold, reference)
  VALUES (i.sql_id, i.ms_per_exec_threshold, i.aas_tot_threshold, i.reference)
/
DELETE &&cs_tools_schema..non_scalable_plan_ignore_sql WHERE sql_id = TRIM('&&cs_sql_id.') AND (TO_NUMBER(NVL(TRIM('&&cs_ms_per_exec_threshold.'), '0')) = 0 OR TO_NUMBER(NVL(TRIM('&&cs_aas_tot_threshold.'), '0')) = 0)
/
COMMIT
/
--
PRO
PRO ALL EXCLUDED SQL &&cs_tools_schema..non_scalable_plan_ignore_sql
PRO ~~~~~~~~~~~~~~~~
SELECT sql_id, ms_per_exec_threshold, aas_tot_threshold, reference 
  FROM &&cs_tools_schema..non_scalable_plan_ignore_sql 
 ORDER BY sql_id
/
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_ms_per_exec_threshold." "&&cs_aas_tot_threshold."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
