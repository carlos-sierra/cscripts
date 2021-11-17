----------------------------------------------------------------------------------------
--
-- File name:   cs_sysstat_hist_chart.sql
--
-- Purpose:     Subset of System Statistics from AWR (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/02/11
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sysstat_hist_chart.sql
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
DEF cs_script_name = 'cs_sysstat_hist_chart';
DEF cs_hours_range_default = '336';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
ALTER SESSION SET container = CDB$ROOT;
--
PRO
PRO 3. Class: [{All}|User|Redo|Enqueue|Cache|OS|RAC|SQL|Debug]
DEF class_type = '&3'.
UNDEF 3;
COL name FOR A64 HEA 'Stat Name';
COL current_value HEA 'Current Value';
COL class FOR A30 HEA 'Class(es)' TRUNC;
SELECT name, value AS current_value,
       TRIM(',' FROM
       CASE WHEN BITAND(class, 1) = 1 THEN ',User' END||
       CASE WHEN BITAND(class, 2) = 2 THEN ',Redo' END||
       CASE WHEN BITAND(class, 4) = 4 THEN ',Enqueue' END||
       CASE WHEN BITAND(class, 8) = 8 THEN ',Cache' END||
       CASE WHEN BITAND(class, 16) = 16 THEN ',OS' END||
       CASE WHEN BITAND(class, 32) = 32 THEN ',RAC' END||
       CASE WHEN BITAND(class, 64) = 64 THEN ',SQL' END||
       CASE WHEN BITAND(class, 128) = 128 THEN ',Debug' END
       ) AS class
  FROM v$sysstat 
 WHERE value > 0
   AND (      UPPER(NVL('&&class_type', 'All')) = 'ALL'
         OR   (UPPER('&&class_type.') = 'USER' AND BITAND(class, 1) = 1)
         OR   (UPPER('&&class_type.') = 'REDO' AND BITAND(class, 2) = 2)
         OR   (UPPER('&&class_type.') = 'ENQUEUE' AND BITAND(class, 4) = 4)
         OR   (UPPER('&&class_type.') = 'CACHE' AND BITAND(class, 8) = 8)
         OR   (UPPER('&&class_type.') = 'OS' AND BITAND(class, 16) = 16)
         OR   (UPPER('&&class_type.') = 'RAC' AND BITAND(class, 32) = 32)
         OR   (UPPER('&&class_type.') = 'SQL' AND BITAND(class, 64) = 64)
         OR   (UPPER('&&class_type.') = 'DEBUG' AND BITAND(class, 128) = 128)
   )
ORDER BY
       statistic#
/
PRO
PRO 4. Enter 1st Stat Name: 
DEF stat_name_1 = '&4.';
UNDEF 4;
PRO
PRO 5. Enter 2nd Stat Name: (opt)
DEF stat_name_2 = '&5.';
UNDEF 5;
PRO
PRO 6. Enter 3rd Stat Name: (opt)
DEF stat_name_3 = '&6.';
UNDEF 6;
PRO
PRO 7. Enter 4th Stat Name: (opt)
DEF stat_name_4 = '&7.';
UNDEF 7;
PRO
PRO 8. Enter 5th Stat Name: (opt)
DEF stat_name_5 = '&8.';
UNDEF 8;
PRO
PRO 9. Enter 6th Stat Name: (opt)
DEF stat_name_6 = '&9.';
UNDEF 9;
PRO
PRO 10. Graph Type: [{SteppedArea}|Line|Area|Scatter] note: SteppedArea and Area are stacked 
DEF graph_type = '&10.';
UNDEF 10;
COL cs_graph_type NEW_V cs_graph_type NOPRI;
SELECT CASE WHEN '&&graph_type.' IN ('SteppedArea', 'Line', 'Area', 'Scatter') THEN '&&graph_type.' ELSE 'SteppedArea' END AS cs_graph_type FROM DUAL
/
PRO
PRO 11. Trendlines Type: &&cs_trendlines_types.
DEF cs_trendlines_type = '&11.';
UNDEF 11;
COL cs_trendlines_type NEW_V cs_trendlines_type NOPRI;
COL cs_trendlines NEW_V cs_trendlines NOPRI;
COL cs_hAxis_maxValue NEW_V cs_hAxis_maxValue NOPRI;
SELECT CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential', 'none') THEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) ELSE 'none' END AS cs_trendlines_type,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) = 'none' THEN '//' END AS cs_trendlines,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential') THEN '&&cs_hAxis_maxValue.' END AS cs_hAxis_maxValue
  FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "System Statistics";
DEF chart_title = "System Statistics";
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to.";
DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
DEF cs_trendlines_series = ", 0:{}, 1:{}, 2:{}, 3:{}, 4:{}, 5:{}";
DEF vaxis_title = "";
COL vaxis_title NEW_V vaxis_title NOPRI;
SELECT CASE WHEN '&&stat_name_1.' LIKE '%current' THEN 'Count' ELSE 'Per Second' END AS vaxis_title FROM DUAL
/
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&class_type." "&&stat_name_1." "&&stat_name_2." "&&stat_name_3." "&&stat_name_4." "&&stat_name_5." "&&stat_name_6." "&&cs_graph_type." "&&cs_trendlines_type."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'&&stat_name_1.', id:'1', type:'number'}
PRO ,{label:'&&stat_name_2.', id:'2', type:'number'}
PRO ,{label:'&&stat_name_3.', id:'3', type:'number'}
PRO ,{label:'&&stat_name_4.', id:'4', type:'number'}
PRO ,{label:'&&stat_name_5.', id:'5', type:'number'}
PRO ,{label:'&&stat_name_6.', id:'6', type:'number'}      
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
sysstat (
       snap_id, end_interval_time, elapsed_sec, stat_value_1, stat_value_2, stat_value_3, stat_value_4, stat_value_5, stat_value_6
) AS (
       SELECT h.snap_id,
              s.end_interval_time,
              (CAST(s.end_interval_time AS DATE) - CAST(s.begin_interval_time AS DATE)) * 86400 AS elapsed_sec,
              SUM(CASE WHEN h.stat_name = '&&stat_name_1.' THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name = '&&stat_name_1.' AND h.stat_name NOT LIKE '%current' THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS stat_value_1,
              SUM(CASE WHEN h.stat_name = '&&stat_name_2.' THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name = '&&stat_name_2.' AND h.stat_name NOT LIKE '%current' THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS stat_value_2,
              SUM(CASE WHEN h.stat_name = '&&stat_name_3.' THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name = '&&stat_name_3.' AND h.stat_name NOT LIKE '%current' THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS stat_value_3,
              SUM(CASE WHEN h.stat_name = '&&stat_name_4.' THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name = '&&stat_name_4.' AND h.stat_name NOT LIKE '%current' THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS stat_value_4,
              SUM(CASE WHEN h.stat_name = '&&stat_name_5.' THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name = '&&stat_name_5.' AND h.stat_name NOT LIKE '%current' THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS stat_value_5,
              SUM(CASE WHEN h.stat_name = '&&stat_name_6.' THEN h.value ELSE 0 END) - LAG(SUM(CASE WHEN h.stat_name = '&&stat_name_6.' AND h.stat_name NOT LIKE '%current' THEN h.value ELSE 0 END)) OVER (ORDER BY h.snap_id) AS stat_value_6
       FROM   dba_hist_sysstat h,
              dba_hist_snapshot s
       WHERE  h.dbid = TO_NUMBER('&&cs_dbid.')
       AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
       AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
       AND h.stat_name IN ('&&stat_name_1.', '&&stat_name_2.', '&&stat_name_3.', '&&stat_name_4.', '&&stat_name_5.', '&&stat_name_6.')
       AND s.snap_id = h.snap_id
       AND s.dbid = h.dbid
       AND s.instance_number = h.instance_number
       AND s.end_interval_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
       GROUP BY
              h.snap_id,
              s.begin_interval_time,
              s.end_interval_time
),
sysstat_per_sec (
       snap_id, end_interval_time, stat_value_1_ps, stat_value_2_ps, stat_value_3_ps, stat_value_4_ps, stat_value_5_ps, stat_value_6_ps
) AS (
       SELECT snap_id,
              end_interval_time,
              CASE WHEN '&&stat_name_1.' LIKE '%current' THEN stat_value_1 ELSE ROUND(stat_value_1 / elapsed_sec, 3) END stat_value_1_ps,
              CASE WHEN '&&stat_name_2.' LIKE '%current' THEN stat_value_2 ELSE ROUND(stat_value_2 / elapsed_sec, 3) END stat_value_2_ps,
              CASE WHEN '&&stat_name_3.' LIKE '%current' THEN stat_value_3 ELSE ROUND(stat_value_3 / elapsed_sec, 3) END stat_value_3_ps,
              CASE WHEN '&&stat_name_4.' LIKE '%current' THEN stat_value_4 ELSE ROUND(stat_value_4 / elapsed_sec, 3) END stat_value_4_ps,
              CASE WHEN '&&stat_name_5.' LIKE '%current' THEN stat_value_5 ELSE ROUND(stat_value_5 / elapsed_sec, 3) END stat_value_5_ps,
              CASE WHEN '&&stat_name_6.' LIKE '%current' THEN stat_value_6 ELSE ROUND(stat_value_6 / elapsed_sec, 3) END stat_value_6_ps
       FROM   sysstat
       WHERE  elapsed_sec > 60 -- ignore snaps too close
)
SELECT ', [new Date('||
       TO_CHAR(q.end_interval_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.end_interval_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.end_interval_time, 'DD')|| /* day */
       ','||TO_CHAR(q.end_interval_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.end_interval_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.end_interval_time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.stat_value_1_ps, 3)|| 
       ','||num_format(q.stat_value_2_ps, 3)|| 
       ','||num_format(q.stat_value_3_ps, 3)|| 
       ','||num_format(q.stat_value_4_ps, 3)|| 
       ','||num_format(q.stat_value_5_ps, 3)|| 
       ','||num_format(q.stat_value_6_ps, 3)|| 
       ']'
  FROM sysstat_per_sec q
 WHERE q.stat_value_1_ps >= 0
 ORDER BY
       q.end_interval_time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = '&&cs_graph_type.';
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