----------------------------------------------------------------------------------------
--
-- File name:   cs_df_u02_chart.sql
--
-- Purpose:     Disk FileSystem u02 Utilization Chart
--
-- Author:      Carlos Sierra
--
-- Version:     2020/06/14
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
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(snap_time)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM c##iod.iod_df_u02
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
PRO ,'FileSystem u02 TB Space'
PRO ,'FileSystem u02 TB Used'
PRO ,'Database TB Allocated'
PRO ,'Database TB Used'
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
df_hh AS (
SELECT snap_time, u02_size, u02_used, u02_available, host_name,
       ROW_NUMBER() OVER (PARTITION BY TRUNC(snap_time, 'HH') ORDER BY u02_size DESC NULLS LAST, u02_used DESC NULLS LAST) AS rn
  FROM c##iod.iod_df_u02
 WHERE snap_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND snap_time < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
),
df_u02 AS (
SELECT ROUND(snap_time, 'HH') AS snap_time,
       ROUND((u02_used + u02_available) * 1024 / POWER(10, 12), 3) AS tb_space,
       ROUND(u02_used * 1024 / POWER(10, 12), 3) AS tb_used
  FROM df_hh
 WHERE rn = 1
),
ts_hh AS (
SELECT snap_time, SUM(oem_allocated_space_mbs) AS oem_allocated_space_mbs, SUM(oem_used_space_mbs) AS oem_used_space_mbs,
       ROW_NUMBER() OVER (PARTITION BY TRUNC(snap_time, 'HH') ORDER BY SUM(oem_allocated_space_mbs) DESC NULLS LAST, SUM(oem_used_space_mbs) DESC NULLS LAST) AS rn
  FROM c##iod.tablespaces_hist
 WHERE snap_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND snap_time < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 GROUP BY
       snap_time
),
ts_space AS (
SELECT ROUND(snap_time, 'HH') AS snap_time,
       ROUND(oem_allocated_space_mbs * POWER(2, 20) / POWER(10, 12), 3) AS tb_allocated,
       ROUND(oem_used_space_mbs * POWER(2, 20) / POWER(10, 12), 3) AS tb_used
  FROM ts_hh
 WHERE rn = 1
),
my_query AS (
SELECT df.snap_time,
       df.tb_space AS df_tb_space,
       df.tb_used AS df_tb_used,
       ts.tb_allocated AS db_tb_allocated,
       ts.tb_used AS db_tb_used
  FROM df_u02 df,
       ts_space ts
 WHERE ts.snap_time = df.snap_time
)
SELECT ', [new Date('||
       TO_CHAR(q.snap_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.snap_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.snap_time, 'DD')|| /* day */
       ','||TO_CHAR(q.snap_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.snap_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.snap_time, 'SS')|| /* second */
       ')'||
       ','||q.df_tb_space|| 
       ','||q.df_tb_used|| 
       ','||q.db_tb_allocated|| 
       ','||q.db_tb_used|| 
       ']'
  FROM my_query q
 ORDER BY
       q.snap_time
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
