----------------------------------------------------------------------------------------
--
-- File name:   cs_sysstat_hist_chart_io.sql
--
-- Purpose:     IO System Statistics from AWR (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/19
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sysstat_hist_chart_io.sql
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
DEF cs_script_name = 'cs_sysstat_hist_chart_io';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
PRO
PRO 3. Metric: [{MBPS}|IOPS]
DEF metric_filter = '&3.';
UNDEF 3;
COL cs_metric_filter NEW_V cs_metric_filter NOPRI;
SELECT CASE NVL(UPPER(TRIM('&&metric_filter.')), 'MBPS') WHEN 'MBPS' THEN 'MBPS' ELSE 'IOPS' END AS cs_metric_filter FROM DUAL
/
COL metric_name_1 NEW_V metric_name_1 NOPRI;
COL metric_name_2 NEW_V metric_name_2 NOPRI;
COL metric_name_3 NEW_V metric_name_3 NOPRI;
SELECT CASE '&&cs_metric_filter.' WHEN 'IOPS' THEN 'RW_IOPS' ELSE 'RW_MBPS' END AS metric_name_1,
       CASE '&&cs_metric_filter.' WHEN 'IOPS' THEN 'R_IOPS' ELSE 'R_MBPS' END AS metric_name_2,
       CASE '&&cs_metric_filter.' WHEN 'IOPS' THEN 'W_IOPS' ELSE 'W_MBPS' END AS metric_name_3
FROM   DUAL
/
--
PRO
PRO 4. Graph Type: [{SteppedArea}|Line|Area|Scatter] note: SteppedArea and Area are stacked 
DEF graph_type = '&4.';
UNDEF 4;
COL cs_graph_type NEW_V cs_graph_type NOPRI;
SELECT CASE WHEN '&&graph_type.' IN ('SteppedArea', 'Line', 'Area', 'Scatter') THEN '&&graph_type.' ELSE 'SteppedArea' END AS cs_graph_type FROM DUAL
/
PRO
PRO 5. Trendlines Type: &&cs_trendlines_types.
DEF cs_trendlines_type = '&5.';
UNDEF 5;
COL cs_trendlines_type NEW_V cs_trendlines_type NOPRI;
COL cs_trendlines NEW_V cs_trendlines NOPRI;
COL cs_hAxis_maxValue NEW_V cs_hAxis_maxValue NOPRI;
SELECT CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential', 'none') THEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) ELSE 'none' END AS cs_trendlines_type,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) = 'none' THEN '//' END AS cs_trendlines,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential') THEN '&&cs_hAxis_maxValue.' END AS cs_hAxis_maxValue
  FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_metric_filter.' cs_file_name FROM DUAL;
--
DEF report_title = "System Statistics (&&cs_metric_filter.)";
DEF chart_title = "System Statistics (&&cs_metric_filter.)";
DEF xaxis_title = "&&cs_metric_filter. between &&cs_sample_time_from. and &&cs_sample_time_to.";
DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
DEF cs_trendlines_series = ", 0:{}, 1:{}, 2:{}, 3:{}";
DEF vaxis_title = "&&cs_metric_filter.";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_metric_filter." "&&cs_graph_type." "&&cs_trendlines_type."';
--
@@cs_internal/cs_spool_head_chart.sql
--
-- PRO ,{label:'&&metric_name_1.', id:'1', type:'number'}
PRO ,{label:'&&metric_name_2.', id:'2', type:'number'}
PRO ,{label:'&&metric_name_3.', id:'3', type:'number'}     
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
sysstat_io (
       snap_id, end_interval_time, elapsed_sec, r_reqs, w_reqs, r_bytes, w_bytes
) AS (
       SELECT h.snap_id,
              s.end_interval_time,
              (CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 86400 AS elapsed_sec,
              SUM(CASE WHEN h.stat_name = 'physical read total IO requests' THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name = 'physical read total IO requests' THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS r_reqs,
              SUM(CASE WHEN h.stat_name IN ('physical write total IO requests', 'redo writes') THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name IN ('physical write total IO requests', 'redo writes') THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS w_reqs,
              SUM(CASE WHEN h.stat_name = 'physical read total bytes' THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name = 'physical read total bytes' THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS r_bytes,
              SUM(CASE WHEN h.stat_name IN ('physical write total bytes', 'redo size') THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name IN ('physical write total bytes', 'redo size') THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS w_bytes
       FROM   dba_hist_sysstat h,
              dba_hist_snapshot s
       WHERE  h.dbid = TO_NUMBER('&&cs_dbid.')
       AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
       AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
       AND h.stat_name IN ('physical read total IO requests', 'physical write total IO requests', 'redo writes', 'physical read total bytes', 'physical write total bytes', 'redo size')
       AND s.snap_id = h.snap_id
       AND s.dbid = h.dbid
       AND s.instance_number = h.instance_number
       AND s.end_interval_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
       GROUP BY
              h.snap_id,
              s.begin_interval_time,
              s.end_interval_time
),
io_per_sec (
       snap_id, end_interval_time, r_iops, w_iops, r_mbps, w_mbps
) AS (
       SELECT snap_id,
              end_interval_time,
              ROUND(r_reqs / elapsed_sec) AS r_iops,
              ROUND(w_reqs / elapsed_sec) AS w_iops,
              ROUND(r_bytes / elapsed_sec / POWER(10, 6)) AS r_mbps,
              ROUND(w_bytes / elapsed_sec / POWER(10, 6)) AS w_mbps
       FROM   sysstat_io
       WHERE  elapsed_sec > 60 -- ignore snaps too close
       AND    r_reqs + w_reqs + r_bytes + w_bytes > 0 -- avoid nulls
)
SELECT ', [new Date('||
       TO_CHAR(q.end_interval_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.end_interval_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.end_interval_time, 'DD')|| /* day */
       ','||TO_CHAR(q.end_interval_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.end_interval_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.end_interval_time, 'SS')|| /* second */
       ')'||
       --','||CASE '&&cs_metric_filter.' WHEN 'IOPS' THEN num_format(q.r_iops + q.w_iops) ELSE num_format(q.r_mbps + q.w_mbps) END|| 
       ','||CASE '&&cs_metric_filter.' WHEN 'IOPS' THEN num_format(q.r_iops) ELSE num_format(q.r_mbps) END|| 
       ','||CASE '&&cs_metric_filter.' WHEN 'IOPS' THEN num_format(q.w_iops) ELSE num_format(q.w_mbps) END|| 
       ']'
  FROM io_per_sec q
 ORDER BY
       q.end_interval_time
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
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--