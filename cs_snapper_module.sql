----------------------------------------------------------------------------------------
--
-- File name:   snapper_module.sql | cs_snapper_module.sql
--
-- Purpose:     Sessions Snapper for one Module using Tanel Poder Snapper
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/16
--
-- Usage:       Execute connected to PDB or CDB. Pass Module when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_snapper_module.sql
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
DEF cs_script_name = 'cs_snapper_module';
DEF cs_script_acronym = 'snapper_module.sql | ';
--
SELECT COUNT(*) sessions, 
       SUM(CASE status WHEN 'ACTIVE' THEN 1 ELSE 0 END) active,
       SUM(CASE status WHEN 'INACTIVE' THEN 1 ELSE 0 END) inactive,
       SUM(CASE status WHEN 'KILLED' THEN 1 ELSE 0 END) killed,
       type,
       module 
  FROM v$session 
 WHERE module IS NOT NULL 
 GROUP BY type, module 
 ORDER BY 1 DESC
/
--
PRO
PRO Executing: SQL> @@snapper.sql ash=module 5 1 all
@@snapper.sql ash=module 5 1 all
UNDEF 1 2 3 4;
--
PRO 1. Module: 
DEF cs_module = '&1.';
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_module.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_module."
@@cs_internal/cs_spool_id.sql
--
PRO MODULE       : "&&cs_module."
PRO
--
DEF module = '&&cs_module.';
PRO Snapper #1 out of 6
@@snapper_module.sql
--
DEF module = '&&cs_module.';
PRO Snapper #2 out of 6
@@snapper_module.sql
--
DEF module = '&&cs_module.';
PRO Snapper #3 out of 6
@@snapper_module.sql
--
DEF module = '&&cs_module.';
PRO Snapper #4 out of 6
@@snapper_module.sql
--
DEF module = '&&cs_module.';
PRO Snapper #5 out of 6
@@snapper_module.sql
--
DEF module = '&&cs_module.';
PRO Snapper #6 out of 6
@@snapper_module.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_module."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--