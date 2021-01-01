----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_accept.sql
--
-- Purpose:     Accept one or all SQL Plan Baselines for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/20
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_accept.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
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
DEF cs_script_name = 'cs_spbl_accept';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_&&dba_or_cdb._plans_performance.sql
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO 2. PLAN_NAME (opt):
DEF cs_plan_name = '&2.';
UNDEF 2;
--
DEF cs_plan_id = '';
COL cs_plan_id NEW_V cs_plan_id NOPRI;
SELECT TO_CHAR(plan_id) cs_plan_id
  FROM sys.sqlobj$
 WHERE obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND signature = TO_NUMBER('&&cs_signature.')
   AND name = '&&cs_plan_name.'
/
PRO
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_name."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO APPLICATION  : &&cs_application_category.
PRO PLAN_NAME    : "&&cs_plan_name."
PRO PLAN_ID      : "&&cs_plan_id."
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/cs_&&dba_or_cdb._plans_performance.sql
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO Accept plan: "&&cs_plan_name."
DECLARE
  l_plans INTEGER;
  l_report CLOB;
BEGIN
  FOR i IN (SELECT sql_handle, signature, plan_name, enabled, accepted, description
              FROM dba_sql_plan_baselines 
             WHERE signature = &&cs_signature.
               AND plan_name = NVL('&&cs_plan_name.', plan_name)
             ORDER BY signature, plan_name)
  LOOP
    IF i.enabled = 'NO' THEN
      l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'YES');
    END IF;
    IF i.accepted = 'NO' THEN
      l_report := DBMS_SPM.evolve_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, verify => 'NO', commit => 'YES');
    END IF;
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => TRIM(i.description||' &&cs_script_name..sql &&cs_reference_sanitized. ACCEPTED='||TO_CHAR(SYSDATE, '&&cs_datetime_full_format.')));    
  END LOOP;
END;
/
--
@@cs_internal/cs_spbl_internal_list.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_plan_name."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
