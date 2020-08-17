----------------------------------------------------------------------------------------
--
-- File name:   cs_top_pdb_size_chart.sql
--
-- Purpose:     Top PDB Disk Size Utilization Chart
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/14
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
ALTER SESSION SET container = CDB$ROOT;
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(snap_time)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM c##iod.tablespaces_hist
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
DEF vaxis_title = "Gigabytes (GB)";
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
DEF report_foot_note = SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to."';
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
       --ROUND(SUM(oem_allocated_space_mbs) / POWER(2,10)) AS GiB_allocated,
       --ROUND(SUM(oem_allocated_space_mbs) * POWER(2,20) / POWER(10,9)) AS GB_allocated,
       ROW_NUMBER() OVER (ORDER BY SUM(oem_allocated_space_mbs) DESC) AS rn
  FROM c##iod.tablespaces_hist
 WHERE snap_time = (SELECT MAX(snap_time) FROM c##iod.tablespaces_hist WHERE snap_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND snap_time < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.'))
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
PRO ,'&&top_01.'
PRO ,'&&top_02.'
PRO ,'&&top_03.'
PRO ,'&&top_04.'
PRO ,'&&top_05.'
PRO ,'&&top_06.'
PRO ,'&&top_07.'
PRO ,'&&top_08.'
PRO ,'&&top_09.'
PRO ,'&&top_10.'
PRO ,'&&others.'
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
my_query AS (
SELECT snap_time,
--       ROUND(SUM(CASE pdb_name WHEN '&&top_01.' THEN oem_allocated_space_mbs ELSE 0 END) / POWER(2,10)) AS top_01,
--       ROUND(SUM(CASE pdb_name WHEN '&&top_02.' THEN oem_allocated_space_mbs ELSE 0 END) / POWER(2,10)) AS top_02,
--       ROUND(SUM(CASE pdb_name WHEN '&&top_03.' THEN oem_allocated_space_mbs ELSE 0 END) / POWER(2,10)) AS top_03,
--       ROUND(SUM(CASE pdb_name WHEN '&&top_04.' THEN oem_allocated_space_mbs ELSE 0 END) / POWER(2,10)) AS top_04,
--       ROUND(SUM(CASE pdb_name WHEN '&&top_05.' THEN oem_allocated_space_mbs ELSE 0 END) / POWER(2,10)) AS top_05,
--       ROUND(SUM(CASE pdb_name WHEN '&&top_06.' THEN oem_allocated_space_mbs ELSE 0 END) / POWER(2,10)) AS top_06,
--       ROUND(SUM(CASE pdb_name WHEN '&&top_07.' THEN oem_allocated_space_mbs ELSE 0 END) / POWER(2,10)) AS top_07,
--       ROUND(SUM(CASE pdb_name WHEN '&&top_08.' THEN oem_allocated_space_mbs ELSE 0 END) / POWER(2,10)) AS top_08,
--       ROUND(SUM(CASE pdb_name WHEN '&&top_09.' THEN oem_allocated_space_mbs ELSE 0 END) / POWER(2,10)) AS top_09,
--       ROUND(SUM(CASE pdb_name WHEN '&&top_10.' THEN oem_allocated_space_mbs ELSE 0 END) / POWER(2,10)) AS top_10,
--       ROUND(SUM(CASE WHEN pdb_name IN ('&&top_01.', '&&top_02.', '&&top_03.', '&&top_04.', '&&top_05.', '&&top_06.', '&&top_07.', '&&top_08.', '&&top_09.', '&&top_10.') THEN 0 ELSE oem_allocated_space_mbs END) / POWER(2,10)) AS others
       ROUND(SUM(CASE pdb_name WHEN '&&top_01.' THEN oem_allocated_space_mbs ELSE 0 END) * POWER(2,20) / POWER(10,9)) AS top_01,
       ROUND(SUM(CASE pdb_name WHEN '&&top_02.' THEN oem_allocated_space_mbs ELSE 0 END) * POWER(2,20) / POWER(10,9)) AS top_02,
       ROUND(SUM(CASE pdb_name WHEN '&&top_03.' THEN oem_allocated_space_mbs ELSE 0 END) * POWER(2,20) / POWER(10,9)) AS top_03,
       ROUND(SUM(CASE pdb_name WHEN '&&top_04.' THEN oem_allocated_space_mbs ELSE 0 END) * POWER(2,20) / POWER(10,9)) AS top_04,
       ROUND(SUM(CASE pdb_name WHEN '&&top_05.' THEN oem_allocated_space_mbs ELSE 0 END) * POWER(2,20) / POWER(10,9)) AS top_05,
       ROUND(SUM(CASE pdb_name WHEN '&&top_06.' THEN oem_allocated_space_mbs ELSE 0 END) * POWER(2,20) / POWER(10,9)) AS top_06,
       ROUND(SUM(CASE pdb_name WHEN '&&top_07.' THEN oem_allocated_space_mbs ELSE 0 END) * POWER(2,20) / POWER(10,9)) AS top_07,
       ROUND(SUM(CASE pdb_name WHEN '&&top_08.' THEN oem_allocated_space_mbs ELSE 0 END) * POWER(2,20) / POWER(10,9)) AS top_08,
       ROUND(SUM(CASE pdb_name WHEN '&&top_09.' THEN oem_allocated_space_mbs ELSE 0 END) * POWER(2,20) / POWER(10,9)) AS top_09,
       ROUND(SUM(CASE pdb_name WHEN '&&top_10.' THEN oem_allocated_space_mbs ELSE 0 END) * POWER(2,20) / POWER(10,9)) AS top_10,
       ROUND(SUM(CASE WHEN pdb_name IN ('&&top_01.', '&&top_02.', '&&top_03.', '&&top_04.', '&&top_05.', '&&top_06.', '&&top_07.', '&&top_08.', '&&top_09.', '&&top_10.') THEN 0 ELSE oem_allocated_space_mbs END) * POWER(2,20) / POWER(10,9)) AS others
  FROM c##iod.tablespaces_hist
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
       ','||q.top_01|| 
       ','||q.top_02|| 
       ','||q.top_03|| 
       ','||q.top_04|| 
       ','||q.top_05|| 
       ','||q.top_06|| 
       ','||q.top_07|| 
       ','||q.top_08|| 
       ','||q.top_09|| 
       ','||q.top_10|| 
       ','||q.others|| 
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
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
