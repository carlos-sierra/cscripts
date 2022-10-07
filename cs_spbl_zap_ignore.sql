----------------------------------------------------------------------------------------
--
-- File name:   zi.sql | cs_spbl_zap_ignore.sql
--
-- Purpose:     Add SQL_ID to Zapper exclusion list (Zapper to ignore such SQL_ID)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/11/18
--
-- Usage:       Connecting into PDB or CDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_spbl_zap_ignore.sql
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
DEF cs_script_name = 'cs_spbl_zap_ignore';
DEF cs_script_acronym = 'zi.sql | ';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SQLHV        : &&cs_sqlid.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
MERGE INTO &&cs_tools_schema..zapper_ignore_sql o
  USING (SELECT TRIM('&&cs_sql_id.') AS sql_id, '&&cs_reference.' AS reference FROM DUAL WHERE LENGTH(TRIM('&&cs_sql_id.')) = 13) i
  ON (o.sql_id = i.sql_id)
WHEN MATCHED THEN
  UPDATE SET o.reference = i.reference
WHEN NOT MATCHED THEN
  INSERT (sql_id, reference)
  VALUES (i.sql_id, i.reference)
/
COMMIT
/
--
PRO
PRO EXCLUDED SQL &&cs_tools_schema..zapper_ignore_sql
PRO ~~~~~~~~~~~~
SELECT * FROM &&cs_tools_schema..zapper_ignore_sql ORDER BY sql_id
/
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
