----------------------------------------------------------------------------------------
--
-- File name:   cs_dg_redo_dest_resp_histogram_chart.sql
--
-- Purpose:     Data Guard (DG) REDO Transport Duration Chart
--
-- Author:      Carlos Sierra
--
-- Version:     2021/04/27
--
-- Usage:       Execute connected to CDB.
--
--              Enter Source and Destination Hosts when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_dg_redo_dest_resp_histogram_chart.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
--@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_dg_redo_dest_resp_histogram_chart';
DEF cs_hours_range_default = '8760';
--
ALTER SESSION SET container = CDB$ROOT;
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(time)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM &&cs_tools_schema..dbc_redo_dest_histogram
/
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL source_host_name FOR A64 TRUNC;
SELECT DISTINCT host_name AS source_host_name
  FROM &&cs_tools_schema..dbc_redo_dest_histogram
 WHERE time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 ORDER BY 1
/
PRO
PRO 3. Source Host Name: (opt)
DEF s_host_name = '&3.';
UNDEF 3;
--
COL dest_host_name FOR A64 TRUNC;
SELECT DISTINCT dest_host_name
  FROM &&cs_tools_schema..dbc_redo_dest_histogram
 WHERE time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND host_name = NVL('&&s_host_name.', host_name)
 ORDER BY 1
/
PRO
PRO 3. Destination Host Name: (opt)
DEF d_host_name = '&4.';
UNDEF 4;
--
DEF source_dest_host_name = "";
COL source_dest_host_name NEW_V source_dest_host_name NOPRI;
SELECT CASE WHEN '&&s_host_name.' IS NOT NULL THEN 'SRC:&&s_host_name.' END||CASE WHEN '&&s_host_name.&&d_host_name.' IS NOT NULL THEN ' -> ' END||CASE WHEN '&&d_host_name.' IS NOT NULL THEN 'DST:&&d_host_name.' END AS source_dest_host_name FROM DUAL
/
--
COL label1 NEW_V label1 NOPRI;
COL label2 NEW_V label2 NOPRI;
COL label3 NEW_V label3 NOPRI;
COL label4 NEW_V label4 NOPRI;
COL label5 NEW_V label5 NOPRI;
COL label6 NEW_V label6 NOPRI;
WITH 
scope AS (
SELECT host_name||' -> '||dest_host_name AS label, SUM(duration_seconds) AS entries, ROW_NUMBER() OVER (ORDER BY SUM(duration_seconds) DESC) AS rn
  FROM &&cs_tools_schema..dbc_redo_dest_histogram
 WHERE time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND host_name = NVL('&&s_host_name.', host_name)
   AND dest_host_name = NVL('&&d_host_name.', dest_host_name)
 GROUP BY host_name||' -> '||dest_host_name
 ORDER BY 2 DESC NULLS LAST
 FETCH FIRST 6 ROWS ONLY
)
SELECT MAX(CASE rn WHEN 1 THEN label END) AS label1,
       MAX(CASE rn WHEN 2 THEN label END) AS label2,
       MAX(CASE rn WHEN 3 THEN label END) AS label3,
       MAX(CASE rn WHEN 4 THEN label END) AS label4,
       MAX(CASE rn WHEN 5 THEN label END) AS label5,
       MAX(CASE rn WHEN 6 THEN label END) AS label6
  FROM scope
WHERE rn BETWEEN 1 AND 6
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "Data Guard (DG) REDO Transport Duration (v$redo_dest_resp_histogram)";
DEF chart_title = "Data Guard (DG) REDO Transport Duration between &&cs_sample_time_from. and &&cs_sample_time_to. UTC";
DEF xaxis_title = "&&source_dest_host_name.";
DEF vaxis_title = "Duration (Seconds)";
-- DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
-- DEF cs_trendlines_series = ", 0:{}, 1:{}, 2:{}";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
--DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&s_host_name." "&&d_host_name."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'&&label1.', id:'1', type:'number'}
PRO ,{label:'&&label2.', id:'2', type:'number'}
PRO ,{label:'&&label3.', id:'3', type:'number'}
PRO ,{label:'&&label4.', id:'4', type:'number'}
PRO ,{label:'&&label5.', id:'5', type:'number'}
PRO ,{label:'&&label6.', id:'6', type:'number'}
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
my_query AS (
SELECT time AS timestamp,
       CASE host_name||' -> '||dest_host_name WHEN '&&label1.' THEN duration_seconds END AS seconds1,
       CASE host_name||' -> '||dest_host_name WHEN '&&label2.' THEN duration_seconds END AS seconds2,
       CASE host_name||' -> '||dest_host_name WHEN '&&label3.' THEN duration_seconds END AS seconds3,
       CASE host_name||' -> '||dest_host_name WHEN '&&label4.' THEN duration_seconds END AS seconds4,
       CASE host_name||' -> '||dest_host_name WHEN '&&label5.' THEN duration_seconds END AS seconds5,
       CASE host_name||' -> '||dest_host_name WHEN '&&label6.' THEN duration_seconds END AS seconds6
  FROM &&cs_tools_schema..dbc_redo_dest_histogram
 WHERE time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND host_name = NVL('&&s_host_name.', host_name)
   AND dest_host_name = NVL('&&d_host_name.', dest_host_name)
   AND host_name||' -> '||dest_host_name IN ('&&label1.', '&&label2.', '&&label3.', '&&label4.', '&&label5.', '&&label6.')
)
SELECT ', [new Date('||
       TO_CHAR(q.timestamp, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.timestamp, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.timestamp, 'DD')|| /* day */
       ','||TO_CHAR(q.timestamp, 'HH24')|| /* hour */
       ','||TO_CHAR(q.timestamp, 'MI')|| /* minute */
       ','||TO_CHAR(q.timestamp, 'SS')|| /* second */
       ')'||
      ','||num_format(q.seconds1)||
      ','||num_format(q.seconds2)||
      ','||num_format(q.seconds3)||
      ','||num_format(q.seconds4)||
      ','||num_format(q.seconds5)||
      ','||num_format(q.seconds6)||
       ']'
  FROM my_query q
 ORDER BY
       q.timestamp
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
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
