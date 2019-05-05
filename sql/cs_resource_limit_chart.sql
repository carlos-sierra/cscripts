----------------------------------------------------------------------------------------
--
-- File name:   cs_resource_limit_chart.sql
--
-- Purpose:     Resource Limit Chart from AWR
--
-- Author:      Carlos Sierra
--
-- Version:     2019/01/05
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates, the resource.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_resource_limit_chart.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_secondary.sql
--@@cs_internal/cs_pdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_resource_limit_chart';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
---ALTER SESSION SET container = CDB$ROOT;
--
SELECT resource_name
  FROM dba_hist_resource_limit
 WHERE resource_name IS NOT NULL
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
 GROUP BY
       resource_name
 ORDER BY
       resource_name
/
PRO
PRO 3. Resource Name: 
DEF cs2_resource_name = '&3.';
--
PRO
PRO 4. Value: [{current_utilization}|max_utilization|initial_allocation|limit_value]
DEF cs2_value = '&4.'
COL cs2_value NEW_V cs2_value NOPRI;
SELECT NVL('&&cs2_value.', 'current_utilization') cs2_value FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs2_resource_name._&&cs2_value.' cs_file_name FROM DUAL;
--
DEF report_title = 'Resource Limit: "&&cs2_resource_name. - &&cs2_value."';
DEF chart_title = 'Resource Limit: "&&cs2_resource_name. - &&cs2_value."';
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to.";
DEF vaxis_title = "&&cs2_resource_name.";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
DEF is_stacked = "isStacked: false,";
--DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
--DEF chart_foot_note_2 = "<br>2) Granularity: &&cs2_granularity. [{MI}|SS|HH|DD]";
DEF chart_foot_note_3 = "";
--DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "&&cs_script_name..sql";
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'&&cs2_value.'        
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
resource_limit AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       snap_id,
       current_utilization,
       max_utilization,
       CASE initial_allocation WHEN ' UNLIMITED' THEN -1 ELSE TO_NUMBER(initial_allocation) END initial_allocation,
       CASE limit_value WHEN ' UNLIMITED' THEN -1 ELSE TO_NUMBER(limit_value) END limit_value
  FROM dba_hist_resource_limit
 WHERE resource_name = '&&cs2_resource_name.'
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
),
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.snap_id,
       CAST(s.begin_interval_time AS DATE) begin_time,
       CAST(s.end_interval_time AS DATE) end_time,
       r.&&cs2_value. value
  FROM dba_hist_snapshot s,
       resource_limit r
 WHERE s.dbid = TO_NUMBER('&&cs_dbid.')
   AND s.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND s.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND r.snap_id = s.snap_id
)
SELECT ', [new Date('||
       TO_CHAR(q.end_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.end_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.end_time, 'DD')|| /* day */
       ','||TO_CHAR(q.end_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.end_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.end_time, 'SS')|| /* second */
       ')'||
       ','||q.value|| 
       ']'
  FROM my_query q
 ORDER BY
       snap_id
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
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_resource_name." "&&cs2_value."
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--