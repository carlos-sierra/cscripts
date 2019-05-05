----------------------------------------------------------------------------------------
--
-- File name:   cs_avg_ash_mem_report.sql
--
-- Purpose:     Report of Average Active Sessions History from MEM
--
-- Author:      Carlos Sierra
--
-- Version:     2018/11/03
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_avg_ash_mem_report.sql
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
DEF cs_script_name = 'cs_avg_ash_mem_report';
DEF cs_hours_range_default = '3';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--ALTER SESSION SET container = CDB$ROOT;
--
PRO 3. Granularity: [{MI}|SS|HH]
DEF cs2_granularity = '&3.';
COL cs2_granularity NEW_V cs2_granularity NOPRI;
SELECT NVL(UPPER(TRIM('&&cs2_granularity.')), 'MI') cs2_granularity FROM DUAL;
SELECT CASE WHEN '&&cs2_granularity.' IN ('MI', 'SS', 'HH') THEN '&&cs2_granularity.' ELSE 'MI' END cs2_granularity FROM DUAL;
--
COL cs2_plus_days NEW_V cs2_plus_days NOPRI;
SELECT CASE '&&cs2_granularity.' WHEN 'MI' THEN '0.000694444444444' WHEN 'SS' THEN '0' WHEN 'HH' THEN '0.041666666666667' ELSE '0.000694444444444' END cs2_plus_days FROM DUAL;
--
COL cs2_denominator NEW_V cs2_denominator NOPRI;
SELECT CASE '&&cs2_granularity.' WHEN 'MI' THEN '60' WHEN 'SS' THEN '1' WHEN 'HH' THEN '3600' ELSE '60' END cs2_denominator FROM DUAL;
--
SELECT machine, COUNT(*) db_time_secs
  FROM v$active_session_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 GROUP BY
       machine
 ORDER BY
       machine
/
PRO
PRO 4. Machine (opt): 
DEF cs2_machine = '&4.';
--
PRO
PRO 5. SQL_ID (opt): 
DEF cs_sql_id = '&5.';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_granularity." "&&cs2_machine." "&&cs_sql_id." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO GRANULARITY  : "&&cs2_granularity." [{MI}|SS|HH]
PRO MACHINE      : "&&cs2_machine."
PRO SQL_ID       : "&&cs_sql_id."
--
COL aas_time           FOR A19       HEA 'End Time'; 
COL aas_total          FOR 999,990.0 HEA '  AAS Total';
COL aas_on_cpu         FOR 999,990.0 HEA '     ON CPU';
COL aas_user_io        FOR 999,990.0 HEA '   User I/O';
COL aas_system_io      FOR 999,990.0 HEA ' System I/O';
COL aas_cluster        FOR 999,990.0 HEA '    Cluster';
COL aas_commit         FOR 999,990.0 HEA '     Commit';
COL aas_concurrency    FOR 999,990.0 HEA 'Concurrency';
COL aas_application    FOR 999,990.0 HEA 'Application';
COL aas_administrative FOR 999,990.0 HEA 'Administrative';
COL aas_configuration  FOR 999,990.0 HEA 'Configuration';
COL aas_network        FOR 999,990.0 HEA '    Network';
COL aas_queueing       FOR 999,990.0 HEA '   Queueing';
COL aas_scheduler      FOR 999,990.0 HEA '  Scheduler';
COL aas_other          FOR 999,990.0 HEA '      Other';
--
BREAK ON REPORT;
COMPUTE MAX LABEL 'MAX' OF aas_total aas_on_cpu aas_user_io aas_system_io aas_cluster aas_commit aas_concurrency aas_application aas_administrative aas_configuration aas_network aas_queueing aas_scheduler aas_other ON REPORT;
--
PRO
PRO Average Active Sessions (AAS) from MEM
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       CASE '&&cs2_granularity.' WHEN 'SS' THEN CAST(sample_time AS DATE) ELSE TRUNC(CAST(sample_time AS DATE) + &&cs2_plus_days., '&&cs2_granularity.') END time,
       ROUND(COUNT(*)/TO_NUMBER('&&cs2_denominator.'),1) aas_total, -- average active sessions on the database (on cpu or waiting)
       ROUND(SUM(CASE session_state WHEN 'ON CPU'         THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_on_cpu,
       ROUND(SUM(CASE wait_class    WHEN 'User I/O'       THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_user_io,
       ROUND(SUM(CASE wait_class    WHEN 'System I/O'     THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_system_io,
       ROUND(SUM(CASE wait_class    WHEN 'Cluster'        THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_cluster,
       ROUND(SUM(CASE wait_class    WHEN 'Commit'         THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_commit,
       ROUND(SUM(CASE wait_class    WHEN 'Concurrency'    THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_concurrency,
       ROUND(SUM(CASE wait_class    WHEN 'Application'    THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_application,
       ROUND(SUM(CASE wait_class    WHEN 'Administrative' THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_administrative,
       ROUND(SUM(CASE wait_class    WHEN 'Configuration'  THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_configuration,
       ROUND(SUM(CASE wait_class    WHEN 'Network'        THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_network,
       ROUND(SUM(CASE wait_class    WHEN 'Queueing'       THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_queueing,
       ROUND(SUM(CASE wait_class    WHEN 'Scheduler'      THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_scheduler,
       ROUND(SUM(CASE wait_class    WHEN 'Other'          THEN 1 ELSE 0 END)/TO_NUMBER('&&cs2_denominator.'),1) aas_other
  FROM v$active_session_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND machine LIKE '%'||TRIM('&&cs2_machine.')||'%'
   AND ('&&cs_sql_id.' IS NULL OR sql_id = '&&cs_sql_id.')
 GROUP BY
       CASE '&&cs2_granularity.' WHEN 'SS' THEN CAST(sample_time AS DATE) ELSE TRUNC(CAST(sample_time AS DATE) + &&cs2_plus_days., '&&cs2_granularity.') END
)
SELECT TO_CHAR(q.time, '&&cs_datetime_full_format.') aas_time,
       q.aas_total,
       q.aas_on_cpu, 
       q.aas_user_io, 
       q.aas_system_io, 
       q.aas_cluster, 
       q.aas_commit, 
       q.aas_concurrency, 
       q.aas_application, 
       q.aas_administrative, 
       q.aas_configuration, 
       q.aas_network, 
       q.aas_queueing, 
       q.aas_scheduler, 
       q.aas_other
  FROM my_query q
 ORDER BY
       q.time
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_granularity." "&&cs2_machine." "&&cs_sql_id." 
--
@@cs_internal/cs_spool_tail.sql
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--