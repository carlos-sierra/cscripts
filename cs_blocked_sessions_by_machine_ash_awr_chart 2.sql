----------------------------------------------------------------------------------------
--
-- File name:   cs_blocked_sessions_by_machine_ash_awr_chart.sql
--
-- Purpose:     Top Session Blockers by Machine of Root Blocker as per ASH from AWR (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/02/10
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_blocked_sessions_by_machine_ash_awr_chart.sql
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
DEF cs_script_name = 'cs_blocked_sessions_by_machine_ash_awr_chart';
DEF cs_hours_range_default = '24';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO 3. Root Blocker State: [{ANY}|ACTIVE|INACTIVE|ACTIVE ON CPU|ACTIVE WAITING|UNKNOWN]
DEF root_blocker_state = '&3.';
UNDEF 3;
COL root_blocker_state NEW_V root_blocker_state NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&root_blocker_state.')) IN ('ANY', 'ACTIVE', 'INACTIVE', 'ACTIVE ON CPU', 'ACTIVE WAITING', 'UNKNOWN') THEN UPPER(TRIM('&&root_blocker_state.')) ELSE 'ANY' END AS root_blocker_state FROM DUAL
/
--
--ALTER SESSION SET container = CDB$ROOT;
--
COL machine_01 NEW_V machine_01 NOPRI;
COL machine_02 NEW_V machine_02 NOPRI;
COL machine_03 NEW_V machine_03 NOPRI;
COL machine_04 NEW_V machine_04 NOPRI;
COL machine_05 NEW_V machine_05 NOPRI;
COL machine_06 NEW_V machine_06 NOPRI;
COL machine_07 NEW_V machine_07 NOPRI;
COL machine_08 NEW_V machine_08 NOPRI;
COL machine_09 NEW_V machine_09 NOPRI;
COL machine_10 NEW_V machine_10 NOPRI;
COL machine_11 NEW_V machine_11 NOPRI;
COL machine_12 NEW_V machine_12 NOPRI;
--
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 , 
666666 by_sessions_sum AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        machine,
666666        ROW_NUMBER() OVER (ORDER BY SUM(CASE '&&root_blocker_state.' 
666666                                           WHEN 'ANY' THEN sessions_blocked 
666666                                           WHEN 'ACTIVE' THEN active_on_cpu + active_waiting 
666666                                           WHEN 'INACTIVE' THEN inactive
666666                                           WHEN 'ACTIVE ON CPU' THEN active_on_cpu
666666                                           WHEN 'ACTIVE WAITING' THEN active_waiting
666666                                           WHEN 'UNKNOWN' THEN unknown
666666                                         END
666666                                    ) DESC NULLS LAST) top_sum
666666   FROM blockers_and_blockees
666666  WHERE sessions_blocked > 0
666666    --AND machine <> 'unknown'
666666  GROUP BY
666666        machine
666666 )
666666 SELECT MAX(CASE top_sum WHEN 01 THEN machine END) machine_01,
666666        MAX(CASE top_sum WHEN 02 THEN machine END) machine_02,
666666        MAX(CASE top_sum WHEN 03 THEN machine END) machine_03,
666666        MAX(CASE top_sum WHEN 04 THEN machine END) machine_04,
666666        MAX(CASE top_sum WHEN 05 THEN machine END) machine_05,
666666        MAX(CASE top_sum WHEN 06 THEN machine END) machine_06,
666666        MAX(CASE top_sum WHEN 07 THEN machine END) machine_07,
666666        MAX(CASE top_sum WHEN 08 THEN machine END) machine_08,
666666        MAX(CASE top_sum WHEN 09 THEN machine END) machine_09,
666666        MAX(CASE top_sum WHEN 10 THEN machine END) machine_10,
666666        MAX(CASE top_sum WHEN 11 THEN machine END) machine_11,
666666        MAX(CASE top_sum WHEN 12 THEN machine END) machine_12
666666   FROM by_sessions_sum
666666  WHERE top_sum BETWEEN 1 AND 12;
SET TERM ON;
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'Sessions Blocked by Machine of Root Blocker between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF xaxis_title = 'Root Blocker State: &&root_blocker_state.';
DEF vaxis_title = 'Blocked Sessions Count';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
DEF is_stacked = "isStacked: false,";
--DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = '<br>2) "INACTIVE" means: Database is waiting for Application Host to release LOCK.';
DEF chart_foot_note_3 = "<br>";
--DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&root_blocker_state."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'&&machine_01.', id:'01', type:'number'}
PRO ,{label:'&&machine_02.', id:'02', type:'number'}
PRO ,{label:'&&machine_03.', id:'03', type:'number'}
PRO ,{label:'&&machine_04.', id:'04', type:'number'}
PRO ,{label:'&&machine_05.', id:'05', type:'number'}
PRO ,{label:'&&machine_06.', id:'06', type:'number'}    
PRO ,{label:'&&machine_07.', id:'07', type:'number'}
PRO ,{label:'&&machine_08.', id:'08', type:'number'}
PRO ,{label:'&&machine_09.', id:'09', type:'number'}
PRO ,{label:'&&machine_10.', id:'10', type:'number'}
PRO ,{label:'&&machine_11.', id:'11', type:'number'}
PRO ,{label:'&&machine_12.', id:'12', type:'number'}    
PRO ]
--
SET HEA OFF PAGES 0;
--
SET TERM OFF;
GET cs_internal/cs_blocked_sessions_ash_awr_internal.sql NOLIST
.
666666 , 
666666 by_sessions_sum AS (
666666 SELECT /*+ MATERIALIZE NO_MERGE */
666666        time,
666666        machine,
666666        SUM(CASE '&&root_blocker_state.' 
666666               WHEN 'ANY' THEN sessions_blocked 
666666               WHEN 'ACTIVE' THEN active_on_cpu + active_waiting 
666666               WHEN 'INACTIVE' THEN inactive
666666               WHEN 'ACTIVE ON CPU' THEN active_on_cpu
666666               WHEN 'ACTIVE WAITING' THEN active_waiting
666666               WHEN 'UNKNOWN' THEN unknown
666666             END
666666        ) AS sessions_blocked
666666   FROM blockers_and_blockees
666666  WHERE sessions_blocked > 0
666666    --AND machine <> 'unknown'
666666  GROUP BY
666666        time,
666666        machine
666666 )
666666 SELECT ', [new Date('||
666666        TO_CHAR(q.time, 'YYYY')|| /* year */
666666        ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
666666        ','||TO_CHAR(q.time, 'DD')|| /* day */
666666        ','||TO_CHAR(q.time, 'HH24')|| /* hour */
666666        ','||TO_CHAR(q.time, 'MI')|| /* minute */
666666        ','||TO_CHAR(q.time, 'SS')|| /* second */
666666        ')'||
666666        ','||num_format(SUM(CASE q.machine WHEN '&&machine_01.' THEN q.sessions_blocked ELSE 0 END))||
666666        ','||num_format(SUM(CASE q.machine WHEN '&&machine_02.' THEN q.sessions_blocked ELSE 0 END))||
666666        ','||num_format(SUM(CASE q.machine WHEN '&&machine_03.' THEN q.sessions_blocked ELSE 0 END))||
666666        ','||num_format(SUM(CASE q.machine WHEN '&&machine_04.' THEN q.sessions_blocked ELSE 0 END))||
666666        ','||num_format(SUM(CASE q.machine WHEN '&&machine_05.' THEN q.sessions_blocked ELSE 0 END))||
666666        ','||num_format(SUM(CASE q.machine WHEN '&&machine_06.' THEN q.sessions_blocked ELSE 0 END))||
666666        ','||num_format(SUM(CASE q.machine WHEN '&&machine_07.' THEN q.sessions_blocked ELSE 0 END))||
666666        ','||num_format(SUM(CASE q.machine WHEN '&&machine_08.' THEN q.sessions_blocked ELSE 0 END))||
666666        ','||num_format(SUM(CASE q.machine WHEN '&&machine_09.' THEN q.sessions_blocked ELSE 0 END))||
666666        ','||num_format(SUM(CASE q.machine WHEN '&&machine_10.' THEN q.sessions_blocked ELSE 0 END))||
666666        ','||num_format(SUM(CASE q.machine WHEN '&&machine_11.' THEN q.sessions_blocked ELSE 0 END))||
666666        ','||num_format(SUM(CASE q.machine WHEN '&&machine_12.' THEN q.sessions_blocked ELSE 0 END))||
666666        ']'
666666   FROM by_sessions_sum q
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