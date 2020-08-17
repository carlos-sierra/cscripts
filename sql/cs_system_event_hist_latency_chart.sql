----------------------------------------------------------------------------------------
--
-- File name:   cs_system_event_hist_latency_chart.sql
--
-- Purpose:     System Event Latency Chart from History
--
-- Author:      Carlos Sierra
--
-- Version:     2020/04/21
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_system_event_hist_latency_chart.sql
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
DEF cs_script_name = 'cs_system_event_hist_latency_chart';
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
PRO Top 30 wait events between &&cs_begin_date_from. and &&cs_end_date_to. (and after startup on &&cs_startup_time.)
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
FETCH FIRST 30 ROWS ONLY
/
--
CLEAR BREAK COMPUTE;
PRO
PRO 3. Event Name (1):
DEF event_name_1 = '&3.';
UNDEF 3;
DEF wait_class_1 = '';
COL wait_class_1 NEW_V wait_class_1 NOPRI;
SELECT wait_class wait_class_1 FROM dba_hist_system_event WHERE event_name = '&&event_name_1.' AND ROWNUM = 1
/
PRO
PRO 4. Event Name (2):
DEF event_name_2 = '&4.';
UNDEF 4;
DEF wait_class_2 = '';
COL wait_class_2 NEW_V wait_class_2 NOPRI;
SELECT wait_class wait_class_2 FROM dba_hist_system_event WHERE event_name = '&&event_name_2.' AND ROWNUM = 1
/
PRO
PRO 5. Event Name (3):
DEF event_name_3 = '&5.';
UNDEF 5;
DEF wait_class_3 = '';
COL wait_class_3 NEW_V wait_class_3 NOPRI;
SELECT wait_class wait_class_3 FROM dba_hist_system_event WHERE event_name = '&&event_name_3.' AND ROWNUM = 1
/
PRO
PRO 6. Event Name (4):
DEF event_name_4 = '&6.';
UNDEF 6;
DEF wait_class_4 = '';
COL wait_class_4 NEW_V wait_class_4 NOPRI;
SELECT wait_class wait_class_4 FROM dba_hist_system_event WHERE event_name = '&&event_name_4.' AND ROWNUM = 1
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "System Event History - Latency in ms";
DEF chart_title = "System Event History - Latency in ms";
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to.";
DEF vaxis_title = "Average Latency in ms";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&event_name_1." "&&event_name_2." "&&event_name_3." "&&event_name_4."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'&&wait_class_1. - &&event_name_1.'        
PRO ,'&&wait_class_2. - &&event_name_2.'        
PRO ,'&&wait_class_3. - &&event_name_3.'        
PRO ,'&&wait_class_4. - &&event_name_4.'        
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
system_event_history AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       snap_id,
       event_name,
       (time_waited_micro - LAG(time_waited_micro) OVER (PARTITION BY event_name ORDER BY snap_id)) / 1e3 time_waited_ms,
       (total_waits - LAG(total_waits) OVER (PARTITION BY event_name ORDER BY snap_id)) total_waits
  FROM dba_hist_system_event
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') - 1 AND TO_NUMBER('&&cs_snap_id_to.')
   AND wait_class IN ('&&wait_class_1.', '&&wait_class_2.', '&&wait_class_3.', '&&wait_class_4.')
   AND event_name IN ('&&event_name_1.', '&&event_name_2.', '&&event_name_3.', '&&event_name_4.')
),
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       CAST(s.end_interval_time AS DATE) time,
       (CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 24 * 3600 interval_seconds,
       SUM(CASE event_name WHEN '&&event_name_1.' THEN h.time_waited_ms/GREATEST(h.total_waits,1) ELSE 0 END) latency_1,
       SUM(CASE event_name WHEN '&&event_name_2.' THEN h.time_waited_ms/GREATEST(h.total_waits,1) ELSE 0 END) latency_2,
       SUM(CASE event_name WHEN '&&event_name_3.' THEN h.time_waited_ms/GREATEST(h.total_waits,1) ELSE 0 END) latency_3,
       SUM(CASE event_name WHEN '&&event_name_4.' THEN h.time_waited_ms/GREATEST(h.total_waits,1) ELSE 0 END) latency_4
  FROM system_event_history h,
       dba_hist_snapshot s
 WHERE h.total_waits >= 0
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
       ','||ROUND(q.latency_1, 3)|| 
       ','||ROUND(q.latency_2, 3)|| 
       ','||ROUND(q.latency_3, 3)|| 
       ','||ROUND(q.latency_4, 3)|| 
       ']'
  FROM my_query q
 ORDER BY
       q.time
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