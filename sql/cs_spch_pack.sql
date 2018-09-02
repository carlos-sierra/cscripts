----------------------------------------------------------------------------------------
--
-- File name:   cs_spch_pack.sql
--
-- Purpose:     Packs into staging table one or all SQL Patches for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2018/08/06
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spch_pack.sql
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
DEF cs_script_name = 'cs_spch_pack';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
--
SELECT '&&cs_file_prefix._&&cs_sql_id._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_plans_performance.sql
@@cs_internal/cs_spch_internal_list.sql
--
PRO
PRO 2. Enter NAME (opt)
DEF cs_name = '&2.';
PRO
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_name."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO NAME         : &&cs_name.
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/cs_plans_performance.sql
@@cs_internal/cs_spch_internal_list.sql
--
PRO
PRO Pack name: "&&cs_name."
BEGIN
  FOR i IN (SELECT name 
              FROM dba_sql_patches 
             WHERE signature = :cs_signature
               AND name = NVL('&&cs_name.', name)
             ORDER BY name)
  LOOP
    DBMS_SQLDIAG.pack_stgtab_sqlpatch(patch_name => i.name, staging_table_name => '&&cs_stgtab_prefix._stgtab_sqlpatch', staging_schema_owner => '&&cs_stgtab_owner.');
  END LOOP;
END;
/
--
@@cs_internal/cs_spch_internal_list.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_name."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--


