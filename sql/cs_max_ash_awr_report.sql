----------------------------------------------------------------------------------------
--
-- File name:   cs_max_ash_awr_report.sql
--
-- Purpose:     Report of Max Active Sessions History from AWR
--
-- Author:      Carlos Sierra
--
-- Version:     2020/07/10
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_max_ash_awr_report.sql
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
DEF cs_script_name = 'cs_max_ash_awr_report';
DEF cs_hours_range_default = '24';
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
SELECT machine, 10*COUNT(*) db_time_secs
  FROM dba_hist_active_sess_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
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
COL as_time           FOR A19       HEA 'End Time'; 
COL as_total          FOR 999,990 HEA 'Act Ses Tot';
COL as_on_cpu         FOR 999,990 HEA '     ON CPU';
COL as_user_io        FOR 999,990 HEA '   User I/O';
COL as_system_io      FOR 999,990 HEA ' System I/O';
COL as_cluster        FOR 999,990 HEA '    Cluster';
COL as_commit         FOR 999,990 HEA '     Commit';
COL as_concurrency    FOR 999,990 HEA 'Concurrency';
COL as_application    FOR 999,990 HEA 'Application';
COL as_administrative FOR 999,990 HEA 'Administrative';
COL as_configuration  FOR 999,990 HEA 'Configuration';
COL as_network        FOR 999,990 HEA '    Network';
COL as_queueing       FOR 999,990 HEA '   Queueing';
COL as_scheduler      FOR 999,990 HEA '  Scheduler';
COL as_other          FOR 999,990 HEA '      Other';
--
BREAK ON REPORT;
COMPUTE MAX LABEL 'MAX' OF as_total as_on_cpu as_user_io as_system_io as_cluster as_commit as_concurrency as_application as_administrative as_configuration as_network as_queueing as_scheduler as_other ON REPORT;
--
PRO
PRO Max Active Sessions (AAS) from AWR
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
/****************************************************************************************/
WITH
FUNCTION ceil_date (p_date IN DATE)
RETURN DATE
IS
BEGIN
  IF '&&cs2_granularity.' = 'SS' THEN
    RETURN p_date + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '15MI' THEN
    RETURN TRUNC(p_date, 'HH') + FLOOR(TO_NUMBER(TO_CHAR(p_date, 'MI')) / 15) * 15 / (24 * 60) + &&cs2_plus_days.;
  ELSIF '&&cs2_granularity.' = '5MI' THEN
    RETURN TRUNC(p_date, 'HH') + FLOOR(TO_NUMBER(TO_CHAR(p_date, 'MI')) / 5) * 5 / (24 * 60) + &&cs2_plus_days.;
  ELSE
    RETURN TRUNC(p_date + &&cs2_plus_days., '&&cs2_granularity.');
  END IF;
END ceil_date;
/****************************************************************************************/
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       1 * COUNT(*) AS as_total, -- active sessions on the database (on cpu or waiting)
       SUM(CASE session_state WHEN 'ON CPU'         THEN 1 ELSE 0 END) as_on_cpu,
       SUM(CASE wait_class    WHEN 'User I/O'       THEN 1 ELSE 0 END) as_user_io,
       SUM(CASE wait_class    WHEN 'System I/O'     THEN 1 ELSE 0 END) as_system_io,
       SUM(CASE wait_class    WHEN 'Cluster'        THEN 1 ELSE 0 END) as_cluster,
       SUM(CASE wait_class    WHEN 'Commit'         THEN 1 ELSE 0 END) as_commit,
       SUM(CASE wait_class    WHEN 'Concurrency'    THEN 1 ELSE 0 END) as_concurrency,
       SUM(CASE wait_class    WHEN 'Application'    THEN 1 ELSE 0 END) as_application,
       SUM(CASE wait_class    WHEN 'Administrative' THEN 1 ELSE 0 END) as_administrative,
       SUM(CASE wait_class    WHEN 'Configuration'  THEN 1 ELSE 0 END) as_configuration,
       SUM(CASE wait_class    WHEN 'Network'        THEN 1 ELSE 0 END) as_network,
       SUM(CASE wait_class    WHEN 'Queueing'       THEN 1 ELSE 0 END) as_queueing,
       SUM(CASE wait_class    WHEN 'Scheduler'      THEN 1 ELSE 0 END) as_scheduler,
       SUM(CASE wait_class    WHEN 'Other'          THEN 1 ELSE 0 END) as_other,
       ROW_NUMBER() OVER (PARTITION BY ceil_date(sample_time) ORDER BY COUNT(*) DESC NULLS LAST) AS row_number 
  FROM dba_hist_active_sess_history h
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND ('&&cs2_machine.' IS NULL OR UPPER(machine) LIKE CHR(37)||UPPER('&&cs2_machine.')||CHR(37))
   AND ('&&cs2_sql_text_piece.' IS NULL OR UPPER((SELECT s.sql_text FROM v$sql s WHERE s.sql_id = h.sql_id AND ROWNUM = 1)) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37))
   AND ('&&cs_sql_id.' IS NULL OR sql_id = '&&cs_sql_id.')
   AND ('&&cs_module.' IS NULL OR module = '&&cs_module.')
   AND ('&&cs_action.' IS NULL OR action = '&&cs_action.')
 GROUP BY
       sample_time
)
/****************************************************************************************/
SELECT TO_CHAR(ceil_date(q.sample_time), '&&cs_datetime_full_format.') AS as_time,
       q.as_total, 
       q.as_on_cpu, 
       q.as_user_io, 
       q.as_system_io, 
       q.as_cluster, 
       q.as_commit, 
       q.as_concurrency, 
       q.as_application, 
       q.as_administrative, 
       q.as_configuration, 
       q.as_network, 
       q.as_queueing, 
       q.as_scheduler, 
       q.as_other
  FROM my_query q
 WHERE q.row_number = 1
 ORDER BY
       ceil_date(q.sample_time)
/
/****************************************************************************************/
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