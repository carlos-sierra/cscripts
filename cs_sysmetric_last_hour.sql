----------------------------------------------------------------------------------------
--
-- File name:   cs_sysmetric_last_hour.sql
--
-- Purpose:     All System Metrics Summary (AVG and MAX) for last one hour (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/09
--
-- Usage:       Execute connected to CDB or PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sysmetric_last_hour.sql
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
DEF cs_script_name = 'cs_sysmetric_last_hour';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
COL metric_name FOR A45 TRUN;
COL metric_unit FOR A41 TRUN;
COL seconds FOR 9999;
--
PRO
PRO System Metrics Summary by Name
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT metric_name,
       average,
       maxval,
       metric_unit,
       begin_time,
       end_time,
       intsize_csec/100 seconds,
       num_interval samples
  FROM v$sysmetric_summary
 ORDER BY
       metric_name
/
--
PRO
PRO System Metrics Summary by Unit and Name
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT metric_unit,
       metric_name,
       average,
       maxval,
       begin_time,
       end_time,
       intsize_csec/100 seconds,
       num_interval samples
  FROM v$sysmetric_summary
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