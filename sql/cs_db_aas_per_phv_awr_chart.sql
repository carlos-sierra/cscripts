----------------------------------------------------------------------------------------
--
-- File name:   cs_db_aas_per_phv_awr_chart.sql
--
-- Purpose:     Chart for DB Average Active Sessions (AAS) per Plan Hash Value (PHV)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/14
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_db_aas_per_phv_awr_chart.sql
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
DEF cs_script_name = 'cs_db_aas_per_phv_awr_chart';
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
PRO
PRO 4. SQL_ID: 
DEF cs_sql_id = '&4.';
UNDEF 4;
--
COL sql_plan_hash_value_1 NEW_V sql_plan_hash_value_1 FOR A10 NOPRI;
COL sql_plan_hash_value_2 NEW_V sql_plan_hash_value_2 FOR A10 NOPRI;
COL sql_plan_hash_value_3 NEW_V sql_plan_hash_value_3 FOR A10 NOPRI;
COL sql_plan_hash_value_4 NEW_V sql_plan_hash_value_4 FOR A10 NOPRI;
COL sql_plan_hash_value_5 NEW_V sql_plan_hash_value_5 FOR A10 NOPRI;
--
WITH
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_plan_hash_value,
       ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) top_phv
  FROM dba_hist_active_sess_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND sql_id = '&&cs_sql_id.'
 GROUP BY
       sql_plan_hash_value
)
SELECT TO_CHAR(MAX(CASE top_phv WHEN 1 THEN sql_plan_hash_value END)) sql_plan_hash_value_1,
       TO_CHAR(MAX(CASE top_phv WHEN 2 THEN sql_plan_hash_value END)) sql_plan_hash_value_2,
       TO_CHAR(MAX(CASE top_phv WHEN 3 THEN sql_plan_hash_value END)) sql_plan_hash_value_3,
       TO_CHAR(MAX(CASE top_phv WHEN 4 THEN sql_plan_hash_value END)) sql_plan_hash_value_4,
       TO_CHAR(MAX(CASE top_phv WHEN 5 THEN sql_plan_hash_value END)) sql_plan_hash_value_5
  FROM my_query
 WHERE top_phv BETWEEN 1 AND 4
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'DB and CPU Average Active Sessions (AAS), between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF xaxis_title = ' SQL_ID:"&&cs_sql_id." granularity:"&&cs2_granularity."';
DEF vaxis_title = 'Average Active Sessions (AAS)';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: false,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_2 = "<br>2) Granularity: &&cs2_granularity. [{5MI}|SS|MI|15MI|HH|DD]";
DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_granularity." "&&cs_sql_id."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'&&sql_plan_hash_value_1. DB'        
PRO ,'&&sql_plan_hash_value_1. CPU'      
PRO ,'&&sql_plan_hash_value_2. DB'        
PRO ,'&&sql_plan_hash_value_2. CPU'      
PRO ,'&&sql_plan_hash_value_3. DB'        
PRO ,'&&sql_plan_hash_value_3. CPU'      
PRO ,'&&sql_plan_hash_value_4. DB'        
PRO ,'&&sql_plan_hash_value_4. CPU'      
PRO ,'&&sql_plan_hash_value_5. DB'        
PRO ,'&&sql_plan_hash_value_5. CPU'      
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
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
       ROUND(24 * 3600 * (MAX(CAST(sample_time AS DATE)) - MIN(CAST(sample_time AS DATE))) + 10) interval_secs,
       SUM(CASE WHEN sql_plan_hash_value = TO_NUMBER('&&sql_plan_hash_value_1.') THEN 10 ELSE 0 END) db_1,
       SUM(CASE WHEN sql_plan_hash_value = TO_NUMBER('&&sql_plan_hash_value_1.') AND session_state = 'ON CPU' THEN 10 ELSE 0 END) cpu_1,
       SUM(CASE WHEN sql_plan_hash_value = TO_NUMBER('&&sql_plan_hash_value_2.') THEN 10 ELSE 0 END) db_2,
       SUM(CASE WHEN sql_plan_hash_value = TO_NUMBER('&&sql_plan_hash_value_2.') AND session_state = 'ON CPU' THEN 10 ELSE 0 END) cpu_2,
       SUM(CASE WHEN sql_plan_hash_value = TO_NUMBER('&&sql_plan_hash_value_3.') THEN 10 ELSE 0 END) db_3,
       SUM(CASE WHEN sql_plan_hash_value = TO_NUMBER('&&sql_plan_hash_value_3.') AND session_state = 'ON CPU' THEN 10 ELSE 0 END) cpu_3,
       SUM(CASE WHEN sql_plan_hash_value = TO_NUMBER('&&sql_plan_hash_value_4.') THEN 10 ELSE 0 END) db_4,
       SUM(CASE WHEN sql_plan_hash_value = TO_NUMBER('&&sql_plan_hash_value_4.') AND session_state = 'ON CPU' THEN 10 ELSE 0 END) cpu_4,
       SUM(CASE WHEN sql_plan_hash_value = TO_NUMBER('&&sql_plan_hash_value_5.') THEN 10 ELSE 0 END) db_5,
       SUM(CASE WHEN sql_plan_hash_value = TO_NUMBER('&&sql_plan_hash_value_5.') AND session_state = 'ON CPU' THEN 10 ELSE 0 END) cpu_5
  FROM dba_hist_active_sess_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND sql_id = '&&cs_sql_id.'
 GROUP BY
       ceil_timestamp(sample_time)
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||ROUND(q.db_1 / q.interval_secs, 3)|| 
       ','||ROUND(q.cpu_1 / q.interval_secs, 3)|| 
       ','||ROUND(q.db_2 / q.interval_secs, 3)|| 
       ','||ROUND(q.cpu_2 / q.interval_secs, 3)|| 
       ','||ROUND(q.db_3 / q.interval_secs, 3)|| 
       ','||ROUND(q.cpu_3 / q.interval_secs, 3)|| 
       ','||ROUND(q.db_4 / q.interval_secs, 3)|| 
       ','||ROUND(q.cpu_4 / q.interval_secs, 3)|| 
       ','||ROUND(q.db_5 / q.interval_secs, 3)|| 
       ','||ROUND(q.cpu_5 / q.interval_secs, 3)|| 
       ']'
  FROM my_query q
 ORDER BY
       q.time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = 'Line';
-- disable explorer with "//" when using Pie
DEF cs_chart_option_explorer = '';
-- enable pie options with "" when using Pie
DEF cs_chart_option_pie = '//';
-- use oem colors
DEF cs_oem_colors_series = '//';
DEF cs_oem_colors_slices = '//';
-- for line charts
DEF cs_curve_type = '';
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