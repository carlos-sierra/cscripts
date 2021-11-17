----------------------------------------------------------------------------------------
--
-- File name:   kiev_fs.sql
--
-- Purpose:     Find application SQL statements matching some string
--
-- Author:      Carlos Sierra
--
-- Version:     2021/05/15
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter string to match when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @kiev_fs.sql
--
-- Notes:       *** Requires Oracle Diagnostics Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
-- @@cs_internal/cs_primary.sql
-- @@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'kiev_fs';
--
PRO 1. SEARCH_STRING: SQL_ID or SQL_TEXT piece or PLAN_HASH_VALUE: (e.g.: ScanQuery, getValues, TableName, IndexName)
DEF search_string = '&1.';
UNDEF 1;
COL search_string NEW_V search_string;
SELECT /* &&cs_script_name. */ TRIM('&&search_string.') search_string FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&search_string." 
-- @@cs_internal/cs_spool_id.sql
-- PRO SEARCH_STRING: &&search_string.
--
@@kiev/kiev_fs_internal.sql
PRO
PRO SQL> @&&cs_script_name..sql "&&search_string." 
--
@@cs_internal/cs_spool_tail.sql
-- @@cs_internal/cs_undef.sql
-- @@cs_internal/cs_reset.sql
--