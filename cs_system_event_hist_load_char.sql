----------------------------------------------------------------------------------------
--
-- File name:   cs_system_event_hist_load_char.sql
--
-- Purpose:     Subset of System Event AAS Load from AWR (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/10/27
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_system_event_hist_load_char.sql
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
DEF cs_script_name = 'cs_system_event_hist_load_char';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
ALTER SESSION SET container = CDB$ROOT;
--
COL perc FOR 990.0;
COL waited_seconds FOR 999,999,999,990;
COL total_waits FOR 999,999,999,990;
COL avg_wait_ms FOR 999,990.000;
COL aas FOR 990.000;
COL wait_class FOR A14;
COL event_name FOR A64;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF perc aas waited_seconds total_waits ON REPORT;
--
PRO
PRO Top 50 wait events between &&cs_begin_date_from. and &&cs_end_date_to. (and after startup on &&cs_startup_time.)
PRO ~~~~~~~~~~~~~~~~~~
SELECT 100 * (e.time_waited_micro - b.time_waited_micro) / SUM(e.time_waited_micro - b.time_waited_micro) OVER () perc,
       (e.time_waited_micro - b.time_waited_micro) / 1e6 / TO_NUMBER('&&cs_begin_end_seconds.') aas,
       (e.time_waited_micro - b.time_waited_micro) / 1e3 / (e.total_waits - b.total_waits) avg_wait_ms,
       e.wait_class,
       e.event_name,
       (e.time_waited_micro - b.time_waited_micro) / 1e6 waited_seconds,
       (e.total_waits - b.total_waits) total_waits
  FROM dba_hist_system_event b,
       dba_hist_system_event e
 WHERE b.dbid = TO_NUMBER('&&cs_dbid.')
   AND b.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND b.snap_id = GREATEST(TO_NUMBER('&&cs_snap_id_from.'), TO_NUMBER('&&cs_startup_snap_id.')) 
   AND b.wait_class <> 'Idle'
   AND e.dbid = TO_NUMBER('&&cs_dbid.')
   AND e.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND e.snap_id = TO_NUMBER('&&cs_snap_id_to.')
   AND e.wait_class <> 'Idle'
   AND e.event_id = b.event_id
   AND e.event_name = b.event_name
   AND e.wait_class_id = b.wait_class_id
   AND e.wait_class = b.wait_class
   AND e.time_waited_micro > b.time_waited_micro
   AND e.total_waits > b.total_waits
 ORDER BY
       e.time_waited_micro - b.time_waited_micro DESC
FETCH FIRST 50 ROWS ONLY
/
--
CLEAR BREAK COMPUTE;
PRO
PRO 3. Enter 1st Event Name: 
DEF evnt_nam_1 = '&3.';
UNDEF 3;
DEF wait_class_1 = '';
COL wait_class_1 NEW_V wait_class_1 NOPRI;
SELECT wait_class wait_class_1 FROM dba_hist_system_event WHERE event_name = '&&evnt_nam_1.' AND ROWNUM = 1
/
PRO
PRO 4. Enter 2nd Event Name: (opt)
DEF evnt_nam_2 = '&4.';
UNDEF 4;
DEF wait_class_2 = '';
COL wait_class_2 NEW_V wait_class_2 NOPRI;
SELECT wait_class wait_class_2 FROM dba_hist_system_event WHERE event_name = '&&evnt_nam_2.' AND ROWNUM = 1
/
PRO
PRO 5. Enter 3rd Event Name: (opt)
DEF evnt_nam_3 = '&5.';
UNDEF 5;
DEF wait_class_3 = '';
COL wait_class_3 NEW_V wait_class_3 NOPRI;
SELECT wait_class wait_class_3 FROM dba_hist_system_event WHERE event_name = '&&evnt_nam_3.' AND ROWNUM = 1
/
PRO
PRO 6. Enter 4th Event Name: (opt)
DEF evnt_nam_4 = '&6.';
UNDEF 6;
DEF wait_class_4 = '';
COL wait_class_4 NEW_V wait_class_4 NOPRI;
SELECT wait_class wait_class_4 FROM dba_hist_system_event WHERE event_name = '&&evnt_nam_4.' AND ROWNUM = 1
/
PRO
PRO 7. Enter 5th Event Name: (opt)
DEF evnt_nam_5 = '&7.';
UNDEF 7;
DEF wait_class_5 = '';
COL wait_class_5 NEW_V wait_class_5 NOPRI;
SELECT wait_class wait_class_5 FROM dba_hist_system_event WHERE event_name = '&&evnt_nam_5.' AND ROWNUM = 1
/
PRO
PRO 8. Enter 6th Event Name: (opt)
DEF evnt_nam_6 = '&8.';
UNDEF 8;
DEF wait_class_6 = '';
COL wait_class_6 NEW_V wait_class_6 NOPRI;
SELECT wait_class wait_class_6 FROM dba_hist_system_event WHERE event_name = '&&evnt_nam_6.' AND ROWNUM = 1
/
PRO
PRO 9. Graph Type: [{SteppedArea}|Line|Area|Scatter] note: SteppedArea and Area are stacked 
DEF graph_type = '&9.';
UNDEF 9;
COL cs_graph_type NEW_V cs_graph_type NOPRI;
SELECT CASE WHEN '&&graph_type.' IN ('SteppedArea', 'Line', 'Area', 'Scatter') THEN '&&graph_type.' ELSE 'SteppedArea' END AS cs_graph_type FROM DUAL
/
PRO
PRO 10. Trendlines Type: &&cs_trendlines_types.
DEF cs_trendlines_type = '&10.';
UNDEF 10;
COL cs_trendlines_type NEW_V cs_trendlines_type NOPRI;
COL cs_trendlines NEW_V cs_trendlines NOPRI;
COL cs_hAxis_maxValue NEW_V cs_hAxis_maxValue NOPRI;
SELECT CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential', 'none') THEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) ELSE 'none' END AS cs_trendlines_type,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) = 'none' THEN '//' END AS cs_trendlines,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential') THEN '&&cs_hAxis_maxValue.' END AS cs_hAxis_maxValue
  FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "System Event History - Load in AAS";
DEF chart_title = "System Event History - Load in AAS";
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to.";
DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
DEF cs_trendlines_series = ", 0:{}, 1:{}, 2:{}, 3:{}, 4:{}, 5:{}";
DEF vaxis_title = "Average Active Sessions (AAS)";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&evnt_nam_1." "&&evnt_nam_2." "&&evnt_nam_3." "&&evnt_nam_4." "&&evnt_nam_5." "&&evnt_nam_6." "&&cs_graph_type." "&&cs_trendlines_type."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'&&wait_class_1. - &&evnt_nam_1.', id:'1', type:'number'}
PRO ,{label:'&&wait_class_2. - &&evnt_nam_2.', id:'2', type:'number'}
PRO ,{label:'&&wait_class_3. - &&evnt_nam_3.', id:'3', type:'number'}
PRO ,{label:'&&wait_class_4. - &&evnt_nam_4.', id:'4', type:'number'}
PRO ,{label:'&&wait_class_5. - &&evnt_nam_5.', id:'5', type:'number'}
PRO ,{label:'&&wait_class_6. - &&evnt_nam_6.', id:'6', type:'number'}
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
system_event_history AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       snap_id,
       event_name,
       (time_waited_micro - LAG(time_waited_micro) OVER (PARTITION BY event_name ORDER BY snap_id)) / 1e6 waited_seconds
  FROM dba_hist_system_event
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') - 1 AND TO_NUMBER('&&cs_snap_id_to.')
   AND (wait_class = '&&wait_class_1.' OR wait_class = '&&wait_class_2.' OR wait_class = '&&wait_class_3.' OR wait_class = '&&wait_class_4.' OR wait_class = '&&wait_class_5.' OR wait_class = '&&wait_class_6.')
   AND (event_name = '&&evnt_nam_1.' OR event_name = '&&evnt_nam_2.' OR event_name = '&&evnt_nam_3.' OR event_name = '&&evnt_nam_4.' OR event_name = '&&evnt_nam_5.' OR event_name = '&&evnt_nam_6.')
),
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       CAST(s.end_interval_time AS DATE) time,
       (CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 24 * 3600 interval_seconds,
       SUM(CASE WHEN event_name = '&&evnt_nam_1.' THEN waited_seconds ELSE 0 END) waited_seconds_1,
       SUM(CASE WHEN event_name = '&&evnt_nam_2.' THEN waited_seconds ELSE 0 END) waited_seconds_2,
       SUM(CASE WHEN event_name = '&&evnt_nam_3.' THEN waited_seconds ELSE 0 END) waited_seconds_3,
       SUM(CASE WHEN event_name = '&&evnt_nam_4.' THEN waited_seconds ELSE 0 END) waited_seconds_4,
       SUM(CASE WHEN event_name = '&&evnt_nam_5.' THEN waited_seconds ELSE 0 END) waited_seconds_5,
       SUM(CASE WHEN event_name = '&&evnt_nam_6.' THEN waited_seconds ELSE 0 END) waited_seconds_6
  FROM system_event_history h,
       dba_hist_snapshot s
 WHERE h.waited_seconds >= 0
   AND s.snap_id = h.snap_id
   AND s.dbid = TO_NUMBER('&&cs_dbid.')
   AND s.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND s.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
 GROUP BY
       s.begin_interval_time,
       s.end_interval_time
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.waited_seconds_1 / q.interval_seconds, 3)|| 
       ','||num_format(q.waited_seconds_2 / q.interval_seconds, 3)|| 
       ','||num_format(q.waited_seconds_3 / q.interval_seconds, 3)|| 
       ','||num_format(q.waited_seconds_4 / q.interval_seconds, 3)|| 
       ','||num_format(q.waited_seconds_5 / q.interval_seconds, 3)|| 
       ','||num_format(q.waited_seconds_6 / q.interval_seconds, 3)|| 
       ']'
  FROM my_query q
 WHERE q.interval_seconds > 0
 ORDER BY
       q.time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = '&&cs_graph_type.';
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
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--