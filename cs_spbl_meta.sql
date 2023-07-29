----------------------------------------------------------------------------------------
--
-- File name:   cs_spbl_meta.sql
--
-- Purpose:     SQL Plan Baseline Metadata for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2023/04/27
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_meta.sql
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
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_spbl_meta';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
@@cs_internal/cs_spool_id_list_sql_id.sql
@@cs_internal/cs_print_sql_text.sql
--
CLEAR SQL
PRO
PRO dba_sql_patches
PRO ~~~~~~~~~~~~~~~
1 SELECT * FROM dba_sql_patches WHERE signature = TO_NUMBER('&&cs_signature.') ORDER BY name;
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO dba_sql_profiles
PRO ~~~~~~~~~~~~~~~~
1 SELECT * FROM dba_sql_profiles WHERE signature = TO_NUMBER('&&cs_signature.') ORDER BY name;
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO dba_sql_plan_baselines
PRO ~~~~~~~~~~~~~~~~~~~~~~
1 SELECT * FROM dba_sql_plan_baselines WHERE signature = TO_NUMBER('&&cs_signature.') ORDER BY plan_name;
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO sys.sql$
PRO ~~~~~~~~
1 SELECT * FROM sys.sql$ WHERE signature = TO_NUMBER('&&cs_signature.');
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO sys.sqllog$
PRO ~~~~~~~~~~~
1 SELECT * FROM sys.sqllog$ WHERE signature = TO_NUMBER('&&cs_signature.');
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO sys.sql$text
PRO ~~~~~~~~~~~~
1 SELECT * FROM sys.sql$text WHERE signature = TO_NUMBER('&&cs_signature.');
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO sys.sqlobj$
PRO ~~~~~~~~~~~
1 SELECT * FROM sys.sqlobj$ WHERE signature = TO_NUMBER('&&cs_signature.') ORDER BY obj_type, plan_id;
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO sys.sqlobj$data
PRO ~~~~~~~~~~~~~~~
1 SELECT * FROM sys.sqlobj$data WHERE signature = TO_NUMBER('&&cs_signature.') ORDER BY obj_type, plan_id;
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO sys.sqlobj$auxdata
PRO ~~~~~~~~~~~~~~~~~~
1 SELECT * FROM sys.sqlobj$auxdata WHERE signature = TO_NUMBER('&&cs_signature.') ORDER BY obj_type, plan_id;
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO sys.sqlobj$plan
PRO ~~~~~~~~~~~~~~~
1 SELECT * FROM sys.sqlobj$plan WHERE signature = TO_NUMBER('&&cs_signature.') ORDER BY obj_type, plan_id, id;
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO sys.smb$config
PRO ~~~~~~~~~~~~~~
1 SELECT * FROM sys.smb$config ORDER BY parameter_name;
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO sys.sqlobj$data.comp_data
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
SET PAGES 500;
COL obj_type FOR 99999999;
COL plan_id FOR 9999999999;
COL comp_data FOR A300;
BREAK ON plan_id SKIP PAGE DUPL;
SELECT obj_type, plan_id, XMLSERIALIZE(DOCUMENT XMLTYPE(comp_data) AS CLOB INDENT SIZE = 2) AS comp_data FROM sys.sqlobj$data WHERE signature = TO_NUMBER('&&cs_signature.') AND comp_data IS NOT NULL;
CLEAR BREAK;
SET PAGES 100;
PRO
PRO sys.sqlobj$plan.other_xml
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
SET PAGES 500;
COL obj_type FOR 99999999;
COL plan_id FOR 9999999999;
COL id FOR 999;
COL other_xml FOR A300;
BREAK ON plan_id SKIP PAGE DUPL;
SELECT obj_type, plan_id, id, XMLSERIALIZE(DOCUMENT XMLTYPE(other_xml) AS CLOB INDENT SIZE = 2) AS other_xml FROM sys.sqlobj$plan WHERE signature = TO_NUMBER('&&cs_signature.') AND other_xml IS NOT NULL;
CLEAR BREAK;
SET PAGES 100;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--