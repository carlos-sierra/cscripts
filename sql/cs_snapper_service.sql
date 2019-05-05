----------------------------------------------------------------------------------------
--
-- File name:   cs_snapper_service.sql
--
-- Purpose:     Top Active Sessions for a Service using Tanel Poder Snapper
--
-- Author:      Carlos Sierra
--
-- Version:     2019/02/08
--
-- Usage:       Execute connected to PDB or CDB. Pass Service Name when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_snapper_service.sql
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
DEF cs_script_name = 'cs_snapper_service';
--
SELECT COUNT(*) sessions, 
       SUM(CASE status WHEN 'ACTIVE' THEN 1 ELSE 0 END) active,
       SUM(CASE status WHEN 'INACTIVE' THEN 1 ELSE 0 END) inactive,
       SUM(CASE status WHEN 'KILLED' THEN 1 ELSE 0 END) killed,
       type,
       service_name 
  FROM v$session 
 WHERE service_name IS NOT NULL 
 GROUP BY type, service_name 
 ORDER BY 1 DESC
/
--
PRO
PRO Executing: SQL> @@snapper.sql ash=service_name 5 1 all
@@snapper.sql ash=service_name 5 1 all
UNDEF 1 2 3 4;
--
PRO 1. Service Name: 
DEF cs_service_name = '&1.';
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_service_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_service_name."
@@cs_internal/cs_spool_id.sql
--
PRO SERVICE_NAME : "&&cs_service_name."
PRO
--
DEF service_name = '&&cs_service_name.';
PRO Snapper #1 out of 6
@@snapper_service.sql
--
DEF service_name = '&&cs_service_name.';
PRO Snapper #2 out of 6
@@snapper_service.sql
--
DEF service_name = '&&cs_service_name.';
PRO Snapper #3 out of 6
@@snapper_service.sql
--
DEF service_name = '&&cs_service_name.';
PRO Snapper #4 out of 6
@@snapper_service.sql
--
DEF service_name = '&&cs_service_name.';
PRO Snapper #5 out of 6
@@snapper_service.sql
--
DEF service_name = '&&cs_service_name.';
PRO Snapper #6 out of 6
@@snapper_service.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_service_name."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--