----------------------------------------------------------------------------------------
--
-- File name:   cs_sysmetric_current.sql
--
-- Purpose:     System Metrics
--
-- Author:      Carlos Sierra
--
-- Version:     2019/03/24
--
-- Usage:       Execute connected to CDB or PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sysmetric_current.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sysmetric_current';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL metric_name FOR A45 TRUN;
COL metric_unit FOR A41 TRUN;
COL seconds FOR 900.00;
--
PRO
PRO System Metrics by Name
PRO ~~~~~~~~~~~~~~~~~~~~~~
SELECT metric_name,
       value,
       metric_unit,
       begin_time,
       end_time,
       intsize_csec/100 seconds
  FROM v$sysmetric
 ORDER BY
       metric_name
/
--
PRO
PRO System Metrics by Unit and Name
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT metric_unit,
       metric_name,
       value,
       begin_time,
       end_time,
       intsize_csec/100 seconds
  FROM v$sysmetric
 ORDER BY
       metric_unit,
       metric_name
/
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--