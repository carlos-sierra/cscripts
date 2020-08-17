----------------------------------------------------------------------------------------
--
-- File name:   cs_max_ash_mem_chart.sql
--
-- Purpose:     Chart of Max Active Sessions History from MEM
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
--              SQL> @cs_max_ash_mem_chart.sql
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
DEF cs_script_name = 'cs_max_ash_mem_chart';
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
DEF report_title = 'Max Active Sessions between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF xaxis_title = 'GRANULARITY:"&&cs2_granularity." MACHINE:"&&cs2_machine." TEXT:"&&cs2_sql_text_piece." SQL_ID:"&&cs_sql_id." MODULE:"&&cs_module." ACTION:"&&cs_action."';
DEF vaxis_title = 'Max Active Sessions';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_2 = '<br>2) GRANULARITY: &&cs2_granularity. [{5MI}|SS|MI|15MI|HH|DD] MACHINE:"&&cs2_machine." TEXT:"&&cs2_sql_text_piece." SQL_ID:"&&cs_sql_id." MODULE:"&&cs_module." ACTION:"&&cs_action."';
DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_granularity." "&&cs2_machine." "&&cs2_sql_text_piece." "&&cs_sql_id." "&&cs_module." "&&cs_action."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'ON CPU'        
PRO ,'User I/O'      
PRO ,'System I/O'    
PRO ,'Cluster'       
PRO ,'Commit'        
PRO ,'Concurrency'   
PRO ,'Application'   
PRO ,'Administrative'
PRO ,'Configuration' 
PRO ,'Network'       
PRO ,'Queueing'      
PRO ,'Scheduler'     
PRO ,'Other'         
PRO ]
--
SET HEA OFF PAGES 0;
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
  FROM v$active_session_history h
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs2_machine.' IS NULL OR UPPER(machine) LIKE CHR(37)||UPPER('&&cs2_machine.')||CHR(37))
   AND ('&&cs2_sql_text_piece.' IS NULL OR UPPER((SELECT s.sql_text FROM v$sql s WHERE s.sql_id = h.sql_id AND ROWNUM = 1)) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37))
   AND ('&&cs_sql_id.' IS NULL OR sql_id = '&&cs_sql_id.')
   AND ('&&cs_module.' IS NULL OR module = '&&cs_module.')
   AND ('&&cs_action.' IS NULL OR action = '&&cs_action.')
 GROUP BY
       sample_time
)
/****************************************************************************************/
SELECT ', [new Date('||
       TO_CHAR(ceil_date(q.sample_time), 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(ceil_date(q.sample_time), 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(ceil_date(q.sample_time), 'DD')|| /* day */
       ','||TO_CHAR(ceil_date(q.sample_time), 'HH24')|| /* hour */
       ','||TO_CHAR(ceil_date(q.sample_time), 'MI')|| /* minute */
       ','||TO_CHAR(ceil_date(q.sample_time), 'SS')|| /* second */
       ')'||
       --','||as_total|| 
       ','||as_on_cpu|| 
       ','||as_user_io|| 
       ','||as_system_io|| 
       ','||as_cluster|| 
       ','||as_commit|| 
       ','||as_concurrency|| 
       ','||as_application|| 
       ','||as_administrative|| 
       ','||as_configuration|| 
       ','||as_network|| 
       ','||as_queueing|| 
       ','||as_scheduler|| 
       ','||as_other||
       ']'
  FROM my_query q
 WHERE q.row_number = 1
 ORDER BY
       ceil_date(q.sample_time)
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = 'SteppedArea';
-- disable explorer with "//" when using Pie
DEF cs_chart_option_explorer = '';
-- enable pie options with "" when using Pie
DEF cs_chart_option_pie = '//';
-- use oem colors
DEF cs_oem_colors_series = '';
DEF cs_oem_colors_slices = '//';
-- for line charts
DEF cs_curve_type = '//';
--
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO
PRO &&report_foot_note.
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--