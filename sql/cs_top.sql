----------------------------------------------------------------------------------------
--
-- File name:   cs_top.sql
--
-- Purpose:     Top Active SQL as per recent Average Active Sessions 
--
-- Author:      Carlos Sierra
--
-- Version:     2020/07/09
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
DEF cs_minutes = '1';
DEF cs_top = '30';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
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