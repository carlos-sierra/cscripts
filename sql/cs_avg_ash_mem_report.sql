----------------------------------------------------------------------------------------
--
-- File name:   cs_avg_ash_mem_report.sql
--
-- Purpose:     Report of Average Active Sessions History from MEM
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/14
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
PRO
PRO 3. Granularity: [{5MI}|SS|MI|15MI|HH|DD]
DEF cs2_granularity = '&3.';
UNDEF 3;
COL cs2_granularity NEW_V cs2_granularity NOPRI;
SELECT NVL(UPPER(TRIM('&&cs2_granularity.')), '5MI') cs2_granularity FROM DUAL;
SELECT CASE WHEN '&&cs2_granularity.' IN ('SS', 'MI', '5MI', '15MI', 'HH', 'DD') THEN '&&cs2_granularity.' ELSE '5MI' END cs2_granularity FROM DUAL;
--
COL cs2_plus_days NEW_V cs2_plus_days NOPRI;
SELECT CASE '&&cs2_granularity.' 
         WHEN 'SS' THEN '0.000011574074074' -- (1/24/3600) 1 second
         WHEN 'MI' THEN '0.000694444444444' -- (1/24/60) 1 minute
         WHEN '5MI' THEN '0.003472222222222' -- (5/24/60) 5 minutes
         WHEN '15MI' THEN '0.01041666666666' -- (15/24/60) 15 minutes
         WHEN 'HH' THEN '0.041666666666667' -- (1/24) 1 hour
         WHEN 'DD' THEN '1' -- 1 day
         ELSE '0.003472222222222' -- default of 5 minutes
       END cs2_plus_days 
  FROM DUAL
/
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
UNDEF 4;
--
PRO
PRO Filtering SQL to reduce search space.
PRO Enter additional SQL Text filtering, such as Table name or SQL Text piece
PRO
PRO 5. SQL Text piece (opt):
DEF cs2_sql_text_piece = '&5.';
UNDEF 5;
--
PRO
PRO 6. SQL_ID (opt): 
DEF cs_sql_id = '&6.';
UNDEF 6;
--
PRO
PRO 7. Module (opt): 
DEF cs_module = '&7.';
UNDEF 7;
--
PRO
PRO 8. Action (opt): 
DEF cs_action = '&8.';
UNDEF 8;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_granularity." "&&cs2_machine." "&&cs2_sql_text_piece." "&&cs_sql_id." "&&cs_module." "&&cs_action."  
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
PRO GRANULARITY  : "&&cs2_granularity." [{5MI}|SS|MI|15MI|HH|DD]
PRO MACHINE      : "&&cs2_machine."
PRO SQL_TEXT     : "&&cs2_sql_text_piece."
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
FUNCTION ceil_timestamp (p_timestamp IN TIMESTAMP)
RETURN DATE
IS
BEGIN
  IF '&&cs2_granularity.' = 'SS' THEN
    RETURN CAST(p_timestamp AS DATE) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '15MI' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'HH') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), 'MI')) / 15) * 15 / (24 * 60) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '5MI' THEN
    RETURN TRUNC(CAST(p_timestamp AS DATE), 'HH') + FLOOR(TO_NUMBER(TO_CHAR(CAST(p_timestamp AS DATE), 'MI')) / 5) * 5 / (24 * 60) + &&cs2_plus_days.;
  ELSE
    RETURN TRUNC(CAST(p_timestamp AS DATE) + &&cs2_plus_days., '&&cs2_granularity.');
  END IF;
