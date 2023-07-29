----------------------------------------------------------------------------------------
--
-- File name:   cs_ash_mem_peaks_bubble.sql
--
-- Purpose:     ASH Peaks Bubble from MEM
--
-- Author:      Carlos Sierra
--
-- Version:     2022/05/25
--
-- Usage:       Execute connected to CDB or PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_ash_mem_peaks_bubble.sql
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
DEF cs_script_name = 'cs_ash_mem_peaks_bubble';
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
PRO
PRO 4. Dimension [{GLOBAL}|SQL_ID|WAIT_CLASS|TIMED_EVENT|PDB]
DEF dimension = '&4.';
UNDEF 4;
COL dimension NEW_V dimension NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&dimension.')) IN ('GLOBAL', 'SQL_ID', 'WAIT_CLASS', 'TIMED_EVENT', 'PDB') THEN UPPER(TRIM('&&dimension.')) ELSE 'GLOBAL' END AS dimension FROM DUAL
/
COL grouping_expression NEW_V grouping_expression NOPRI;
SELECT CASE '&&dimension.'
         WHEN 'GLOBAL' THEN q'[object_type]'
         WHEN 'SQL_ID' THEN q'[statement_id||' '||SUBSTR(remarks, 1, 50)]'
         WHEN 'WAIT_CLASS' THEN q'[CASE operation WHEN 'ON CPU' THEN operation ELSE options END]'
         WHEN 'TIMED_EVENT' THEN q'[CASE operation WHEN 'ON CPU' THEN operation ELSE options||' - '||object_node END]'
         WHEN 'PDB' THEN q'[object_owner||'('||plan_id||')']'
       END AS grouping_expression
FROM DUAL
/
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
DEF include_hist = 'N';
DEF include_mem = 'Y';
SET SERVEROUT OFF;
@@cs_internal/cs_active_sessions_peaks_internal_v5.sql
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&dimension.' cs_file_name FROM DUAL;
--
DEF report_title = "Peaks duration of Active Sessions in Concurrency contention exceeding &&times_cpu_cores.x CPU_CORES by top value - &&dimension.";
DEF chart_title = "&&report_title.";
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to.";
-- DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
-- DEF cs_trendlines_series = ", 0:{}, 1:{}, 2:{}, 3:{}, 4:{}, 5:{}";
DEF vaxis_title = "Maximum Active Sessions";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2) Bubble size indicates duration of contention. Label shows the top#1 contributor.";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&times_cpu_cores." "&&dimension."';
--
DEF spool_chart_1st_column = 'ID';
@@cs_internal/cs_spool_head_chart.sql
PRO , 'Time', 'Total Maximum Active Sessions', 'Top#1 &&dimension.', 'Approximate duration in seconds'
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
-- SELECT ', [''#'||ROW_NUMBER() OVER (ORDER BY cost DESC, timestamp)||' '||cost||''''||
SELECT ', ['''''||
       ', new Date('||
       TO_CHAR(t.timestamp, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(t.timestamp, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(t.timestamp, 'DD')|| /* day */
       ','||TO_CHAR(t.timestamp, 'HH24')|| /* hour */
       ','||TO_CHAR(t.timestamp, 'MI')|| /* minute */
       ','||TO_CHAR(t.timestamp, 'SS')|| /* second */
       ')'||
       ', '||num_format(t.cardinality, 0)|| -- sessions_peak
       ', '''||&&grouping_expression.||''''|| 
       ', '||num_format(t.cost, 0)|| -- seconds
       ']'
  FROM plan_table t
 ORDER BY
       t.cost DESC
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter|Bubble]
DEF cs_chart_type = 'Bubble';
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
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--