----------------------------------------------------------------------------------------
--
-- File name:   cs_ash_mem_peaks_chart.sql
--
-- Purpose:     ASH Peaks Chart from MEM
--
-- Author:      Carlos Sierra
--
-- Version:     2021/12/03
--
-- Usage:       Execute connected to CDB or PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_ash_mem_peaks_chart.sql
--
-- Notes:       Developed and tested on 19c.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_ash_mem_peaks_chart';
DEF cs_hours_range_default = '3';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO To chart on Active Sessions over 1x the number of CPU Cores, then pass "1" (default) as Threshold value below
PRO
PRO 3. Threshold: [{1}|0-10] 
DEF times_cpu_cores = '&3.';
UNDEF 3;
COL times_cpu_cores NEW_V times_cpu_cores NOPRI;
SELECT CASE WHEN TO_NUMBER(REPLACE(UPPER('&&times_cpu_cores.'), 'X')) BETWEEN 0 AND 10 THEN REPLACE(UPPER('&&times_cpu_cores.'), 'X') ELSE '1' END AS times_cpu_cores FROM DUAL
/
DEF include_hist = 'N';
DEF include_mem = 'Y';
--
-- @@cs_internal/&&cs_set_container_to_cdb_root.
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "Active Sessions Peaks";
DEF chart_title = "&&report_title.";
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to.";
-- DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
-- DEF cs_trendlines_series = ", 0:{}, 1:{}, 2:{}, 3:{}, 4:{}, 5:{}";
DEF vaxis_title = "Sum of Active Sessions per sampled time";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
DEF is_stacked = "isStacked: false,";
--DEF is_stacked = "isStacked: true,";
DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
--DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&times_cpu_cores."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'Sessions Peak', id:'1', type:'number'} 
PRO ,{label:'Before Peak', id:'2', type:'number'} 
PRO ,{label:'After Peak', id:'3', type:'number'} 
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
threshold AS (
  SELECT /*+ MATERIALIZE NO_MERGE */ &&times_cpu_cores. * value AS value FROM v$osstat WHERE stat_name = 'NUM_CPU_CORES' AND ROWNUM >= 1 /* MATERIALIZE */
),
active_sessions_time_series AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       COUNT(*) AS active_sessions
  FROM dba_hist_active_sess_history h
 WHERE '&&include_hist.' = 'Y' 
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       h.sample_time
UNION
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_time,
       COUNT(*) AS active_sessions
  FROM v$active_session_history h
 WHERE '&&include_mem.' = 'Y' 
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       h.sample_time
),
time_dim AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_time,
       SUM(active_sessions) AS active_sessions,
       LAG(SUM(active_sessions)) OVER (ORDER BY sample_time) AS lag_active_sessions,
       LEAD(SUM(active_sessions)) OVER (ORDER BY sample_time) AS lead_active_sessions
  FROM active_sessions_time_series
 WHERE ROWNUM >= 1 /* MATERIALIZE */
 GROUP BY
       sample_time
),
t AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       t.sample_time,
       CASE WHEN t.active_sessions >= threshold.value THEN t.active_sessions END AS peak_value,
       CASE WHEN t.active_sessions < threshold.value AND t.lead_active_sessions >= threshold.value THEN t.active_sessions END AS before_value,
       CASE WHEN t.active_sessions < threshold.value AND t.lag_active_sessions >= threshold.value THEN t.active_sessions END AS after_value
  FROM threshold,
       time_dim t
 WHERE (t.active_sessions >= threshold.value OR t.lag_active_sessions >= threshold.value OR t.lead_active_sessions >= threshold.value)
   AND ROWNUM >= 1 /* MATERIALIZE */
)
SELECT ', [new Date('||
       TO_CHAR(t.sample_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(t.sample_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(t.sample_time, 'DD')|| /* day */
       ','||TO_CHAR(t.sample_time, 'HH24')|| /* hour */
       ','||TO_CHAR(t.sample_time, 'MI')|| /* minute */
       ','||TO_CHAR(t.sample_time, 'SS')|| /* second */
       ')'||
       ','||num_format(t.peak_value, 0)|| 
       ','||num_format(t.before_value, 0)|| 
       ','||num_format(t.after_value, 0)|| 
       ']'
  FROM t
 ORDER BY
       t.sample_time
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
DEF cs_curve_type = '//';
--
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO
PRO &&report_foot_note.
--
-- @@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--