END ceil_timestamp;
/****************************************************************************************/
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ceil_timestamp(sample_time) time,
       ROUND(24 * 3600 * (MAX(CAST(sample_time AS DATE)) - MIN(CAST(sample_time AS DATE))) + 1) interval_secs,
       1 * COUNT(*) AS aas_total, -- average active sessions on the database (on cpu or waiting)
       SUM(CASE session_state WHEN 'ON CPU'         THEN 1 ELSE 0 END) aas_on_cpu,
       SUM(CASE wait_class    WHEN 'User I/O'       THEN 1 ELSE 0 END) aas_user_io,
       SUM(CASE wait_class    WHEN 'System I/O'     THEN 1 ELSE 0 END) aas_system_io,
       SUM(CASE wait_class    WHEN 'Cluster'        THEN 1 ELSE 0 END) aas_cluster,
       SUM(CASE wait_class    WHEN 'Commit'         THEN 1 ELSE 0 END) aas_commit,
       SUM(CASE wait_class    WHEN 'Concurrency'    THEN 1 ELSE 0 END) aas_concurrency,
       SUM(CASE wait_class    WHEN 'Application'    THEN 1 ELSE 0 END) aas_application,
       SUM(CASE wait_class    WHEN 'Administrative' THEN 1 ELSE 0 END) aas_administrative,
       SUM(CASE wait_class    WHEN 'Configuration'  THEN 1 ELSE 0 END) aas_configuration,
       SUM(CASE wait_class    WHEN 'Network'        THEN 1 ELSE 0 END) aas_network,
       SUM(CASE wait_class    WHEN 'Queueing'       THEN 1 ELSE 0 END) aas_queueing,
       SUM(CASE wait_class    WHEN 'Scheduler'      THEN 1 ELSE 0 END) aas_scheduler,
       SUM(CASE wait_class    WHEN 'Other'          THEN 1 ELSE 0 END) aas_other
  FROM v$active_session_history h
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs2_machine.' IS NULL OR UPPER(machine) LIKE CHR(37)||UPPER('&&cs2_machine.')||CHR(37))
   AND ('&&cs2_sql_text_piece.' IS NULL OR UPPER((SELECT s.sql_text FROM v$sql s WHERE s.sql_id = h.sql_id AND ROWNUM = 1)) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37))
   AND ('&&cs_sql_id.' IS NULL OR sql_id = '&&cs_sql_id.')
   AND ('&&cs_module.' IS NULL OR module = '&&cs_module.')
   AND ('&&cs_action.' IS NULL OR action = '&&cs_action.')
 GROUP BY
       ceil_timestamp(sample_time)
)
SELECT TO_CHAR(q.time, '&&cs_datetime_full_format.') aas_time,
       ROUND(q.aas_total / q.interval_secs, 3) AS aas_total, 
       ROUND(q.aas_on_cpu / q.interval_secs, 3) AS aas_on_cpu, 
       ROUND(q.aas_user_io / q.interval_secs, 3) AS aas_user_io, 
       ROUND(q.aas_system_io / q.interval_secs, 3) AS aas_system_io, 
       ROUND(q.aas_cluster / q.interval_secs, 3) AS aas_cluster, 
       ROUND(q.aas_commit / q.interval_secs, 3) AS aas_commit, 
       ROUND(q.aas_concurrency / q.interval_secs, 3) AS aas_concurrency, 
       ROUND(q.aas_application / q.interval_secs, 3) AS aas_application, 
       ROUND(q.aas_administrative / q.interval_secs, 3) AS aas_administrative, 
       ROUND(q.aas_configuration / q.interval_secs, 3) AS aas_configuration, 
       ROUND(q.aas_network / q.interval_secs, 3) AS aas_network, 
       ROUND(q.aas_queueing / q.interval_secs, 3) AS aas_queueing, 
       ROUND(q.aas_scheduler / q.interval_secs, 3) AS aas_scheduler, 
       ROUND(q.aas_other / q.interval_secs, 3) AS aas_other
  FROM my_query q
 ORDER BY
       q.time
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_granularity." "&&cs2_machine." "&&cs2_sql_text_piece." "&&cs_sql_id." "&&cs_module." "&&cs_action."  
--
@@cs_internal/cs_spool_tail.sql
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--