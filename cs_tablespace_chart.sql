----------------------------------------------------------------------------------------
--
-- File name:   cs_tablespace_chart.sql
--
-- Purpose:     Tablespace Utilization (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/25
--
-- Usage:       Execute connected to CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_tablespace_chart.sql
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
DEF cs_script_name = 'cs_tablespace_chart';
DEF cs_hours_range_default = '4320';
--
ALTER SESSION SET container = CDB$ROOT;
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(snap_time)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM &&cs_tools_schema..dbc_tablespaces
/
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
SELECT DISTINCT tablespace_name 
  FROM &&cs_tools_schema..dbc_tablespaces
 WHERE '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
 ORDER BY 1
/
PRO
PRO 3. Enter Tablespace Name (opt):
DEF cs2_tablespace_name = '&3.';
UNDEF 3;
--
PRO
PRO 4. Trendlines Type: &&cs_trendlines_types.
DEF cs_trendlines_type = '&4.';
UNDEF 4;
COL cs_trendlines_type NEW_V cs_trendlines_type NOPRI;
COL cs_trendlines NEW_V cs_trendlines NOPRI;
COL cs_hAxis_maxValue NEW_V cs_hAxis_maxValue NOPRI;
SELECT CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential', 'none') THEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) ELSE 'none' END AS cs_trendlines_type,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) = 'none' THEN '//' END AS cs_trendlines,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential') THEN '&&cs_hAxis_maxValue.' END AS cs_hAxis_maxValue
  FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.'||CASE WHEN '&&cs2_tablespace_name.' IS NOT NULL THEN '_&&cs2_tablespace_name.' END AS cs_file_name FROM DUAL;
--
--DEF report_title = "Disk FileSystem u02 and DB Utilization between &&cs_sample_time_from. and &&cs_sample_time_to. UTC";
DEF report_title = "&&cs2_tablespace_name. Tablespace Utilization";
DEF chart_title = "&&cs2_tablespace_name.";
DEF xaxis_title = "";
DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
DEF cs_trendlines_series = ", 0:{}, 1:{}";
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
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_tablespace_name." "&&cs_trendlines_type."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'Database TB Allocated', id:'1', type:'number'}
PRO ,{label:'Database TB Used', id:'2', type:'number'}
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
ts_hh AS (
SELECT snap_time, SUM(allocated_bytes) AS allocated_bytes, SUM(used_bytes) AS used_bytes, 
       ROW_NUMBER() OVER (PARTITION BY TRUNC(snap_time, 'HH') ORDER BY SUM(allocated_bytes) DESC NULLS LAST, SUM(used_bytes) DESC NULLS LAST) AS rn
  FROM &&cs_tools_schema..dbc_tablespaces
 WHERE snap_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND snap_time < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
   AND ('&&cs2_tablespace_name.' IS NULL OR tablespace_name LIKE '%&&cs2_tablespace_name.%')
 GROUP BY
       snap_time
),
ts_space AS (
SELECT ROUND(snap_time, 'HH') AS snap_time,
       ROUND(allocated_bytes / POWER(10, 12), 3) AS tb_allocated,
       ROUND(used_bytes / POWER(10, 12), 3) AS tb_used
  FROM ts_hh
 WHERE rn = 1
),
/****************************************************************************************/
my_query AS (
SELECT ts.snap_time,
       ts.tb_allocated AS db_tb_allocated,
       ts.tb_used AS db_tb_used
  FROM ts_space ts
)
SELECT ', [new Date('||
       TO_CHAR(q.snap_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.snap_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.snap_time, 'DD')|| /* day */
       ','||TO_CHAR(q.snap_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.snap_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.snap_time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.db_tb_allocated, 3)|| 
       ','||num_format(q.db_tb_used, 3)|| 
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
