----------------------------------------------------------------------------------------
--
-- File name:   cs_pdb_cpu_iod_chart.sql
--
-- Purpose:     AAS on CPU percentiles for one PDB as per IOD metadata (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/25
--
-- Usage:       Execute connected to PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_pdb_cpu_iod_chart.sql
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
DEF cs_script_name = 'cs_pdb_cpu_iod_chart';
DEF cs_time_bucket = 'W';
DEF cs_forecast_days = '30';
DEF cs_trendlines_types = '[{none}|linear|polynomial|exponential]'
DEF cs_trendlines_type = 'linear';
COL cs_hAxis_maxValue NEW_V cs_hAxis_maxValue NOPRI;
SELECT 'maxValue: new Date('||
       TO_CHAR(SYSDATE + &&cs_forecast_days., 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(SYSDATE + &&cs_forecast_days., 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(SYSDATE + &&cs_forecast_days., 'DD')|| /* day */
       ','||TO_CHAR(SYSDATE + &&cs_forecast_days., 'HH24')|| /* hour */
       ','||TO_CHAR(SYSDATE + &&cs_forecast_days., 'MI')|| /* minute */
       ','||TO_CHAR(SYSDATE + &&cs_forecast_days., 'SS')|| /* second */
       '), ' AS cs_hAxis_maxValue
  FROM DUAL
/
--
ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'Sessions on CPU';
DEF chart_title = '&&report_title.';
DEF xaxis_title = 'PDB:&&cs_con_name.';
DEF vaxis_title = 'Sessions on CPU';
DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
DEF cs_trendlines_series = ", 0:{}, 1:{}, 2:{}, 3:{}, 4:{}, 5:{}";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'Avg', id:'1', type:'number'}
PRO ,{label:'p90', id:'2', type:'number'}
PRO ,{label:'p95', id:'3', type:'number'}
PRO ,{label:'p97', id:'4', type:'number'}
PRO ,{label:'p99', id:'5', type:'number'}
PRO ,{label:'Max', id:'6', type:'number'}
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
snap AS (
 SELECT /*+ MATERIALIZE NO_MERGE */
        snap_time, COUNT(*) AS sessions
   FROM &&cs_tools_schema..iod_session_hist
  WHERE con_id = &&cs_con_id.
    AND type = 'USER'
    AND status = 'ACTIVE'
    AND state <> 'WAITING'
  GROUP BY
        snap_time
),
by_time_bucket AS (
SELECT  TRUNC(snap_time, '&&cs_time_bucket.') AS time,
        ROUND(AVG(sessions),1) AS aas,
        PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY sessions) AS p90,
        PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY sessions) AS p95,
        PERCENTILE_DISC(0.97) WITHIN GROUP (ORDER BY sessions) AS p97,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY sessions) AS p99,
        MAX(sessions) AS p100
  FROM  snap
  GROUP BY
        TRUNC(snap_time, '&&cs_time_bucket.')
)
SELECT  ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.aas, 1)|| 
      --  ','||(q.p90 - q.aas)|| 
      --  ','||(q.p95 - q.p90)|| 
      --  ','||(q.p97 - q.p95)|| 
      --  ','||(q.p99 - q.p97)|| 
      --  ','||(q.p100 - q.p99)|| 
       ','||num_format(q.p90)|| 
       ','||num_format(q.p95)|| 
       ','||num_format(q.p97)|| 
       ','||num_format(q.p99)|| 
       ','||num_format(q.p100)||
       ']'
  FROM  by_time_bucket q
  ORDER BY
        q.time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
-- DEF cs_chart_type = 'SteppedArea';
DEF cs_chart_type = 'Scatter';
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