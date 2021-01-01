----------------------------------------------------------------------------------------
--
-- File name:   cs_purge_cursor.sql
--
-- Purpose:     Purge Cursor(s) for SQL_ID using DBMS_SHARED_POOL.PURGE and SQL Patch
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
--              SQL> @cs_purge_cursor.sql
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
DEF cs_script_name = 'cs_purge_cursor';
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
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
@@cs_internal/cs_&&dba_or_cdb._plans_performance.sql
--
DEF plan_name_backup = '';
COL plan_name_backup NEW_V plan_name_backup NOPRI;
SELECT name AS plan_name_backup FROM dba_sql_patches WHERE signature = :cs_signature AND category = 'DEFAULT' AND ROWNUM = 1
/
DEF cs_name = '&&plan_name_backup.';
DEF cs_category = 'BACKUP';
--
PRO
PRO Backup SQL Patch (if any)
PRO ~~~~~~~~~~~~~~~~
@@cs_internal/cs_spch_internal_category.sql
--
DEF hints_text = 'DUMMY';
--
PRO
PRO Create and Drop DUMMY SQL Patch
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@@cs_internal/cs_spch_internal_create.sql
@@cs_internal/cs_spch_internal_drop.sql
--
DEF cs_category = 'DEFAULT';
--
PRO
PRO Restore SQL Patch (if any)
PRO ~~~~~~~~~~~~~~~~~
@@cs_internal/cs_spch_internal_category.sql
--
PRO
PRO DBMS_SHARED_POOL.PURGE
PRO ~~~~~~~~~~~~~~~~~~~~~~
DECLARE
  l_name     VARCHAR2(64);
BEGIN
  SELECT address||','||hash_value INTO l_name FROM v$sqlarea WHERE sql_id = '&&cs_sql_id.' AND ROWNUM = 1; -- there are cases where it comes back with > 1 row!!!
  SYS.DBMS_SHARED_POOL.PURGE(name => l_name, flag => 'C', heaps => 1); -- not always does the job
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
END;
/
--
@@cs_internal/cs_&&dba_or_cdb._plans_performance.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
