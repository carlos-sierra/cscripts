----------------------------------------------------------------------------------------
--
-- File name:   cs_sessions_by_machine_chart.sql
--
-- Purpose:     Sessions by Machine Chart
--
-- Author:      Carlos Sierra
--
-- Version:     2020/04/29
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sessions_by_machine_chart.sql
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
DEF cs_script_name = 'cs_sessions_by_machine_chart';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
ALTER SESSION SET container = CDB$ROOT;
--
COL machine HEA 'Machine';
--
SELECT COALESCE(machine, '"null"') AS machine, COUNT(*), MIN(snap_time) AS min_snap_time, MAX(snap_time) AS max_snap_time
  FROM c##iod.iod_session_hist
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND '&&cs_con_id' IN ('1', con_id)
   AND type = 'USER'
 GROUP BY
       COALESCE(machine, '"null"')
 ORDER BY
       1
/
PRO
PRO 3. Machine (opt):
DEF cs2_machine = '&3.';
UNDEF 3;
COL cs2_machine NEW_V cs2_machine NOPRI;
SELECT TRIM('"' FROM '&&cs2_machine.') AS cs2_machine FROM DUAL;
--
DEF spool_id_chart_footer_script = 'cs_sessions_by_machine_footer.sql';
COL rn FOR 999;
DEF series_01 = ' ';
DEF series_02 = ' ';
DEF series_03 = ' ';
DEF series_04 = ' ';
DEF series_05 = ' ';
DEF series_06 = ' ';
DEF series_07 = ' ';
DEF series_08 = ' ';
DEF series_09 = ' ';
DEF series_10 = ' ';
DEF series_11 = ' ';
DEF series_12 = ' ';
DEF series_13 = ' ';
COL series_01 NEW_V series_01 FOR A64 TRUNC NOPRI;
COL series_02 NEW_V series_02 FOR A64 TRUNC NOPRI;
COL series_03 NEW_V series_03 FOR A64 TRUNC NOPRI;
COL series_04 NEW_V series_04 FOR A64 TRUNC NOPRI;
COL series_05 NEW_V series_05 FOR A64 TRUNC NOPRI;
COL series_06 NEW_V series_06 FOR A64 TRUNC NOPRI;
COL series_07 NEW_V series_07 FOR A64 TRUNC NOPRI;
COL series_08 NEW_V series_08 FOR A64 TRUNC NOPRI;
COL series_09 NEW_V series_09 FOR A64 TRUNC NOPRI;
COL series_10 NEW_V series_10 FOR A64 TRUNC NOPRI;
COL series_11 NEW_V series_11 FOR A64 TRUNC NOPRI;
COL series_12 NEW_V series_12 FOR A64 TRUNC NOPRI;
COL series_13 NEW_V series_13 FOR A64 TRUNC NOPRI;
--
WITH
by_machine AS (
SELECT COALESCE(machine, '"null"') AS machine,
       ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS rn
  FROM c##iod.iod_session_hist
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs2_machine.' IS NULL OR COALESCE(machine, '"null"') LIKE CHR(37)||'&&cs2_machine.'||CHR(37))
   AND '&&cs_con_id' IN ('1', con_id)
   AND type = 'USER'
 GROUP BY
       COALESCE(machine, '"null"')
),
top AS (
SELECT machine, rn
  FROM by_machine
 WHERE rn < 13
),
max_top AS (
SELECT /*+ MATERIALIZE NO_MERGE */ MAX(rn) AS max_rn FROM top
),
bottom AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       (1 + max_top.max_rn) AS bottom_rn, -- up to 13
       '"all others"' AS dimension_group
  FROM by_machine a, max_top
 WHERE a.rn >= max_top.max_rn
 GROUP BY
       max_top.max_rn
),
top_and_bottom AS (
SELECT rn, machine AS dimension_group
  FROM top
 UNION ALL
SELECT bottom_rn AS rn, dimension_group
  FROM bottom
),
list AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       rn, dimension_group
  FROM top_and_bottom
)
SELECT rn, dimension_group,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  1), ' ') AS series_01,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  2), ' ') AS series_02,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  3), ' ') AS series_03,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  4), ' ') AS series_04,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  5), ' ') AS series_05,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  6), ' ') AS series_06,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  7), ' ') AS series_07,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  8), ' ') AS series_08,
       COALESCE((SELECT dimension_group FROM list WHERE rn =  9), ' ') AS series_09,
       COALESCE((SELECT dimension_group FROM list WHERE rn = 10), ' ') AS series_10,
       COALESCE((SELECT dimension_group FROM list WHERE rn = 11), ' ') AS series_11,
       COALESCE((SELECT dimension_group FROM list WHERE rn = 12), ' ') AS series_12,
       COALESCE((SELECT dimension_group FROM list WHERE rn = 13), ' ') AS series_13
  FROM list
 ORDER BY
       rn
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'Sessions by Machine between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF vaxis_title = 'Sessions';
DEF xaxis_title = '';
--
COL xaxis_title NEW_V xaxis_title NOPRI;
SELECT CASE WHEN '&&cs2_machine.' IS NOT NULL THEN 'Machine:"%&&cs2_machine.%" ' END AS xaxis_title
FROM DUAL;
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
PRO ,'&&series_01.'        
PRO ,'&&series_02.'        
PRO ,'&&series_03.'        
PRO ,'&&series_04.'        
PRO ,'&&series_05.'        
PRO ,'&&series_06.'        
PRO ,'&&series_07.'        
PRO ,'&&series_08.'        
PRO ,'&&series_09.'        
PRO ,'&&series_10.'        
PRO ,'&&series_11.'        
PRO ,'&&series_12.'        
PRO ,'&&series_13.'        
PRO ]
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
all_sessions AS (
SELECT snap_time AS time,
       CASE COALESCE(machine, '"null"')
         WHEN '&&series_01.' THEN '&&series_01.'
         WHEN '&&series_02.' THEN '&&series_02.'
         WHEN '&&series_03.' THEN '&&series_03.'
         WHEN '&&series_04.' THEN '&&series_04.'
         WHEN '&&series_05.' THEN '&&series_05.'
         WHEN '&&series_06.' THEN '&&series_06.'
         WHEN '&&series_07.' THEN '&&series_07.'
         WHEN '&&series_08.' THEN '&&series_08.'
         WHEN '&&series_09.' THEN '&&series_09.'
         WHEN '&&series_10.' THEN '&&series_10.'
         WHEN '&&series_11.' THEN '&&series_11.'
         WHEN '&&series_12.' THEN '&&series_12.'
         WHEN '&&series_13.' THEN '&&series_13.'
         ELSE '"all others"' 
       END AS dimension_group
  FROM c##iod.iod_session_hist
 WHERE snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ('&&cs2_machine.' IS NULL OR COALESCE(machine, '"null"') LIKE CHR(37)||'&&cs2_machine.'||CHR(37))
   AND '&&cs_con_id' IN ('1', con_id)
   AND type = 'USER'
),
my_query AS (
SELECT time,
       SUM(CASE WHEN dimension_group = '&&series_01.' THEN 1 ELSE 0 END) AS sessions_01,
       SUM(CASE WHEN dimension_group = '&&series_02.' THEN 1 ELSE 0 END) AS sessions_02,
       SUM(CASE WHEN dimension_group = '&&series_03.' THEN 1 ELSE 0 END) AS sessions_03,
       SUM(CASE WHEN dimension_group = '&&series_04.' THEN 1 ELSE 0 END) AS sessions_04,
       SUM(CASE WHEN dimension_group = '&&series_05.' THEN 1 ELSE 0 END) AS sessions_05,
       SUM(CASE WHEN dimension_group = '&&series_06.' THEN 1 ELSE 0 END) AS sessions_06,
       SUM(CASE WHEN dimension_group = '&&series_07.' THEN 1 ELSE 0 END) AS sessions_07,
       SUM(CASE WHEN dimension_group = '&&series_08.' THEN 1 ELSE 0 END) AS sessions_08,
       SUM(CASE WHEN dimension_group = '&&series_09.' THEN 1 ELSE 0 END) AS sessions_09,
       SUM(CASE WHEN dimension_group = '&&series_10.' THEN 1 ELSE 0 END) AS sessions_10,
       SUM(CASE WHEN dimension_group = '&&series_11.' THEN 1 ELSE 0 END) AS sessions_11,
       SUM(CASE WHEN dimension_group = '&&series_12.' THEN 1 ELSE 0 END) AS sessions_12,
       SUM(CASE WHEN dimension_group = '&&series_13.' THEN 1 ELSE 0 END) AS sessions_13
  FROM all_sessions
 GROUP BY
       time
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||q.sessions_01|| 
       ','||q.sessions_02|| 
       ','||q.sessions_03|| 
       ','||q.sessions_04|| 
       ','||q.sessions_05|| 
       ','||q.sessions_06|| 
       ','||q.sessions_07|| 
       ','||q.sessions_08|| 
       ','||q.sessions_09|| 
       ','||q.sessions_10|| 
       ','||q.sessions_11|| 
       ','||q.sessions_12|| 
       ','||q.sessions_13|| 
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
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--