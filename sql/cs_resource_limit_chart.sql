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
---COL cs2_pdb_name NEW_V cs2_pdb_name FOR A30 NOPRI;
---SELECT SYS_CONTEXT('USERENV', 'CON_NAME') cs2_pdb_name FROM DUAL;
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
SELECT '&&cs_file_prefix._&&cs2_resource_name._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "Resource Limit: &&cs2_resource_name.";
DEF chart_title = "Resource Limit: &&cs2_resource_name.";
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to.";
DEF vaxis_title = "&&cs2_resource_name.";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
DEF is_stacked = "isStacked: false,";
--DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:0";
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
PRO ,'Current Utilization'        
PRO ,'Max Utilization'      
PRO ,'Initial Allocation'    
PRO ,'Limit Value'       
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
resource_limit AS (
SELECT /*+ NO_MERGE */
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
SELECT /*+ NO_MERGE */
       s.snap_id,
       CAST(s.begin_interval_time AS DATE) begin_time,
       CAST(s.end_interval_time AS DATE) end_time,
       r.current_utilization,
       r.max_utilization,
       r.initial_allocation,
       r.limit_value
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
       ','||q.current_utilization|| 
       ','||q.max_utilization|| 
       ','||q.initial_allocation|| 
       ','||q.limit_value|| 
       ']'
  FROM my_query q
 ORDER BY
       snap_id
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area]
DEF cs_chart_type = 'Line';
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO scp &&cs_host_name.:&&cs_file_prefix._*_&&cs_reference_sanitized._*.* &&cs_local_dir.
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_resource_name."
--
--ALTER SESSION SET CONTAINER = &&cs2_pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--