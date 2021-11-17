----------------------------------------------------------------------------------------
--
-- File name:   cs_some_sysmetric_for_cdb_hist_chart.sql
--
-- Purpose:     Some System Metrics as per DBA_HIST_SYSMETRIC_SUMMARY View for a CDB (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/11/09
--
-- Usage:       Execute connected to CDB and pass range of AWR snapshots then select some metrics.
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_some_sysmetric_for_cdb_hist_chart.sql
--
-- Notes:       Developed and tested on 12.1.0.2 and 19c.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF view_name = 'v$sysmetric';
DEF common_predicate = "SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT'";
DEF cs_script_name = 'cs_some_sysmetric_for_cdb_hist_chart';
DEF cs_hours_range_default = '168';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
ALTER SESSION SET container = CDB$ROOT;
--
COL metric_name FOR A45 TRUN;
COL metric_unit FOR A41 TRUN;
SELECT metric_name,
       metric_unit,
       value
  FROM &&view_name.
 WHERE &&common_predicate.
   AND group_id = 2
 ORDER BY
       metric_name
/
PRO
PRO 3. Filter on Metric Name or Unit (e.g. sessions, blocks, redo, undo, commit, transaction, bytes, sec, txn, logon, call, %, etc.):
DEF metric_filter = '&3.';
UNDEF 3;
--
SELECT metric_name,
       metric_unit,
       value
  FROM &&view_name.
 WHERE &&common_predicate.
   AND group_id = 2
   AND CASE '&&metric_filter.'
       WHEN '%' THEN CASE WHEN metric_name||metric_unit LIKE '%\%%' ESCAPE '\' THEN 1 END
       ELSE CASE WHEN UPPER(metric_name||metric_unit) LIKE UPPER('%&&metric_filter.%') THEN 1 END
       END = 1
 ORDER BY
       metric_name
/
PRO
PRO 4. Enter 1st Metric Name:
DEF metric_name_1 = '&4.';
UNDEF 4;
--
COL cs_metric_unit_1 NEW_V cs_metric_unit_1 NOPRI;
SELECT metric_unit cs_metric_unit_1 FROM &&view_name. WHERE metric_name = '&&metric_name_1.' AND ROWNUM = 1
/
--
SELECT metric_name,
       metric_unit,
       value
  FROM &&view_name.
 WHERE &&common_predicate.
   AND group_id = 2
   AND UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_1.%') 
   AND metric_name NOT IN ('&&metric_name_1.')
 ORDER BY
       metric_name
/
PRO
PRO Enter additional optional Metric Names, consistent with Metric Unit of "&&cs_metric_unit_1."
PRO
PRO 5. Enter 2nd Metric Name: (opt)
DEF metric_name_2 = '&5.';
UNDEF 5;
--
COL cs_metric_unit_2 NEW_V cs_metric_unit_2 NOPRI;
SELECT metric_unit cs_metric_unit_2 FROM &&view_name. WHERE metric_name = '&&metric_name_2.' AND ROWNUM = 1
/
--
SELECT metric_name,
       metric_unit,
       value
  FROM &&view_name.
 WHERE &&common_predicate.
   AND group_id = 2
   AND (UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_1.%') OR UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_2.%'))
   AND metric_name NOT IN ('&&metric_name_1.', '&&metric_name_2.')
 ORDER BY
       metric_name
/
PRO
PRO 6. Enter 3rd Metric Name: (opt)
DEF metric_name_3 = '&6.';
UNDEF 6;
--
COL cs_metric_unit_3 NEW_V cs_metric_unit_3 NOPRI;
SELECT metric_unit cs_metric_unit_3 FROM &&view_name. WHERE metric_name = '&&metric_name_3.' AND ROWNUM = 1
/
--
SELECT metric_name,
       metric_unit,
       value
  FROM &&view_name.
 WHERE &&common_predicate.
   AND group_id = 2
   AND (UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_1.%') OR UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_2.%') OR UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_3.%'))
   AND metric_name NOT IN ('&&metric_name_1.', '&&metric_name_2.', '&&metric_name_3.')
 ORDER BY
       metric_name
/
PRO
PRO 7. Enter 4th Metric Name: (opt)
DEF metric_name_4 = '&7.';
UNDEF 7;
--
COL cs_metric_unit_4 NEW_V cs_metric_unit_4 NOPRI;
SELECT metric_unit cs_metric_unit_4 FROM &&view_name. WHERE metric_name = '&&metric_name_4.' AND ROWNUM = 1
/
--
SELECT metric_name,
       metric_unit,
       value
  FROM &&view_name.
 WHERE &&common_predicate.
   AND group_id = 2
   AND (UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_1.%') OR UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_2.%') OR UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_3.%') OR UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_4.%'))
   AND metric_name NOT IN ('&&metric_name_1.', '&&metric_name_2.', '&&metric_name_3.', '&&metric_name_4.')
 ORDER BY
       metric_name
