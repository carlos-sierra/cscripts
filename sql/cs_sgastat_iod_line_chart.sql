----------------------------------------------------------------------------------------
--
-- File name:   cs_sgastat_iod_line_chart.sql
--
-- Purpose:     SGA Pools History Chart from IOD
--
-- Author:      Carlos Sierra
--
-- Version:     2019/01/02
--
-- Usage:       Execute connected to CDB
--
--              Enter range of dates.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sgastat_iod_line_chart.sql
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
DEF cs_script_name = 'cs_sgastat_iod_line_chart';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL cs2_pdb_name NEW_V cs2_pdb_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') cs2_pdb_name FROM DUAL;
ALTER SESSION SET container = CDB$ROOT;
--
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "SGA Pool Stats IOD";
DEF chart_title = "SGA Pools";
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to.";
DEF vaxis_title = "GBs";
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
PRO ,'Buffer Cache'    
PRO ,'Shared Pool'       
PRO ,'Large Pool'        
PRO ,'Java Pool'   
PRO ,'Streams Pool'   
PRO ,'Shared IO Pool'
PRO ,'Shared Pool Free Memory'       
PRO ,'Large Pool Free Memory'        
PRO ,'Java Pool Free Memory'   
PRO ,'Streams Pool Free Memory'   
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
sgastat AS (
SELECT snap_time,
       ROUND(SUM(CASE WHEN name = 'buffer_cache' AND pool IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) buffer_cache,
       ROUND(SUM(CASE WHEN name = 'log_buffer' AND pool IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) log_buffer,
       ROUND(SUM(CASE WHEN name = 'shared_io_pool' AND pool IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) shared_io_pool,
       ROUND(SUM(CASE WHEN name = 'fixed_sga' AND pool IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) fixed_sga,
       ROUND(SUM(CASE WHEN pool = 'shared pool' AND name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) shared_pool,
       ROUND(SUM(CASE WHEN pool = 'shared pool' AND name = 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) shared_pool_free_memory,
       ROUND(SUM(CASE WHEN pool = 'large pool'  AND name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) large_pool,
       ROUND(SUM(CASE WHEN pool = 'large pool' AND name = 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) large_pool_free_memory,
       ROUND(SUM(CASE WHEN pool = 'java pool' AND name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) java_pool,
       ROUND(SUM(CASE WHEN pool = 'java pool' AND name = 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) java_pool_free_memory,
       ROUND(SUM(CASE WHEN pool = 'streams pool' AND name IS NULL THEN bytes ELSE 0 END)/POWER(2,30), 3) streams_pool,
       ROUND(SUM(CASE WHEN pool = 'streams pool' AND name = 'free memory' THEN bytes ELSE 0 END)/POWER(2,30), 3) streams_pool_free_memory
  FROM c##iod.iod_sgastat
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format')
 GROUP BY
       snap_time
)
SELECT ', [new Date('||
       TO_CHAR(q.snap_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.snap_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.snap_time, 'DD')|| /* day */
       ','||TO_CHAR(q.snap_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.snap_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.snap_time, 'SS')|| /* second */
       ')'||
       ','||q.buffer_cache|| 
       ','||q.shared_pool|| 
       ','||q.large_pool|| 
       ','||q.java_pool|| 
       ','||q.streams_pool|| 
       ','||q.shared_io_pool|| 
       ','||q.shared_pool_free_memory|| 
       ','||q.large_pool_free_memory|| 
       ','||q.java_pool_free_memory|| 
       ','||q.streams_pool_free_memory|| 
       ']'
  FROM sgastat q
 ORDER BY
       q.snap_time
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
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."
--
ALTER SESSION SET CONTAINER = &&cs2_pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--