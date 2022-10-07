----------------------------------------------------------------------------------------
--
-- File name:   cs_sgastat_awr_line_chart.sql
--
-- Purpose:     SGA Pools History Chart from AWR (include free memory)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/08
--
-- Usage:       Execute connected to CDB
--
--              Enter range of dates.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sgastat_awr_line_chart.sql
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
DEF cs_script_name = 'cs_sgastat_awr_line_chart';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "SGA Pool Stats AWR";
DEF chart_title = "SGA Pools";
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to.";
DEF vaxis_title = "GBs";
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
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'PGA Aggregate Target'     , id:'01', type:'number'}  
PRO ,{label:'SGA Target'               , id:'02', type:'number'}  
PRO ,{label:'Buffer Cache'             , id:'03', type:'number'}  
PRO ,{label:'Shared Pool'              , id:'04', type:'number'}  
PRO ,{label:'Large Pool'               , id:'05', type:'number'}  
PRO ,{label:'Java Pool'                , id:'06', type:'number'}  
PRO ,{label:'Streams Pool'             , id:'07', type:'number'}  
PRO ,{label:'Shared IO Pool'           , id:'08', type:'number'}  
PRO ,{label:'Shared Pool Free Memory'  , id:'09', type:'number'}    
PRO ,{label:'Large Pool Free Memory'   , id:'10', type:'number'}    
PRO ,{label:'Java Pool Free Memory'    , id:'11', type:'number'}  
PRO ,{label:'Streams Pool Free Memory' , id:'12', type:'number'}  
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
sgastat AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       snap_id,
       ROUND(SUM(CASE WHEN name = 'buffer_cache' AND pool IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) buffer_cache, -- see bug 18166499
       ROUND(SUM(CASE WHEN name = 'log_buffer' AND pool IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) log_buffer,
       ROUND(SUM(CASE WHEN name = 'shared_io_pool' AND pool IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) shared_io_pool,
       ROUND(SUM(CASE WHEN name = 'fixed_sga' AND pool IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) fixed_sga,
       ROUND(SUM(CASE WHEN pool = 'shared pool' AND name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) shared_pool, -- see bug 18166499
       ROUND(SUM(CASE WHEN pool = 'shared pool' AND name = 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) shared_pool_free_memory,
       ROUND(SUM(CASE WHEN pool = 'large pool'  AND name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) large_pool, -- see bug 18166499
       ROUND(SUM(CASE WHEN pool = 'large pool' AND name = 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) large_pool_free_memory,
       ROUND(SUM(CASE WHEN pool = 'java pool' AND name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) java_pool, -- see bug 18166499
       ROUND(SUM(CASE WHEN pool = 'java pool' AND name = 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) java_pool_free_memory,
       ROUND(SUM(CASE WHEN pool = 'streams pool' AND name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) streams_pool, -- see bug 18166499
       ROUND(SUM(CASE WHEN pool = 'streams pool' AND name = 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) streams_pool_free_memory
  FROM dba_hist_sgastat
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
 GROUP BY
       snap_id
),
param AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       snap_id,
       ROUND(SUM(CASE parameter_name WHEN '__db_cache_size' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) buffer_cache,
       ROUND(SUM(CASE parameter_name WHEN '__shared_io_pool_size' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) shared_io_pool,
       ROUND(SUM(CASE parameter_name WHEN '__shared_pool_size' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) shared_pool,
       ROUND(SUM(CASE parameter_name WHEN '__large_pool_size' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) large_pool,
       ROUND(SUM(CASE parameter_name WHEN '__java_pool_size' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) java_pool,
       ROUND(SUM(CASE parameter_name WHEN '__streams_pool_size' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) streams_pool,
       ROUND(SUM(CASE parameter_name WHEN '__sga_target' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) sga_target,
       ROUND(SUM(CASE parameter_name WHEN '__pga_aggregate_target' THEN TO_NUMBER(value) ELSE 0 END)/POWER(2,30), 3) pga_aggregate_target
  FROM dba_hist_parameter
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND parameter_name IN ('__db_cache_size', '__java_pool_size', '__large_pool_size', '__pga_aggregate_target', '__sga_target', '__shared_io_pool_size', '__shared_pool_size', '__streams_pool_size')
 GROUP BY
       snap_id
),
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.snap_id,
       CAST(s.begin_interval_time AS DATE) begin_time,
       CAST(s.end_interval_time AS DATE) end_time,
       p.pga_aggregate_target,
       p.sga_target,
       p.buffer_cache,
       p.shared_pool,
       p.large_pool,
       p.java_pool,
       p.streams_pool,
       p.shared_io_pool,
       t.shared_pool_free_memory,
       t.large_pool_free_memory,
       t.java_pool_free_memory,
       t.streams_pool_free_memory
  FROM dba_hist_snapshot s,
       sgastat t,
       param p
 WHERE s.dbid = TO_NUMBER('&&cs_dbid.')
   AND s.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND s.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND t.snap_id = s.snap_id
   AND p.snap_id = s.snap_id
)
SELECT ', [new Date('||
       TO_CHAR(q.end_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.end_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.end_time, 'DD')|| /* day */
       ','||TO_CHAR(q.end_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.end_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.end_time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.pga_aggregate_target, 3)|| 
       ','||num_format(q.sga_target, 3)|| 
       ','||num_format(q.buffer_cache, 3)|| 
       ','||num_format(q.shared_pool, 3)|| 
       ','||num_format(q.large_pool, 3)|| 
       ','||num_format(q.java_pool, 3)|| 
       ','||num_format(q.streams_pool, 3)|| 
       ','||num_format(q.shared_io_pool, 3)|| 
       ','||num_format(q.shared_pool_free_memory, 3)|| 
       ','||num_format(q.large_pool_free_memory, 3)|| 
       ','||num_format(q.java_pool_free_memory, 3)|| 
       ','||num_format(q.streams_pool_free_memory, 3)|| 
       ']'
  FROM my_query q
 ORDER BY
       snap_id
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
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--