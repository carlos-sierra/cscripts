----------------------------------------------------------------------------------------
--
-- File name:   cs_cpu_forecast_chart.sql
--
-- Purpose:     CBO Foreceast Chart
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/14
--
-- Usage:       Execute connected to CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_cpu_forecast_chart.sql
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
DEF cs_script_name = 'cs_cpu_forecast_chart';
DEF days_of_history = '60';
DEF forecast_days = '20';
--
ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "CPU Cores Utilization Forecast";
DEF chart_title = "CPU Cores Utilization Forecast";
DEF xaxis_title = "";
DEF vaxis_title = "CPU Cores Busy (%)";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2) Target of 100% means all CPU Cores are Busy";
DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'Utilization Percent'
PRO ,'Moving 1d Window'
PRO ,'Linear Regression'
PRO ,'Forecast'
PRO ,'Target'
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
  WITH 
  busy_time_ts AS (
  SELECT o.snap_id,
         CAST(s.end_interval_time AS DATE) end_date_time,
         CAST(s.startup_time AS DATE) - (LAG(CAST(s.startup_time AS DATE)) OVER (ORDER BY o.snap_id)) startup_gap,
         ((o.value - LAG(o.value) OVER (ORDER BY o.snap_id)) / 100) /
         ((CAST(s.end_interval_time AS DATE) - CAST(LAG(s.end_interval_time) OVER (ORDER BY o.snap_id) AS DATE)) * 24 * 60 * 60)
         cores_busy
    FROM dba_hist_osstat o,
         dba_hist_snapshot s
   WHERE o.dbid = (SELECT dbid FROM v$database)
     AND o.instance_number = SYS_CONTEXT('USERENV', 'INSTANCE')
     AND o.stat_name = 'BUSY_TIME'
     AND s.snap_id = o.snap_id
     AND s.dbid = o.dbid
     AND s.instance_number = o.instance_number
     AND s.end_interval_time > SYSDATE - &&days_of_history.
  ),
  cpu_util_ts1 AS (
  SELECT u.snap_id,
         u.end_date_time,
         ROW_NUMBER() OVER (ORDER BY u.end_date_time ASC) row_number_asc,
         ROW_NUMBER() OVER (ORDER BY u.end_date_time DESC) row_number_desc,
         100 * u.cores_busy / c.value y1,
         AVG(100 * u.cores_busy / c.value) OVER (ORDER BY u.end_date_time RANGE BETWEEN INTERVAL '1' DAY PRECEDING AND CURRENT ROW) y2
    FROM busy_time_ts u,
         v$osstat c
   WHERE u.startup_gap = 0
     AND u.cores_busy > 0
     AND c.con_id = 0
     AND c.stat_name = 'NUM_CPU_CORES'
  ),
  lower_bound AS (
  SELECT end_date_time, y1, y2
    FROM cpu_util_ts1
   WHERE row_number_asc = 1
  ),
  upper_bound AS (
  SELECT end_date_time, y1, y2
    FROM cpu_util_ts1
   WHERE row_number_desc = 1
  ),
  cpu_util_ts2 AS (
  SELECT u.snap_id,
         u.end_date_time,
         u.row_number_desc,
         u.row_number_asc,
         (u.end_date_time - b.end_date_time) x,
         u.y1, u.y2 
    FROM cpu_util_ts1 u,
         lower_bound b
  ),
  linear_regr_ts AS (
  SELECT snap_id,
         end_date_time, 
         row_number_desc,
         row_number_asc,
         x,
         y1, y2,
         REGR_SLOPE(y1, x) OVER () m,
         REGR_INTERCEPT(y1, x) OVER () b
    FROM cpu_util_ts2
  ),
  linear_regr AS (
  SELECT m, -- slope
         b -- intercept
    FROM linear_regr_ts
   WHERE row_number_desc = 1 -- it does not matter which row we get (first, last, or anything in between)
  ),
  cpu_util_ts3 AS (
  SELECT u.end_date_time,
         u.x,
         u.y1, u.y2,
         (r.m * u.x) + r.b y8 /* y8 = (m * x) + b */
    FROM cpu_util_ts2 u,
         linear_regr r
  ),
  cpu_util_ts4 AS (
  SELECT q.end_date_time,
         q.x,
         q.y1, 
         q.y2,
         q.y8,
         CASE WHEN q.end_date_time = u.end_date_time THEN q.y8 ELSE TO_NUMBER(NULL) END y9
    FROM cpu_util_ts3 q, upper_bound u
   UNION ALL
  SELECT (u.end_date_time + LEVEL) end_date_time,
         LEVEL x,
         TO_NUMBER(NULL) y1,
         TO_NUMBER(NULL) y2,
         TO_NUMBER(NULL) y8,
         (r.m * LEVEL + z.y8) y9
    FROM upper_bound u, 
         cpu_util_ts3 z,
         linear_regr r
   WHERE z.end_date_time = u.end_date_time
  CONNECT BY LEVEL <= &&forecast_days.
  )
  SELECT ', [new Date('||
         TO_CHAR(q.end_date_time, 'YYYY')|| /* year */
         ','||(TO_NUMBER(TO_CHAR(q.end_date_time, 'MM')) - 1)|| /* month - 1 */
         ','||TO_CHAR(q.end_date_time, 'DD')|| /* day */
         ','||TO_CHAR(q.end_date_time, 'HH24')|| /* hour */
         ','||TO_CHAR(q.end_date_time, 'MI')|| /* minute */
         ','||TO_CHAR(q.end_date_time, 'SS')|| /* second */
         ')'||
         ','||ROUND(q.y1, 3)||
         ','||ROUND(q.y2, 3)||
         ','||ROUND(q.y8, 3)||
         ','||ROUND(q.y9, 3)||
         ',100'||
         ']'
    FROM cpu_util_ts4 q
   WHERE NVL(q.y1, 0) >= 0
   ORDER BY
         q.end_date_time
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
