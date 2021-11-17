----------------------------------------------------------------------------------------
--
-- File name:   cs_system_event_histogram_chart.sql
--
-- Purpose:     One System Event AAS Load Histogram from AWR as per Latency Bucket (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/10/27
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_system_event_histogram_chart.sql
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
DEF cs_script_name = 'cs_system_event_histogram_chart';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
ALTER SESSION SET container = CDB$ROOT;
--
COL perc FOR 990.0;
COL waited_seconds FOR 999,999,999,990;
COL total_waits FOR 999,999,999,990;
COL avg_wait_ms FOR 999,990.000;
COL aas FOR 990.000;
COL wait_class FOR A14;
COL event_name FOR A64;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF perc aas waited_seconds total_waits ON REPORT;
--
PRO
PRO Top 30 wait events between &&cs_begin_date_from. and &&cs_end_date_to. (and after startup on &&cs_startup_time.)
PRO ~~~~~~~~~~~~~~~~~~
SELECT 100 * (e.time_waited_micro - b.time_waited_micro) / SUM(e.time_waited_micro - b.time_waited_micro) OVER () perc,
       (e.time_waited_micro - b.time_waited_micro) / 1e6 / TO_NUMBER('&&cs_begin_end_seconds.') aas,
       (e.time_waited_micro - b.time_waited_micro) / 1e3 / (e.total_waits - b.total_waits) avg_wait_ms,
       e.wait_class,
       e.event_name,
       (e.time_waited_micro - b.time_waited_micro) / 1e6 waited_seconds,
       (e.total_waits - b.total_waits) total_waits
  FROM dba_hist_system_event b,
       dba_hist_system_event e
 WHERE b.dbid = TO_NUMBER('&&cs_dbid.')
   AND b.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND b.snap_id = GREATEST(TO_NUMBER('&&cs_snap_id_from.'), TO_NUMBER('&&cs_startup_snap_id.')) 
   AND b.wait_class <> 'Idle'
   AND e.dbid = TO_NUMBER('&&cs_dbid.')
   AND e.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND e.snap_id = TO_NUMBER('&&cs_snap_id_to.')
   AND e.wait_class <> 'Idle'
   AND e.event_id = b.event_id
   AND e.event_name = b.event_name
   AND e.wait_class_id = b.wait_class_id
   AND e.wait_class = b.wait_class
   AND e.time_waited_micro > b.time_waited_micro
   AND e.total_waits > b.total_waits
 ORDER BY
       e.time_waited_micro - b.time_waited_micro DESC
FETCH FIRST 30 ROWS ONLY
/
--
CLEAR BREAK COMPUTE;
PRO
PRO 3. Event Name:
DEF event_name_1 = '&3.';
UNDEF 3;
DEF wait_class_1 = '';
COL wait_class_1 NEW_V wait_class_1 NOPRI;
SELECT wait_class wait_class_1 FROM dba_hist_system_event WHERE event_name = '&&event_name_1.' AND ROWNUM = 1
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "System Event Histogram for: &&wait_class_1 - &&event_name_1.";
DEF chart_title = "System Event Histogram for: &&wait_class_1 - &&event_name_1.";
DEF xaxis_title = "Wait Time buckets (in ms) between &&cs_sample_time_from. and &&cs_sample_time_to.";
DEF vaxis_title = "Average Active Sessions (AAS)";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&event_name_1."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'>65536'     , id:'01', type:'number'}   
PRO ,{label:'32768-65536', id:'02', type:'number'}        
PRO ,{label:'16384-32768', id:'03', type:'number'}        
PRO ,{label:'8192-16384' , id:'04', type:'number'}       
PRO ,{label:'4096-8192'  , id:'05', type:'number'}      
PRO ,{label:'2048-4096'  , id:'06', type:'number'}      
PRO ,{label:'1024-2048'  , id:'07', type:'number'}      
PRO ,{label:'512-1024'   , id:'08', type:'number'}     
PRO ,{label:'256-512'    , id:'09', type:'number'}    
PRO ,{label:'128-256'    , id:'10', type:'number'}    
PRO ,{label:'64-128'     , id:'11', type:'number'}   
PRO ,{label:'32-64'      , id:'12', type:'number'}  
PRO ,{label:'16-32'      , id:'13', type:'number'}  
PRO ,{label:'8-16'       , id:'14', type:'number'} 
PRO ,{label:'4-8'        , id:'15', type:'number'}
PRO ,{label:'2-4'        , id:'16', type:'number'}
PRO ,{label:'1-2'        , id:'17', type:'number'}
PRO ,{label:'0-1'        , id:'18', type:'number'}
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
event_histogram AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       snap_id,
       wait_time_milli bucket, 
       (CASE wait_time_milli WHEN 1 THEN 0.5 ELSE 0.75 END) * wait_time_milli * (wait_count - LAG(wait_count) OVER (PARTITION BY wait_time_milli ORDER BY snap_id)) / 1e3 seconds
  FROM dba_hist_event_histogram
 WHERE dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') - 1 AND TO_NUMBER('&&cs_snap_id_to.')
   AND wait_class = '&&wait_class_1.'
   AND event_name = '&&event_name_1.'
),
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       CAST(s.end_interval_time AS DATE) time,
       (CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 24 * 3600 interval_seconds,
       SUM(CASE WHEN bucket = POWER(2,0) THEN seconds ELSE 0 END) b01,
       SUM(CASE WHEN bucket = POWER(2,1) THEN seconds ELSE 0 END) b02,
       SUM(CASE WHEN bucket = POWER(2,2) THEN seconds ELSE 0 END) b03,
       SUM(CASE WHEN bucket = POWER(2,3) THEN seconds ELSE 0 END) b04,
       SUM(CASE WHEN bucket = POWER(2,4) THEN seconds ELSE 0 END) b05,
       SUM(CASE WHEN bucket = POWER(2,5) THEN seconds ELSE 0 END) b06,
       SUM(CASE WHEN bucket = POWER(2,6) THEN seconds ELSE 0 END) b07,
       SUM(CASE WHEN bucket = POWER(2,7) THEN seconds ELSE 0 END) b08,
       SUM(CASE WHEN bucket = POWER(2,8) THEN seconds ELSE 0 END) b09,
       SUM(CASE WHEN bucket = POWER(2,9) THEN seconds ELSE 0 END) b10,
       SUM(CASE WHEN bucket = POWER(2,10) THEN seconds ELSE 0 END) b11,
       SUM(CASE WHEN bucket = POWER(2,11) THEN seconds ELSE 0 END) b12,
       SUM(CASE WHEN bucket = POWER(2,12) THEN seconds ELSE 0 END) b13,
       SUM(CASE WHEN bucket = POWER(2,13) THEN seconds ELSE 0 END) b14,
       SUM(CASE WHEN bucket = POWER(2,14) THEN seconds ELSE 0 END) b15,
       SUM(CASE WHEN bucket = POWER(2,15) THEN seconds ELSE 0 END) b16,
       SUM(CASE WHEN bucket = POWER(2,16) THEN seconds ELSE 0 END) b17,
       SUM(CASE WHEN bucket > POWER(2,16) THEN seconds ELSE 0 END) b18
  FROM event_histogram h,
       dba_hist_snapshot s
 WHERE h.seconds > 0
   AND s.snap_id = h.snap_id
   AND s.dbid = TO_NUMBER('&&cs_dbid.')
   AND s.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND s.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
 GROUP BY
       s.begin_interval_time,
       s.end_interval_time
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.b18 / q.interval_seconds, 3)|| 
       ','||num_format(q.b17 / q.interval_seconds, 3)|| 
       ','||num_format(q.b16 / q.interval_seconds, 3)|| 
       ','||num_format(q.b15 / q.interval_seconds, 3)|| 
       ','||num_format(q.b14 / q.interval_seconds, 3)|| 
       ','||num_format(q.b13 / q.interval_seconds, 3)|| 
       ','||num_format(q.b12 / q.interval_seconds, 3)|| 
       ','||num_format(q.b11 / q.interval_seconds, 3)|| 
       ','||num_format(q.b10 / q.interval_seconds, 3)|| 
       ','||num_format(q.b09 / q.interval_seconds, 3)|| 
       ','||num_format(q.b08 / q.interval_seconds, 3)|| 
       ','||num_format(q.b07 / q.interval_seconds, 3)|| 
       ','||num_format(q.b06 / q.interval_seconds, 3)|| 
       ','||num_format(q.b05 / q.interval_seconds, 3)|| 
       ','||num_format(q.b04 / q.interval_seconds, 3)|| 
       ','||num_format(q.b03 / q.interval_seconds, 3)|| 
       ','||num_format(q.b02 / q.interval_seconds, 3)|| 
       ','||num_format(q.b01 / q.interval_seconds, 3)|| 
       ']'
  FROM my_query q
 WHERE q.interval_seconds > 0
 ORDER BY
       q.time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = 'SteppedArea';
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
--