/
PRO
PRO 8. Enter 5th Metric Name: (opt)
DEF metric_name_5 = '&8.';
UNDEF 8;
--
COL cs_metric_unit_5 NEW_V cs_metric_unit_5 NOPRI;
SELECT metric_unit cs_metric_unit_5 FROM &&view_name. WHERE metric_name = '&&metric_name_5.' AND ROWNUM = 1
/
--
SELECT metric_name,
       metric_unit,
       value
  FROM &&view_name.
 WHERE &&common_predicate.
   AND group_id = 2
   AND (UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_1.%') OR UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_2.%') OR UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_3.%') OR UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_4.%') OR UPPER(metric_unit) LIKE UPPER('%&&cs_metric_unit_5.%'))
   AND metric_name NOT IN ('&&metric_name_1.', '&&metric_name_2.', '&&metric_name_3.', '&&metric_name_4.', '&&metric_name_5.')
 ORDER BY
       metric_name
/
PRO
PRO 9. Enter 6th Metric Name: (opt)
DEF metric_name_6 = '&9.';
UNDEF 9;
PRO
PRO 10. Value: [{average}|maxval]
DEF cs_value = '&10.';
UNDEF 10;
COL cs_value NEW_V cs_value NOPRI;
SELECT CASE WHEN LOWER(TRIM('&&cs_value.')) IN ('average', 'maxval') THEN LOWER(TRIM('&&cs_value.')) ELSE 'average' END cs_value FROM DUAL
/
PRO
PRO 11. Graph Type: [{SteppedArea}|Line|Area|Scatter] note: SteppedArea and Area are stacked 
DEF graph_type = '&11.';
UNDEF 11;
COL cs_graph_type NEW_V cs_graph_type NOPRI;
SELECT CASE WHEN '&&graph_type.' IN ('SteppedArea', 'Line', 'Area', 'Scatter') THEN '&&graph_type.' ELSE 'SteppedArea' END AS cs_graph_type FROM DUAL
/
PRO
PRO 12. Trendlines Type: &&cs_trendlines_types.
DEF cs_trendlines_type = '&12.';
UNDEF 12;
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
DEF report_title = "CDB System Metrics (&&cs_value.)";
DEF chart_title = "CDB System Metrics (&&cs_value.)";
DEF xaxis_title = "&&cs_value. between &&cs_sample_time_from. and &&cs_sample_time_to.";
DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
DEF cs_trendlines_series = ", 0:{}, 1:{}, 2:{}, 3:{}, 4:{}, 5:{}";
DEF vaxis_title = "&&cs_metric_unit_1.";
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
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&metric_filter." "&&metric_name_1." "&&metric_name_2." "&&metric_name_3." "&&metric_name_4." "&&metric_name_5." "&&metric_name_6." "&&cs_value." "&&cs_graph_type." "&&cs_trendlines_type."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'&&metric_name_1.', id:'1', type:'number'}
PRO ,{label:'&&metric_name_2.', id:'2', type:'number'}
PRO ,{label:'&&metric_name_3.', id:'3', type:'number'}
PRO ,{label:'&&metric_name_4.', id:'4', type:'number'}
PRO ,{label:'&&metric_name_5.', id:'5', type:'number'}
PRO ,{label:'&&metric_name_6.', id:'6', type:'number'}     
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
sysmetric_history AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       end_time,
       metric_name, 
       &&cs_value. value
  FROM dba_hist_sysmetric_summary
 WHERE metric_name IN ('&&metric_name_1.', '&&metric_name_2.', '&&metric_name_3.', '&&metric_name_4.', '&&metric_name_5.', '&&metric_name_6.')
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND end_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
),
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       end_time time,
       SUM(CASE metric_name WHEN '&&metric_name_1.' THEN value ELSE 0 END) metric_name_1,
       SUM(CASE metric_name WHEN '&&metric_name_2.' THEN value ELSE 0 END) metric_name_2,
       SUM(CASE metric_name WHEN '&&metric_name_3.' THEN value ELSE 0 END) metric_name_3,
       SUM(CASE metric_name WHEN '&&metric_name_4.' THEN value ELSE 0 END) metric_name_4,
       SUM(CASE metric_name WHEN '&&metric_name_5.' THEN value ELSE 0 END) metric_name_5,
       SUM(CASE metric_name WHEN '&&metric_name_6.' THEN value ELSE 0 END) metric_name_6
  FROM sysmetric_history
 GROUP BY
       end_time
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.metric_name_1)|| 
       ','||num_format(q.metric_name_2)|| 
       ','||num_format(q.metric_name_3)|| 
       ','||num_format(q.metric_name_4)|| 
       ','||num_format(q.metric_name_5)|| 
       ','||num_format(q.metric_name_6)|| 
       ']'
  FROM my_query q
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