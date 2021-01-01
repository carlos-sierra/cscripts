----------------------------------------------------------------------------------------
--
-- File name:   cs_df_u02_chart.sql
--
-- Purpose:     Disk FileSystem u02 Utilization Chart
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/25
--
-- Usage:       Execute connected to CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_df_u02_chart.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_df_u02_chart';
DEF cs_hours_range_default = '4320';
--
ALTER SESSION SET container = CDB$ROOT;
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(timestamp)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM &&cs_tools_schema..dbc_system
/
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO
PRO 3. Trendlines Type: &&cs_trendlines_types.
DEF cs_trendlines_type = '&3.';
UNDEF 3;
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
DEF report_title = "Disk FileSystem u02 and DB Utilization";
DEF chart_title = "";
DEF xaxis_title = "";
DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
DEF cs_trendlines_series = ", 0:{}, 1:{}, 2:{}, 3:{}";
DEF vaxis_title = "Terabytes (TB)";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
DEF is_stacked = "isStacked: true,";
DEF vaxis_baseline = "";
DEF vaxis_viewwindow = ", viewWindow: {min:0}";
DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_trendlines_type."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'FileSystem u02 TB Space', id:'1', type:'number'}
PRO ,{label:'FileSystem u02 TB Used', id:'2', type:'number'}
PRO ,{label:'Database TB Allocated', id:'3', type:'number'}
PRO ,{label:'Database TB Used', id:'4', type:'number'}
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
df_hh AS (
SELECT timestamp, u02_size, u02_used, u02_available, host_name,
       ROW_NUMBER() OVER (PARTITION BY TRUNC(timestamp, 'HH') ORDER BY u02_size DESC NULLS LAST, u02_used DESC NULLS LAST) AS rn
  FROM &&cs_tools_schema..dbc_system
 WHERE timestamp >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND timestamp < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
),
df_u02 AS (
SELECT ROUND(timestamp, 'HH') AS timestamp,
       ROUND((u02_used + u02_available) * 1024 / POWER(10, 12), 3) AS tb_space,
       ROUND(u02_used * 1024 / POWER(10, 12), 3) AS tb_used
  FROM df_hh
 WHERE rn = 1
),
ts_hh AS (
SELECT snap_time, SUM(allocated_bytes) AS allocated_bytes, SUM(used_bytes) AS used_bytes,
       ROW_NUMBER() OVER (PARTITION BY TRUNC(snap_time, 'HH') ORDER BY SUM(allocated_bytes) DESC NULLS LAST, SUM(used_bytes) DESC NULLS LAST) AS rn
  FROM &&cs_tools_schema..dbc_tablespaces
 WHERE snap_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND snap_time < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 GROUP BY
       snap_time
),
ts_space AS (
SELECT ROUND(snap_time, 'HH') AS snap_time,
       ROUND(allocated_bytes / POWER(10, 12), 3) AS tb_allocated,
       ROUND(used_bytes / POWER(10, 12), 3) AS tb_used
  FROM ts_hh
 WHERE rn = 1
),
/****************************************************************************************/
my_query AS (
SELECT df.timestamp,
       df.tb_space AS df_tb_space,
       df.tb_used AS df_tb_used,
       ts.tb_allocated AS db_tb_allocated,
       ts.tb_used AS db_tb_used
  FROM df_u02 df,
       ts_space ts
 WHERE ts.snap_time = df.timestamp
)
SELECT ', [new Date('||
       TO_CHAR(q.timestamp, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.timestamp, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.timestamp, 'DD')|| /* day */
       ','||TO_CHAR(q.timestamp, 'HH24')|| /* hour */
       ','||TO_CHAR(q.timestamp, 'MI')|| /* minute */
       ','||TO_CHAR(q.timestamp, 'SS')|| /* second */
       ')'||
       ','||num_format(q.df_tb_space, 3)|| 
       ','||num_format(q.df_tb_used, 3)|| 
       ','||num_format(q.db_tb_allocated, 3)|| 
       ','||num_format(q.db_tb_used, 3)|| 
       ']'
  FROM my_query q
 ORDER BY
       q.timestamp
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
