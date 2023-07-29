----------------------------------------------------------------------------------------
--
-- File name:   cs_one_sysmetric_per_pdb_chart.sql
--
-- Purpose:     One System Metric as per DBA_HIST_CON_SYSMETRIC_SUMM View per PDB (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/10/31
--
-- Usage:       Execute connected to CDB or PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_one_sysmetric_per_pdb_chart.sql
--
-- Notes:       Developed and tested on 19c.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_one_sysmetric_per_pdb_chart';
DEF cs_hours_range_default = '168';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
@@cs_internal/&&cs_set_container_to_cdb_root.
COL metric_name FOR A40;
COL metric_unit FOR A40;
SELECT DISTINCT h.metric_name, h.metric_unit
  FROM dba_hist_con_sysmetric_summ h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id = TO_NUMBER('&&cs_snap_id_to.')
 ORDER BY
       h.metric_name, h.metric_unit
/
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO 3. Metric Name: 
DEF cs_metric_name = '&3.';
UNDEF 3;
COL cs_metric_name NEW_V cs_metric_name NOPRI;
COL cs_metric_unit NEW_V cs_metric_unit NOPRI;
@@cs_internal/&&cs_set_container_to_cdb_root.
SELECT h.metric_name AS cs_metric_name, h.metric_unit AS cs_metric_unit
  FROM dba_hist_con_sysmetric_summ h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id = TO_NUMBER('&&cs_snap_id_to.')
   AND h.metric_name = TRIM('&&cs_metric_name.')
   AND ROWNUM = 1
/
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO 4. Metric Value: [{average}|maxval]
DEF cs_metric_value = '&4.';
UNDEF 1;
COL cs_metric_value NEW_V cs_metric_value NOPRI;
SELECT CASE WHEN LOWER(TRIM('&&cs_metric_value.')) IN ('average' ,'maxval') THEN LOWER(TRIM('&&cs_metric_value.')) ELSE 'average' END AS cs_metric_value FROM DUAL
/
COL cs_hea NEW_V cs_hea NOPRI;
COL cs_func NEW_V cs_func NOPRI;
SELECT CASE '&&cs_metric_value.' WHEN 'average' THEN 'Average' WHEN 'maxval' THEN 'Maximum' ELSE 'Error' END AS cs_hea, CASE '&&cs_metric_value.' WHEN 'average' THEN 'AVG' WHEN 'maxval' THEN 'MAX' ELSE 'Error' END AS cs_func FROM DUAL
/
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
DEF con_id_01 = ' ';
DEF con_id_02 = ' ';
DEF con_id_03 = ' ';
DEF con_id_04 = ' ';
DEF con_id_05 = ' ';
DEF con_id_06 = ' ';
DEF con_id_07 = ' ';
DEF con_id_08 = ' ';
DEF con_id_09 = ' ';
DEF con_id_10 = ' ';
DEF con_id_11 = ' ';
DEF con_id_12 = ' ';
DEF con_id_13 = ' ';
DEF con_id_14 = ' ';
DEF con_id_15 = ' ';
COL con_id_01 NEW_V con_id_01 NOPRI;
COL con_id_02 NEW_V con_id_02 NOPRI;
COL con_id_03 NEW_V con_id_03 NOPRI;
COL con_id_04 NEW_V con_id_04 NOPRI;
COL con_id_05 NEW_V con_id_05 NOPRI;
COL con_id_06 NEW_V con_id_06 NOPRI;
COL con_id_07 NEW_V con_id_07 NOPRI;
COL con_id_08 NEW_V con_id_08 NOPRI;
COL con_id_09 NEW_V con_id_09 NOPRI;
COL con_id_10 NEW_V con_id_10 NOPRI;
COL con_id_11 NEW_V con_id_11 NOPRI;
COL con_id_12 NEW_V con_id_12 NOPRI;
COL con_id_13 NEW_V con_id_13 NOPRI;
COL con_id_14 NEW_V con_id_14 NOPRI;
COL con_id_15 NEW_V con_id_15 NOPRI;
DEF pdb_name_01 = ' ';
DEF pdb_name_02 = ' ';
DEF pdb_name_03 = ' ';
DEF pdb_name_04 = ' ';
DEF pdb_name_05 = ' ';
DEF pdb_name_06 = ' ';
DEF pdb_name_07 = ' ';
DEF pdb_name_08 = ' ';
DEF pdb_name_09 = ' ';
DEF pdb_name_10 = ' ';
DEF pdb_name_11 = ' ';
DEF pdb_name_12 = ' ';
DEF pdb_name_13 = ' ';
DEF pdb_name_14 = ' ';
DEF pdb_name_15 = ' ';
COL pdb_name_01 NEW_V pdb_name_01 NOPRI;
COL pdb_name_02 NEW_V pdb_name_02 NOPRI;
COL pdb_name_03 NEW_V pdb_name_03 NOPRI;
COL pdb_name_04 NEW_V pdb_name_04 NOPRI;
COL pdb_name_05 NEW_V pdb_name_05 NOPRI;
COL pdb_name_06 NEW_V pdb_name_06 NOPRI;
COL pdb_name_07 NEW_V pdb_name_07 NOPRI;
COL pdb_name_08 NEW_V pdb_name_08 NOPRI;
COL pdb_name_09 NEW_V pdb_name_09 NOPRI;
COL pdb_name_10 NEW_V pdb_name_10 NOPRI;
COL pdb_name_11 NEW_V pdb_name_11 NOPRI;
COL pdb_name_12 NEW_V pdb_name_12 NOPRI;
COL pdb_name_13 NEW_V pdb_name_13 NOPRI;
COL pdb_name_14 NEW_V pdb_name_14 NOPRI;
COL pdb_name_15 NEW_V pdb_name_15 NOPRI;
--
WITH
all_pdbs AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.con_id,
       &&cs_func.(&&cs_metric_value.) AS value,
       ROW_NUMBER() OVER (ORDER BY &&cs_func.(&&cs_metric_value.) DESC NULLS LAST) AS rn
  FROM dba_hist_con_sysmetric_summ h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND h.end_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.end_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.metric_name = '&&cs_metric_name.'
   AND h.metric_unit = '&&cs_metric_unit.'
 GROUP BY
       h.con_id
),
top_15 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.rn, TO_CHAR(h.con_id) AS con_id, c.name AS pdb_name, value
  FROM all_pdbs h, v$containers c
 WHERE h.rn <= 13
   AND c.con_id = h.con_id
)
SELECT (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 01) AS con_id_01,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 01) AS pdb_name_01,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 02) AS con_id_02,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 02) AS pdb_name_02,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 03) AS con_id_03,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 03) AS pdb_name_03,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 04) AS con_id_04,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 04) AS pdb_name_04,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 05) AS con_id_05,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 05) AS pdb_name_05,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 06) AS con_id_06,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 06) AS pdb_name_06,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 07) AS con_id_07,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 07) AS pdb_name_07,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 08) AS con_id_08,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 08) AS pdb_name_08,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 09) AS con_id_09,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 09) AS pdb_name_09,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 10) AS con_id_10,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 10) AS pdb_name_10,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 11) AS con_id_11,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 11) AS pdb_name_11,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 12) AS con_id_12,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 12) AS pdb_name_12,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 13) AS con_id_13,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 13) AS pdb_name_13,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 14) AS con_id_14,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 14) AS pdb_name_14,
       (SELECT NVL(con_id  , ' ') FROM top_15 WHERE rn = 15) AS con_id_15,
       (SELECT NVL(pdb_name, ' ') FROM top_15 WHERE rn = 15) AS pdb_name_15
  FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "&&cs_hea. - &&cs_metric_name. per PDB";
