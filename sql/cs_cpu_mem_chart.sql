----------------------------------------------------------------------------------------
--
-- File name:   cs_cpu_mem_chart.sql
--
-- Purpose:     CPU Chart from Memory
--
-- Author:      Carlos Sierra
--
-- Version:     2019/03/24
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_cpu_mem_chart.sql
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
DEF cs_script_name = 'cs_cpu_mem_chart';
--
--ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "Recent CPU Utilization";
DEF chart_title = "Recent CPU Utilization";
DEF xaxis_title = "";
DEF vaxis_title = "CPU Threads or Active Sessions";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: false,";
DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
--DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2) AS: Active Sessions, AAS: Average AS, Scheduler: DB Resource Manager";
DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "&&cs_script_name..sql";
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'Max DB CPU Demand (AS on CPU + Scheduler)'
PRO ,'Host CPU Usage (Threads)'        
PRO ,'DB CPU Usage (Threads)'        
PRO ,'DB Foreground CPU Usage (Threads)'        
PRO ,'DB Background CPU Usage (Threads)'        
PRO ,'Avg DB CPU Demand (AAS on CPU + Scheduler)'        
PRO ,'AAS on CPU'        
PRO ,'AAS on Scheduler'        
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
sysmetric_history AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       TRUNC(end_time, 'MI') end_time,
       ROUND(MAX(CASE metric_name WHEN 'Host CPU Usage Per Sec' THEN value ELSE 0 END) / 100, 3) host_cpu_usage,
       ROUND(MAX(CASE metric_name WHEN 'CPU Usage Per Sec' THEN value ELSE 0 END) / 100, 3) foreground_cpu_usage,
       ROUND(MAX(CASE metric_name WHEN 'Background CPU Usage Per Sec' THEN value ELSE 0 END) / 100, 3) background_cpu_usage
  FROM v$sysmetric_history
 WHERE metric_name IN ('Host CPU Usage Per Sec', 'CPU Usage Per Sec', 'Background CPU Usage Per Sec')
   AND group_id = 2 -- 1 minute
 GROUP BY
       TRUNC(end_time, 'MI')
),
active_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       CAST(sample_time AS DATE) sample_date,
       COUNT(*) as_on_cpu_or_scheduler,
       SUM(CASE session_state WHEN 'ON CPU' THEN 1 ELSE 0 END) as_on_cpu,
       SUM(CASE wait_class WHEN 'Scheduler' THEN 1 ELSE 0 END) as_scheduler
  FROM v$active_session_history
 WHERE sample_time >= (SELECT /*+ MATERIALIZE NO_MERGE */ CAST(MIN(end_time) AS TIMESTAMP) FROM sysmetric_history)
   AND sample_time < (SELECT /*+ MATERIALIZE NO_MERGE */ CAST(MAX(end_time) + (1/24/60) AS TIMESTAMP) FROM sysmetric_history)
   AND (session_state = 'ON CPU' OR wait_class = 'Scheduler')
 GROUP BY
       CAST(sample_time AS DATE)
),
average_active_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       TO_CHAR(TRUNC(sample_date, 'MI')) end_time,
       MAX(as_on_cpu_or_scheduler) max_as_on_cpu_or_scheduler,
       ROUND(SUM(as_on_cpu) / 60, 3) aas_on_cpu,
       ROUND(SUM(as_scheduler) / 60, 3) aas_scheduler
  FROM active_sessions
 GROUP BY
       TO_CHAR(TRUNC(sample_date, 'MI'))
),
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       m.end_time + (1/24/60) time,
       a.max_as_on_cpu_or_scheduler,
       m.host_cpu_usage,
       m.foreground_cpu_usage,
       m.background_cpu_usage,
       a.aas_on_cpu,
       a.aas_scheduler
  FROM sysmetric_history m,
       average_active_sessions a
 WHERE a.end_time = m.end_time
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||q.max_as_on_cpu_or_scheduler|| 
       ','||q.host_cpu_usage|| 
       ','||(q.foreground_cpu_usage + q.background_cpu_usage)|| 
       ','||q.foreground_cpu_usage|| 
       ','||q.background_cpu_usage|| 
       ','||(q.aas_on_cpu + q.aas_scheduler)|| 
       ','||q.aas_on_cpu|| 
       ','||q.aas_scheduler|| 
       ']'
  FROM my_query q
 ORDER BY
       q.time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|Scatter]
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
PRO SQL> @&&cs_script_name..sql 
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--