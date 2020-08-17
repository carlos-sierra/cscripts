----------------------------------------------------------------------------------------
--
-- File name:   cs_timed_event_top_consumers_pie.sql
--
-- Purpose:     Timed Event Top Consumers Chart
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/14
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates, timed event and group by when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_timed_event_top_consumers_pie.sql
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
DEF cs_script_name = 'cs_timed_event_top_consumers_pie';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--ALTER SESSION SET container = CDB$ROOT;
--
COL perc FOR 990.0;
COL waited_seconds FOR 999,999,999,990;
COL total_waits FOR 999,999,999,990;
COL avg_wait_ms FOR 999,990.000;
COL aas FOR 990.000;
COL wait_class FOR A14;
COL event_name FOR A64 HEA 'EVENT';
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF perc aas waited_seconds total_waits ON REPORT;
--
PRO
PRO Top 30 timed events between &&cs_begin_date_from. and &&cs_end_date_to. (and after startup on &&cs_startup_time.)
PRO ~~~~~~~~~~~~~~~~~~~
WITH
top AS (
SELECT 100 * (e.time_waited_micro - b.time_waited_micro) / SUM(e.time_waited_micro - b.time_waited_micro) OVER () perc,
       (e.time_waited_micro - b.time_waited_micro) / 1e6 / TO_NUMBER('&&cs_begin_end_seconds.') aas,
       (e.time_waited_micro - b.time_waited_micro) / 1e3 / (e.total_waits - b.total_waits) avg_wait_ms,
       SUM(e.time_waited_micro - b.time_waited_micro) OVER (PARTITION BY e.wait_class) AS wait_class_time,
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
)
SELECT wait_class,
       event_name,
       perc,
       aas,
       avg_wait_ms,
       waited_seconds,
       total_waits
  FROM top
 ORDER BY
       wait_class_time DESC,
       perc DESC
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO 3. Timed Event: [{all}|WAIT_CLASS|EVENT]
DEF timed_event = '&3.';
UNDEF 3;
COL timed_event NEW_V timed_event NOPRI;
SELECT COALESCE('&&timed_event.','all') AS timed_event FROM DUAL
/
PRO
PRO 4. Group By: [{PDB_NAME}|SQL_ID|TOP_LEVEL_SQL_ID|MACHINE|PROGRAM|MODULE|ACTION|SESSION_ID|USER_ID|WAIT_CLASS|EVENT|CURRENT_OBJ#]
DEF gb_column_name = '&4.';
UNDEF 4;
COL gb_column_name NEW_V gb_column_name NOPRI;
SELECT CASE WHEN '&&gb_column_name.' IN ('PDB_NAME', 'SQL_ID', 'TOP_LEVEL_SQL_ID', 'MACHINE', 'PROGRAM', 'MODULE', 'ACTION', 'SESSION_ID', 'USER_ID', 'WAIT_CLASS', 'EVENT', 'CURRENT_OBJ#') THEN '&&gb_column_name.' ELSE 'PDB_NAME' END AS gb_column_name FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'DB Time Contribution of "&&timed_event." Timed Event(s) by &&gb_column_name. between &&cs_sample_time_from. and &&cs_sample_time_to.';
DEF chart_title = '&&report_title.';
DEF xaxis_title = '';
DEF vaxis_title = '';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
DEF is_stacked = "isStacked: false,";
--DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_1 = "";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&timed_event." "&&gb_column_name."';
--
DEF chart_foot_note_0 = '';
DEF chart_foot_note_1 = '';
-- [Line|Area|SteppedArea|ScatterPie]
DEF cs_chart_type = 'Pie';
DEF cs_chart_width = '900px';
DEF cs_chart_height = '450px';
DEF cs_chartarea_height = '80%';
-- disable explorer with "//" when using Pie
DEF cs_chart_option_explorer = '//';
-- enable pie options with "" when using Pie
DEF cs_chart_option_pie = '';
-- pieSliceText [{percentage}|value|label|none]
DEF cs_chart_pie_slice_text = "// pieSliceText: 'percentage',";
--DEF cs_chart_pie_slice_text = "pieSliceText: 'value',";
-- use oem colors
DEF cs_oem_colors_series = '//';
DEF cs_oem_colors_slices = '//';
-- for line charts
DEF cs_curve_type = '//';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'&&gb_column_name.'      
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
timed_events_samples AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name AS pdb_name,
       h.sql_id, h.top_level_sql_id, h.machine, h.program, h.module, h.action, h.session_id, h.user_id, h.wait_class, h.event, h.current_obj#,
       COUNT(*) as samples
  FROM dba_hist_active_sess_history h,
       v$containers c
 WHERE h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND h.session_state = 'WAITING'
   AND ('&&timed_event.' = 'all' OR UPPER(h.wait_class||h.event) LIKE UPPER('%&&timed_event.%'))
   AND c.con_id = h.con_id
 GROUP BY
       c.name,
       h.sql_id, h.top_level_sql_id, h.machine, h.program, h.module, h.action, h.session_id, h.user_id, h.wait_class, h.event, h.current_obj#
),
aggregated AS (
SELECT &&gb_column_name. AS slice_name,
       SUM(samples) * 10 AS value,
       100 * SUM(samples) / SUM(SUM(samples)) OVER () AS percent
  FROM timed_events_samples
 GROUP BY
       &&gb_column_name.
)
SELECT ', ['''||slice_name||' ('||TRIM(TO_CHAR(percent, '990.0'))||'%)'','||value||']'
  FROM aggregated
 ORDER BY
       value DESC
/
/****************************************************************************************/
SET HEA ON PAGES 100;
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
