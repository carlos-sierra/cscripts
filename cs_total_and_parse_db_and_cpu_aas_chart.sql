----------------------------------------------------------------------------------------
--
-- File name:   cs_total_and_parse_db_and_cpu_aas_chart.sql
--
-- Purpose:     Total and Parse DB and CPU Average Active Sessions (AAS) from AWR (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/08/06
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_total_and_parse_db_and_cpu_aas_chart.sql
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
DEF cs_script_name = 'cs_total_and_parse_db_and_cpu_aas_chart';
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
PRO 4. SQL_ID (opt): 
DEF cs_sql_id = '&4.';
UNDEF 4;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'DB and CPU Average Active Sessions (AAS), between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF xaxis_title = 'granularity:"&&cs2_granularity." SQL_ID:"&&cs_sql_id."';
DEF vaxis_title = 'Average Active Sessions (AAS)';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: false,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_2 = "<br>2) Granularity: &&cs2_granularity. [{5MI}|SS|MI|15MI|HH|DD]";
DEF chart_foot_note_3 = "<br>3) Target Ratio is 100. A Ratio of 25 means: from elapsed time, only 25% is consumed on CPU (service), while 75% was overhead (waiting).";
DEF chart_foot_note_4 = "<br>";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_granularity." "&&cs_sql_id."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'Total DB', id:'1', type:'number'}        
PRO ,{label:'Total CPU', id:'2', type:'number'}      
PRO ,{label:'Parse DB', id:'3', type:'number'}        
PRO ,{label:'Parse CPU', id:'4', type:'number'}      
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
FUNCTION num_format (p_number IN NUMBER, p_round IN NUMBER DEFAULT 0) 
RETURN VARCHAR2 IS
BEGIN
  IF p_number IS NULL OR ROUND(p_number, p_round) <= 0 THEN
    RETURN 'null';
  ELSE
    RETURN TO_CHAR(ROUND(p_number, p_round));
  END IF;
END num_format;
/****************************************************************************************/
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
       10 * COUNT(*) total_db_secs, 
       SUM(CASE session_state WHEN 'ON CPU' THEN 10 ELSE 0 END) total_cpu_secs,
       SUM(CASE in_parse WHEN 'Y' THEN 10 ELSE 0 END) parse_db_secs, 
       SUM(CASE WHEN in_parse = 'Y' AND session_state = 'ON CPU' THEN 10 ELSE 0 END) parse_cpu_secs
  FROM dba_hist_active_sess_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND ('&&cs_sql_id.' IS NULL OR sql_id = '&&cs_sql_id.')
   AND sql_id IS NOT NULL
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
       ','||num_format(q.total_db_secs / q.interval_secs, 3)|| 
       ','||num_format(q.total_cpu_secs / q.interval_secs, 3)|| 
       ','||num_format(q.parse_db_secs / q.interval_secs, 3)|| 
       ','||num_format(q.parse_cpu_secs / q.interval_secs, 3)|| 
       ']'
  FROM my_query q
 WHERE q.total_db_secs > 0 
   AND q.interval_secs > 0
 ORDER BY
       q.time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = 'Scatter';
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