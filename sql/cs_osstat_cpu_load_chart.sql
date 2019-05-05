----------------------------------------------------------------------------------------
--
-- File name:   cs_osstat_cpu_load_chart.sql
--
-- Purpose:     Chart of OS Stats from AWR
--
-- Author:      Carlos Sierra
--
-- Version:     2019/04/20
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_osstat_cpu_load_chart.sql
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
DEF cs_script_name = 'cs_osstat_cpu_load_chart';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'CPU Demand between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF xaxis_title = '';
DEF vaxis_title = 'Processes and Sessions';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2) Load: Number of OS processes running or waiting on the run queue";
DEF chart_foot_note_3 = "<br>3) DBRM: Number of database sessions requesting CPU and waiting on Resource Manager Scheduler";
DEF chart_foot_note_4 = "<br>4) CPU Demand: Load + DBRM (number of sessions running or waiting for CPU)<br>";
DEF report_foot_note = "&&cs_script_name..sql";
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'CPU Cores'        
PRO ,'CPU Threads'  
PRO ,'Threads Busy'    
PRO ,'Load'    
PRO ,'DBRM'       
PRO ,'CPU Demand'        
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
osstat AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       CAST(s.begin_interval_time AS DATE) begin_time,
       CAST(s.end_interval_time AS DATE) end_time,
       (CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 24 * 3600 seconds,
       h.stat_name,
       CASE 
         WHEN h.stat_name IN ('NUM_CPUS','LOAD','NUM_CPU_CORES') THEN value
         WHEN h.stat_name LIKE '%TIME' THEN h.value - LAG(h.value) OVER (PARTITION BY h.stat_name ORDER BY h.snap_id) 
         ELSE 0
       END value,
       ROW_NUMBER() OVER (PARTITION BY h.stat_name ORDER BY h.snap_id) row_number
  FROM dba_hist_osstat h,
       dba_hist_snapshot s
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND h.stat_name IN ('NUM_CPUS','IDLE_TIME','BUSY_TIME','USER_TIME','SYS_TIME','IOWAIT_TIME','NICE_TIME','RSRC_MGR_CPU_WAIT_TIME','LOAD','NUM_CPU_CORES')
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
),
my_query AS (
SELECT end_time time,
       ROUND(SUM(CASE stat_name WHEN 'LOAD' THEN value ELSE 0 END), 1) load,
       SUM(CASE stat_name WHEN 'NUM_CPU_CORES' THEN value ELSE 0 END) cores,
       SUM(CASE stat_name WHEN 'NUM_CPUS' THEN value ELSE 0 END) cpus,
       ROUND(SUM(CASE stat_name WHEN 'IDLE_TIME' THEN value / 100 / seconds ELSE 0 END), 1) idle,
       ROUND(SUM(CASE stat_name WHEN 'BUSY_TIME' THEN value / 100 / seconds ELSE 0 END), 1) busy,
       ROUND(SUM(CASE stat_name WHEN 'USER_TIME' THEN value / 100 / seconds ELSE 0 END), 1) usr,
       ROUND(SUM(CASE stat_name WHEN 'SYS_TIME' THEN value / 100 / seconds ELSE 0 END), 1) sys,
       ROUND(SUM(CASE stat_name WHEN 'IOWAIT_TIME' THEN value / 100 / seconds ELSE 0 END), 1) io,
       ROUND(SUM(CASE stat_name WHEN 'NICE_TIME' THEN value / 100 / seconds ELSE 0 END), 1) nice,
       ROUND(SUM(CASE stat_name WHEN 'RSRC_MGR_CPU_WAIT_TIME' THEN value / 100 / seconds ELSE 0 END), 1) dbrm
  FROM osstat
 WHERE row_number > 1 -- remove first row
   AND value >= 0
   AND seconds > 0
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
       ','||q.cores|| 
       ','||q.cpus|| 
       ','||q.busy|| 
       ','||q.load|| 
       ','||q.dbrm|| 
       ','||(q.load + q.dbrm)|| 
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
DEF cs_oem_colors_series = '';
DEF cs_oem_colors_slices = '//';
-- for line charts
DEF cs_curve_type = '';
--
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--