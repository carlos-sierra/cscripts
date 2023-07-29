----------------------------------------------------------------------------------------
--
-- File name:   cs_top_pdb_size_chart.sql
--
-- Purpose:     Top PDB Disk Size Utilization (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/01/19
--
-- Usage:       Execute connected to CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_pdb_size_chart.sql
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
DEF cs_script_name = 'cs_top_pdb_size_chart';
DEF cs_hours_range_default = '4320';
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(snap_time)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM &&cs_tools_schema..dbc_tablespaces
/
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "Top PDBs in terms of Allocated Disk Space between &&cs_sample_time_from. and &&cs_sample_time_to. UTC";
DEF chart_title = "&&report_title.";
DEF xaxis_title = "";
--DEF vaxis_title = "Gibibytes (GiB)";
DEF vaxis_title = "Gigabytes (GBs)";
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
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."';
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
DEF others = "OTHERS";
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
COL others NEW_V others NOPRI;
--
WITH
pdb AS (
SELECT pdb_name,
       ROW_NUMBER() OVER (ORDER BY SUM(allocated_bytes) DESC) AS rn
  FROM &&cs_tools_schema..dbc_tablespaces
 WHERE snap_time = (SELECT MAX(snap_time) FROM &&cs_tools_schema..dbc_tablespaces WHERE snap_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND snap_time < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.'))
   AND pdb_name <> 'CDB$ROOT'
 GROUP BY 
       pdb_name
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
       CASE WHEN COUNT(*) > 10 THEN (COUNT(*) - 10)||' OTHERS' END AS others
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
PRO ,{label:'&&others.', id:'11', type:'number'}
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
SELECT snap_time,
       ROUND(SUM(CASE pdb_name WHEN '&&top_01.' THEN allocated_bytes ELSE 0 END) / POWER(10,9)) AS top_01,
       ROUND(SUM(CASE pdb_name WHEN '&&top_02.' THEN allocated_bytes ELSE 0 END) / POWER(10,9)) AS top_02,
       ROUND(SUM(CASE pdb_name WHEN '&&top_03.' THEN allocated_bytes ELSE 0 END) / POWER(10,9)) AS top_03,
       ROUND(SUM(CASE pdb_name WHEN '&&top_04.' THEN allocated_bytes ELSE 0 END) / POWER(10,9)) AS top_04,
       ROUND(SUM(CASE pdb_name WHEN '&&top_05.' THEN allocated_bytes ELSE 0 END) / POWER(10,9)) AS top_05,
       ROUND(SUM(CASE pdb_name WHEN '&&top_06.' THEN allocated_bytes ELSE 0 END) / POWER(10,9)) AS top_06,
       ROUND(SUM(CASE pdb_name WHEN '&&top_07.' THEN allocated_bytes ELSE 0 END) / POWER(10,9)) AS top_07,
       ROUND(SUM(CASE pdb_name WHEN '&&top_08.' THEN allocated_bytes ELSE 0 END) / POWER(10,9)) AS top_08,
       ROUND(SUM(CASE pdb_name WHEN '&&top_09.' THEN allocated_bytes ELSE 0 END) / POWER(10,9)) AS top_09,
       ROUND(SUM(CASE pdb_name WHEN '&&top_10.' THEN allocated_bytes ELSE 0 END) / POWER(10,9)) AS top_10,
       ROUND(SUM(CASE WHEN pdb_name IN ('&&top_01.', '&&top_02.', '&&top_03.', '&&top_04.', '&&top_05.', '&&top_06.', '&&top_07.', '&&top_08.', '&&top_09.', '&&top_10.') THEN 0 ELSE allocated_bytes END) / POWER(10,9)) AS others
  FROM &&cs_tools_schema..dbc_tablespaces
 WHERE snap_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND snap_time < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
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
       ','||num_format(q.others, 3)|| 
       ']'
  FROM my_query q
 ORDER BY
       q.snap_time
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