DEF chart_title = "&&cs_hea. - &&cs_metric_name. per PDB";
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to.";
-- DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
-- DEF cs_trendlines_series = ", 0:{}, 1:{}, 2:{}, 3:{}, 4:{}, 5:{}";
DEF vaxis_title = "&&cs_metric_unit.";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
-- DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
-- DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_metric_name." "&&cs_metric_value."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'&&pdb_name_01.', id:'01', type:'number'} 
PRO ,{label:'&&pdb_name_02.', id:'02', type:'number'} 
PRO ,{label:'&&pdb_name_03.', id:'03', type:'number'} 
PRO ,{label:'&&pdb_name_04.', id:'04', type:'number'} 
PRO ,{label:'&&pdb_name_05.', id:'05', type:'number'} 
PRO ,{label:'&&pdb_name_06.', id:'06', type:'number'} 
PRO ,{label:'&&pdb_name_07.', id:'07', type:'number'} 
PRO ,{label:'&&pdb_name_08.', id:'08', type:'number'} 
PRO ,{label:'&&pdb_name_09.', id:'09', type:'number'} 
PRO ,{label:'&&pdb_name_10.', id:'10', type:'number'} 
PRO ,{label:'&&pdb_name_11.', id:'11', type:'number'} 
PRO ,{label:'&&pdb_name_12.', id:'12', type:'number'} 
PRO ,{label:'&&pdb_name_13.', id:'13', type:'number'} 
-- PRO ,{label:'&&pdb_name_14.', id:'14', type:'number'} 
-- PRO ,{label:'&&pdb_name_15.', id:'15', type:'number'} 
PRO ,{label:'All Others',     id:'16', type:'number'} 
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
all_pdbs AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.end_time,
       h.con_id,
       &&cs_metric_value. AS value
  FROM dba_hist_con_sysmetric_summ h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND h.end_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.end_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.metric_name = '&&cs_metric_name.'
   AND h.metric_unit = '&&cs_metric_unit.'
)
SELECT ', [new Date('||
       TO_CHAR(h.end_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(h.end_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(h.end_time, 'DD')|| /* day */
       ','||TO_CHAR(h.end_time, 'HH24')|| /* hour */
       ','||TO_CHAR(h.end_time, 'MI')|| /* minute */
       ','||TO_CHAR(h.end_time, 'SS')|| /* second */
       ')'||
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_01.', '0')) THEN h.value ELSE 0 END), 3)|| 
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_02.', '0')) THEN h.value ELSE 0 END), 3)||  
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_03.', '0')) THEN h.value ELSE 0 END), 3)||  
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_04.', '0')) THEN h.value ELSE 0 END), 3)||  
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_05.', '0')) THEN h.value ELSE 0 END), 3)||  
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_06.', '0')) THEN h.value ELSE 0 END), 3)||  
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_07.', '0')) THEN h.value ELSE 0 END), 3)||  
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_08.', '0')) THEN h.value ELSE 0 END), 3)||  
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_09.', '0')) THEN h.value ELSE 0 END), 3)||  
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_10.', '0')) THEN h.value ELSE 0 END), 3)||  
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_11.', '0')) THEN h.value ELSE 0 END), 3)||  
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_12.', '0')) THEN h.value ELSE 0 END), 3)||  
       ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_13.', '0')) THEN h.value ELSE 0 END), 3)||  
      --  ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_14.', '0')) THEN h.value ELSE 0 END), 3)||  
      --  ','||num_format(SUM(CASE WHEN h.con_id = TO_NUMBER(NVL('&&con_id_15.', '0')) THEN h.value ELSE 0 END), 3)|| 
       ','||num_format(SUM(CASE WHEN h.con_id IN (
       TO_NUMBER(NVL('&&con_id_01.', '0')),
       TO_NUMBER(NVL('&&con_id_02.', '0')),
       TO_NUMBER(NVL('&&con_id_03.', '0')),
       TO_NUMBER(NVL('&&con_id_04.', '0')),
       TO_NUMBER(NVL('&&con_id_05.', '0')),
       TO_NUMBER(NVL('&&con_id_06.', '0')),
       TO_NUMBER(NVL('&&con_id_07.', '0')),
       TO_NUMBER(NVL('&&con_id_08.', '0')),
       TO_NUMBER(NVL('&&con_id_09.', '0')),
       TO_NUMBER(NVL('&&con_id_10.', '0')),
       TO_NUMBER(NVL('&&con_id_11.', '0')),
       TO_NUMBER(NVL('&&con_id_12.', '0')),
       TO_NUMBER(NVL('&&con_id_13.', '0'))
      --  TO_NUMBER(NVL('&&con_id_14.', '0')),
      --  TO_NUMBER(NVL('&&con_id_15.', '0'))
       ) THEN 0 ELSE h.value END), 3)||
       ']'
  FROM all_pdbs h
 GROUP BY
       h.end_time
 ORDER BY
       h.end_time
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