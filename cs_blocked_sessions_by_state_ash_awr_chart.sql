----------------------------------------------------------------------------------------
--
-- File name:   cs_blocked_sessions_by_state_ash_awr_chart.sql
--
-- Purpose:     Top Session Blockers by State of Root Blocker as per ASH from AWR (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/01/17
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_blocked_sessions_by_state_ash_awr_chart.sql
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
DEF cs_script_name = 'cs_blocked_sessions_by_state_ash_awr_chart';
DEF cs_hours_range_default = '24';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'Blocked Sessions by State of Root Blocker between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF xaxis_title = '';
DEF vaxis_title = 'Blocked Sessions Count';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
DEF is_stacked = "isStacked: false,";
--DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = '<br>2) "INACTIVE" means: Database is waiting for Application Host to release LOCK, while "UNKNOWN" could be a BACKGROUND session on CDB$ROOT.';
DEF chart_foot_note_3 = "<br>";
--DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'ACTIVE ON CPU', id:'1', type:'number'}
PRO ,{label:'ACTIVE WAITING', id:'2', type:'number'}
PRO ,{label:'INACTIVE', id:'3', type:'number'}
PRO ,{label:'UNKNOWN', id:'4', type:'number'}         
PRO ]
--
SET HEA OFF PAGES 0;
--
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 SELECT ', [new Date('||
666666        TO_CHAR(q.time, 'YYYY')|| /* year */
666666        ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
666666        ','||TO_CHAR(q.time, 'DD')|| /* day */
666666        ','||TO_CHAR(q.time, 'HH24')|| /* hour */
666666        ','||TO_CHAR(q.time, 'MI')|| /* minute */
666666        ','||TO_CHAR(q.time, 'SS')|| /* second */
666666        ')'||
666666        ','||num_format(SUM(q.active_on_cpu))|| -- ACTIVE ON CPU
666666        ','||num_format(SUM(q.active_waiting))|| -- ACTIVE WAITING
666666        ','||num_format(SUM(q.inactive))|| -- INACTIVE
666666        ','||num_format(SUM(q.unknown))|| -- UNKNOWN
666666        ']'
666666   FROM blockers_and_blockees q
666666  WHERE q.sessions_blocked > 0
666666  GROUP BY
666666        q.time
666666  ORDER BY
666666        q.time;
SET TERM ON;
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
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
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--