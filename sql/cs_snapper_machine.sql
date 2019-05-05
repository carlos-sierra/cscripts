----------------------------------------------------------------------------------------
--
-- File name:   cs_snapper_machine.sql
--
-- Purpose:     Top Active Sessions for a Machine using Tanel Poder Snapper
--
-- Author:      Carlos Sierra
--
-- Version:     2019/02/08
--
-- Usage:       Execute connected to PDB or CDB. Pass Machine when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_snapper_machine.sql
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
DEF cs_script_name = 'cs_snapper_machine';
--
SELECT COUNT(*) sessions, 
       SUM(CASE status WHEN 'ACTIVE' THEN 1 ELSE 0 END) active,
       SUM(CASE status WHEN 'INACTIVE' THEN 1 ELSE 0 END) inactive,
       SUM(CASE status WHEN 'KILLED' THEN 1 ELSE 0 END) killed,
       type,
       machine 
  FROM v$session 
 WHERE machine IS NOT NULL 
 GROUP BY type, machine 
 ORDER BY 1 DESC
/
--
PRO
PRO Executing: SQL> @@snapper.sql ash=machine 5 1 all
@@snapper.sql ash=machine 5 1 all
UNDEF 1 2 3 4;
--
PRO 1. Machine: 
DEF cs_machine = '&1.';
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_machine.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_machine."
@@cs_internal/cs_spool_id.sql
--
PRO MACHINE      : "&&cs_machine."
PRO
--
DEF machine = '&&cs_machine.';
PRO Snapper #1 out of 6
@@snapper_machine.sql
--
DEF machine = '&&cs_machine.';
PRO Snapper #2 out of 6
@@snapper_machine.sql
--
DEF machine = '&&cs_machine.';
PRO Snapper #3 out of 6
@@snapper_machine.sql
--
DEF machine = '&&cs_machine.';
PRO Snapper #4 out of 6
@@snapper_machine.sql
--
DEF machine = '&&cs_machine.';
PRO Snapper #5 out of 6
@@snapper_machine.sql
--
DEF machine = '&&cs_machine.';
PRO Snapper #6 out of 6
@@snapper_machine.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_machine."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--