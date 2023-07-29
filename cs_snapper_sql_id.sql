----------------------------------------------------------------------------------------
--
-- File name:   snapper_sql_id.sql | cs_snapper_sql_id.sql
--
-- Purpose:     Sessions Snapper for one SQL_ID using Tanel Poder Snapper
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/16
--
-- Usage:       Execute connected to PDB or CDB. Pass SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_snapper_sql_id.sql
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
DEF cs_script_name = 'cs_snapper_sql_id';
DEF cs_script_acronym = 'snapper_sql_id.sql | ';
--
SELECT COUNT(*) sessions, 
       SUM(CASE status WHEN 'ACTIVE' THEN 1 ELSE 0 END) active,
       SUM(CASE status WHEN 'INACTIVE' THEN 1 ELSE 0 END) inactive,
       SUM(CASE status WHEN 'KILLED' THEN 1 ELSE 0 END) killed,
       type,
       sql_id 
  FROM v$session 
 WHERE sql_id IS NOT NULL 
 GROUP BY type, sql_id 
 ORDER BY 1 DESC
/
--
PRO
PRO Executing: SQL> @@snapper.sql ash=sql_id 5 1 all
@@snapper.sql ash=sql_id 5 1 all
UNDEF 1 2 3 4;
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : "&&cs_sql_id."
PRO
--
DEF sql_id = '&&cs_sql_id.';
PRO Snapper #1 out of 6
@@snapper_sql_id.sql
--
DEF sql_id = '&&cs_sql_id.';
PRO Snapper #2 out of 6
@@snapper_sql_id.sql
--
DEF sql_id = '&&cs_sql_id.';
PRO Snapper #3 out of 6
@@snapper_sql_id.sql
--
DEF sql_id = '&&cs_sql_id.';
PRO Snapper #4 out of 6
@@snapper_sql_id.sql
--
DEF sql_id = '&&cs_sql_id.';
PRO Snapper #5 out of 6
@@snapper_sql_id.sql
--
DEF sql_id = '&&cs_sql_id.';
PRO Snapper #6 out of 6
@@snapper_sql_id.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--