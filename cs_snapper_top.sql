----------------------------------------------------------------------------------------
--
-- File name:   snapper_top.sql | cs_snapper_top.sql
--
-- Purpose:     Sessions Snapper for all sessions using Tanel Poder Snapper
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/16
--
-- Usage:       Execute connected to PDB or CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_snapper_top.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
--@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_snapper_top';
DEF cs_script_acronym = 'snapper_top.sql | ';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
PRO
--
PRO Snapper #1 out of 6
@@snapper_top.sql
--
PRO Snapper #2 out of 6
@@snapper_top.sql
--
PRO Snapper #3 out of 6
@@snapper_top.sql
--
PRO Snapper #4 out of 6
@@snapper_top.sql
--
PRO Snapper #5 out of 6
@@snapper_top.sql
--
PRO Snapper #6 out of 6
@@snapper_top.sql
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--