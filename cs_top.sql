----------------------------------------------------------------------------------------
--
-- File name:   ta.sql | t.sql | cs_top.sql
--
-- Purpose:     Top N Active SQL as per recent (AAS) Average Active Sessions (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/21
--
-- Usage:       Execute connected to PDB or CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top.sql
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
DEF cs_script_name = 'cs_top';
DEF cs_script_acronym = 'ta.sql | t.sql | ';
--
DEF cs_minutes = '1';
DEF cs_top = '30';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_top_activity_internal.sql
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--