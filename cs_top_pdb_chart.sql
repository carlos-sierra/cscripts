----------------------------------------------------------------------------------------
--
-- File name:   cs_top_pdb_chart.sql
--
-- Purpose:     Top PDBs as per use of CPU Cores, Disk Space or Sessions (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/01/21
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_pdb_chart.sql
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
DEF cs_script_name = 'cs_top_pdb_chart';
DEF cs_hours_range_default = '4320';
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(timestamp)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM &&cs_tools_schema..dbc_pdbs
/
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
PRO 3. Metric: [{CPU Cores}|Disk Space|Sessions]
DEF cs_metric = '&3.';
UNDEF 3;
COL cs_metric NEW_V cs_metric NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&cs_metric.')) IN ('CPU CORES', 'DISK SPACE', 'SESSIONS') THEN TRIM('&&cs_metric.') ELSE 'CPU Cores' END AS cs_metric FROM DUAL;
COL cs_vaxis_title NEW_V cs_vaxis_title NOPRI;
SELECT CASE UPPER('&&cs_metric.') WHEN 'CPU CORES' THEN 'Average Running Sessions' WHEN 'DISK SPACE' THEN 'Gigabytes (GBs)' WHEN 'SESSIONS' THEN 'Sessions' END AS cs_vaxis_title FROM DUAL;
COL cs_expression NEW_V cs_expression NOPRI;
SELECT CASE UPPER('&&cs_metric.') WHEN 'CPU CORES' THEN 'p.avg_running_sessions' WHEN 'DISK SPACE' THEN 'p.total_size_bytes / POWER(10, 9)' WHEN 'SESSIONS' THEN 'p.sessions' END AS cs_expression FROM DUAL;
COL report_title_prefix NEW_V report_title_prefix NOPRI;
SELECT CASE '&&cs_con_name.' WHEN 'CDB$ROOT' THEN 'Top PDBs as per use of' ELSE '&&cs_con_name. use of' END AS report_title_prefix FROM DUAL;
COL cs_legend_position NEW_V cs_legend_position NOPRI;
SELECT CASE '&&cs_con_name.' WHEN 'CDB$ROOT' THEN '&&cs_legend_position.' ELSE 'none' END AS cs_legend_position FROM DUAL;
COL cs_chartarea_width NEW_V cs_chartarea_width NOPRI;
SELECT CASE '&&cs_con_name.' WHEN 'CDB$ROOT' THEN '&&cs_chartarea_width.' ELSE '87%' END AS cs_chartarea_width FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "&&report_title_prefix. &&cs_metric. between &&cs_sample_time_from. and &&cs_sample_time_to. UTC";
DEF chart_title = "&&report_title.";
DEF xaxis_title = "";
DEF vaxis_title = "&&cs_vaxis_title.";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&baseline., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF vaxis_viewwindow = ", viewWindow: {min:0}";
DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_metric."';
--
DEF top_01 = "";
DEF top_02 = "";
DEF top_03 = "";
DEF top_04 = "";
DEF top_05 = "";
DEF top_06 = "";
DEF top_08 = "";
DEF top_09 = "";
DEF top_10 = "";
DEF top_11 = "";
DEF top_12 = "";
DEF top_13 = "";
DEF top_14 = "";
DEF others = "OTHER PDBS";
--
COL top_01 NEW_V top_01 NOPRI;
COL top_02 NEW_V top_02 NOPRI;
COL top_03 NEW_V top_03 NOPRI;
COL top_04 NEW_V top_04 NOPRI;
COL top_05 NEW_V top_05 NOPRI;
COL top_06 NEW_V top_06 NOPRI;
COL top_07 NEW_V top_07 NOPRI;
COL top_08 NEW_V top_08 NOPRI;
COL top_09 NEW_V top_09 NOPRI;
COL top_10 NEW_V top_10 NOPRI;
COL top_11 NEW_V top_11 NOPRI;
COL top_12 NEW_V top_12 NOPRI;
COL top_13 NEW_V top_13 NOPRI;
COL top_14 NEW_V top_14 NOPRI;
COL others NEW_V others NOPRI;
--
WITH
pdb AS (
SELECT p.pdb_name,
       ROW_NUMBER() OVER (ORDER BY SUM(&&cs_expression.) DESC) AS rn
  FROM &&cs_tools_schema..dbc_pdbs p
 --WHERE p.timestamp = (SELECT MAX(timestamp) FROM &&cs_tools_schema..dbc_pdbs WHERE timestamp >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND timestamp < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.'))
 WHERE p.timestamp >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND p.timestamp < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND '&&cs_con_name.' IN (p.pdb_name, 'CDB$ROOT')
   AND &&cs_expression. > 0
 GROUP BY 
       p.pdb_name
)
SELECT MAX(CASE rn WHEN  1 THEN pdb_name END) AS top_01,
       MAX(CASE rn WHEN  2 THEN pdb_name END) AS top_02,
       MAX(CASE rn WHEN  3 THEN pdb_name END) AS top_03,
       MAX(CASE rn WHEN  4 THEN pdb_name END) AS top_04,
       MAX(CASE rn WHEN  5 THEN pdb_name END) AS top_05,
       MAX(CASE rn WHEN  6 THEN pdb_name END) AS top_06,
       MAX(CASE rn WHEN  7 THEN pdb_name END) AS top_07,
       MAX(CASE rn WHEN  8 THEN pdb_name END) AS top_08,
       MAX(CASE rn WHEN  9 THEN pdb_name END) AS top_09,
       MAX(CASE rn WHEN 10 THEN pdb_name END) AS top_10,
       MAX(CASE rn WHEN 11 THEN pdb_name END) AS top_11,
       MAX(CASE rn WHEN 12 THEN pdb_name END) AS top_12,
       MAX(CASE rn WHEN 13 THEN pdb_name END) AS top_13,
       MAX(CASE rn WHEN 14 THEN pdb_name END) AS top_14,
       CASE WHEN COUNT(*) > 15 THEN (COUNT(*) - 15)||' OTHER PDBS' END AS others
  FROM pdb
/
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'&&top_01.', id:'01', type:'number'}
PRO ,{label:'&&top_02.', id:'02', type:'number'}
PRO ,{label:'&&top_03.', id:'03', type:'number'}
PRO ,{label:'&&top_04.', id:'04', type:'number'}
PRO ,{label:'&&top_05.', id:'05', type:'number'}
PRO ,{label:'&&top_06.', id:'06', type:'number'}
PRO ,{label:'&&top_07.', id:'07', type:'number'}
PRO ,{label:'&&top_08.', id:'08', type:'number'}
PRO ,{label:'&&top_09.', id:'09', type:'number'}
PRO ,{label:'&&top_10.', id:'10', type:'number'}
PRO ,{label:'&&top_11.', id:'11', type:'number'}
PRO ,{label:'&&top_12.', id:'12', type:'number'}
PRO ,{label:'&&top_13.', id:'13', type:'number'}
PRO ,{label:'&&top_14.', id:'14', type:'number'}
PRO ,{label:'&&others.', id:'99', type:'number'}
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
my_query AS (
SELECT p.timestamp,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_01.' THEN &&cs_expression. ELSE 0 END), 3) AS top_01,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_02.' THEN &&cs_expression. ELSE 0 END), 3) AS top_02,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_03.' THEN &&cs_expression. ELSE 0 END), 3) AS top_03,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_04.' THEN &&cs_expression. ELSE 0 END), 3) AS top_04,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_05.' THEN &&cs_expression. ELSE 0 END), 3) AS top_05,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_06.' THEN &&cs_expression. ELSE 0 END), 3) AS top_06,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_07.' THEN &&cs_expression. ELSE 0 END), 3) AS top_07,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_08.' THEN &&cs_expression. ELSE 0 END), 3) AS top_08,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_09.' THEN &&cs_expression. ELSE 0 END), 3) AS top_09,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_10.' THEN &&cs_expression. ELSE 0 END), 3) AS top_10,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_11.' THEN &&cs_expression. ELSE 0 END), 3) AS top_11,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_12.' THEN &&cs_expression. ELSE 0 END), 3) AS top_12,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_13.' THEN &&cs_expression. ELSE 0 END), 3) AS top_13,
       ROUND(SUM(CASE p.pdb_name WHEN '&&top_14.' THEN &&cs_expression. ELSE 0 END), 3) AS top_14,
       ROUND(SUM(CASE WHEN p.pdb_name IN ('&&top_01.', '&&top_02.', '&&top_03.', '&&top_04.', '&&top_05.', '&&top_06.', '&&top_07.', '&&top_08.', '&&top_09.', '&&top_10.', '&&top_11.', '&&top_12.', '&&top_13.', '&&top_14.') THEN 0 ELSE &&cs_expression. END), 3) AS others
  FROM &&cs_tools_schema..dbc_pdbs p
 WHERE p.timestamp >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND p.timestamp < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND '&&cs_con_name.' IN (p.pdb_name, 'CDB$ROOT')
   AND &&cs_expression. > 0
 GROUP BY
       p.timestamp
)
SELECT ', [new Date('||
       TO_CHAR(q.timestamp, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.timestamp, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.timestamp, 'DD')|| /* day */
       ','||TO_CHAR(q.timestamp, 'HH24')|| /* hour */
       ','||TO_CHAR(q.timestamp, 'MI')|| /* minute */
       ','||TO_CHAR(q.timestamp, 'SS')|| /* second */
       ')'||
       ','||num_format(q.top_01, 3)|| 
       ','||num_format(q.top_02, 3)|| 
       ','||num_format(q.top_03, 3)|| 
       ','||num_format(q.top_04, 3)|| 
       ','||num_format(q.top_05, 3)|| 
       ','||num_format(q.top_06, 3)|| 
       ','||num_format(q.top_07, 3)|| 
       ','||num_format(q.top_08, 3)|| 
       ','||num_format(q.top_09, 3)|| 
       ','||num_format(q.top_10, 3)||
       ','||num_format(q.top_11, 3)|| 
       ','||num_format(q.top_12, 3)|| 
       ','||num_format(q.top_13, 3)|| 
       ','||num_format(q.top_14, 3)|| 
       ','||num_format(q.others, 3)|| 
       ']'
  FROM my_query q
 ORDER BY
       q.timestamp
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
