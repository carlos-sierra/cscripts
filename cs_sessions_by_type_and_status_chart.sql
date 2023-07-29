----------------------------------------------------------------------------------------
--
-- File name:   cs_sessions_by_type_and_status_chart.sql
--
-- Purpose:     Sessions by Type and Status (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2022/02/14
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sessions_by_type_and_status_chart.sql
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
DEF cs_script_name = 'cs_sessions_by_type_and_status_chart';
DEF cs_hours_range_default = '168';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL machine HEA 'Machine';
SELECT machine, COUNT(*), MIN(snap_time) AS min_snap_time, MAX(snap_time) AS max_snap_time
  FROM &&cs_tools_schema..iod_session
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND &&cs_con_id IN (1, con_id)
 GROUP BY
       machine
 ORDER BY
       machine
/
PRO
PRO 3. Machine (opt):
DEF cs2_machine = '&3.';
UNDEF 3;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'Sessions by Type and Status between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF vaxis_title = 'Sessions';
DEF xaxis_title = 'Sessions &&cs2_machine.';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
--DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_2 = '<br>2) &&xaxis_title.';
DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_machine."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'USER - ACTIVE', id:'1', type:'number'}        
PRO ,{label:'USER - INACTIVE', id:'2', type:'number'}        
PRO ,{label:'RECURSIVE', id:'3', type:'number'}        
PRO ,{label:'BACKGROUND', id:'4', type:'number'}        
PRO ]
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
my_query AS (
SELECT snap_time AS time,
       SUM(CASE WHEN type = 'USER' AND status = 'ACTIVE' THEN 1 ELSE 0 END) AS user_active,
       SUM(CASE WHEN type = 'USER' AND status <> 'ACTIVE' THEN 1 ELSE 0 END) AS user_inactive,
       SUM(CASE WHEN type = 'RECURSIVE' THEN 1 ELSE 0 END) AS recursive,
       SUM(CASE WHEN type = 'BACKGROUND' THEN 1 ELSE 0 END) AS background
  FROM &&cs_tools_schema..iod_session
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs2_machine.' IS NULL OR machine LIKE CHR(37)||'&&cs2_machine.'||CHR(37))
   AND &&cs_con_id IN (1, con_id)
 GROUP BY
       snap_time
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.user_active)|| 
       ','||num_format(q.user_inactive)|| 
       ','||num_format(q.recursive)|| 
       ','||num_format(q.background)|| 
       ']'
  FROM my_query q
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
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--