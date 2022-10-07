----------------------------------------------------------------------------------------
--
-- File name:   cs_top_pdb_tps_chart.sql
--
-- Purpose:     Top PDBs as per TPS (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/26
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_pdb_tps_chart.sql
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
DEF cs_script_name = 'cs_top_pdb_tps_chart';
DEF cs_hours_range_default = '168';
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
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "Top PDBs as per their TPS between &&cs_sample_time_from. and &&cs_sample_time_to. UTC";
DEF chart_title = "&&report_title.";
DEF xaxis_title = "";
DEF vaxis_title = "Transactions per Second (TPS)";
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
DEF spool_id_chart_footer_script = 'cs_top_14_footer.sql';
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
DEF value_01 = "";
DEF value_02 = "";
DEF value_03 = "";
DEF value_04 = "";
DEF value_05 = "";
DEF value_06 = "";
DEF value_08 = "";
DEF value_09 = "";
DEF value_10 = "";
DEF value_11 = "";
DEF value_12 = "";
DEF value_13 = "";
DEF value_14 = "";
DEF value_others = "OTHER PDBS";
--
COL top_01 NEW_V top_01 FOR A30 TRUNC NOPRI;
COL top_02 NEW_V top_02 FOR A30 TRUNC NOPRI;
COL top_03 NEW_V top_03 FOR A30 TRUNC NOPRI;
COL top_04 NEW_V top_04 FOR A30 TRUNC NOPRI;
COL top_05 NEW_V top_05 FOR A30 TRUNC NOPRI;
COL top_06 NEW_V top_06 FOR A30 TRUNC NOPRI;
COL top_07 NEW_V top_07 FOR A30 TRUNC NOPRI;
COL top_08 NEW_V top_08 FOR A30 TRUNC NOPRI;
COL top_09 NEW_V top_09 FOR A30 TRUNC NOPRI;
COL top_10 NEW_V top_10 FOR A30 TRUNC NOPRI;
COL top_11 NEW_V top_11 FOR A30 TRUNC NOPRI;
COL top_12 NEW_V top_12 FOR A30 TRUNC NOPRI;
COL top_13 NEW_V top_13 FOR A30 TRUNC NOPRI;
COL top_14 NEW_V top_14 FOR A30 TRUNC NOPRI;
COL others NEW_V others FOR A30 TRUNC NOPRI;
--
COL value_01 NEW_V value_01 FOR A10 TRUNC NOPRI;
COL value_02 NEW_V value_02 FOR A10 TRUNC NOPRI;
COL value_03 NEW_V value_03 FOR A10 TRUNC NOPRI;
COL value_04 NEW_V value_04 FOR A10 TRUNC NOPRI;
COL value_05 NEW_V value_05 FOR A10 TRUNC NOPRI;
COL value_06 NEW_V value_06 FOR A10 TRUNC NOPRI;
COL value_07 NEW_V value_07 FOR A10 TRUNC NOPRI;
COL value_08 NEW_V value_08 FOR A10 TRUNC NOPRI;
COL value_09 NEW_V value_09 FOR A10 TRUNC NOPRI;
COL value_10 NEW_V value_10 FOR A10 TRUNC NOPRI;
COL value_11 NEW_V value_11 FOR A10 TRUNC NOPRI;
COL value_12 NEW_V value_12 FOR A10 TRUNC NOPRI;
COL value_13 NEW_V value_13 FOR A10 TRUNC NOPRI;
COL value_14 NEW_V value_14 FOR A10 TRUNC NOPRI;
COL value_others NEW_V value_others FOR A10 TRUNC NOPRI;
--
-- WITH
-- pdb AS (
-- SELECT /*+ MATERIALIZE NO_MERGE */
--        c.name AS pdb_name,
--        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT h.xid) DESC) rn
--   FROM dba_hist_active_sess_history h, v$containers c
--  WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
--    AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
--    AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
--    AND xid IS NOT NULL
--    AND c.con_id = h.con_id
--  GROUP BY
--        c.name
-- )
-- SELECT MAX(CASE rn WHEN  1 THEN pdb_name END) AS top_01,
--        MAX(CASE rn WHEN  2 THEN pdb_name END) AS top_02,
--        MAX(CASE rn WHEN  3 THEN pdb_name END) AS top_03,
--        MAX(CASE rn WHEN  4 THEN pdb_name END) AS top_04,
--        MAX(CASE rn WHEN  5 THEN pdb_name END) AS top_05,
--        MAX(CASE rn WHEN  6 THEN pdb_name END) AS top_06,
--        MAX(CASE rn WHEN  7 THEN pdb_name END) AS top_07,
--        MAX(CASE rn WHEN  8 THEN pdb_name END) AS top_08,
--        MAX(CASE rn WHEN  9 THEN pdb_name END) AS top_09,
--        MAX(CASE rn WHEN 10 THEN pdb_name END) AS top_10,
--        MAX(CASE rn WHEN 11 THEN pdb_name END) AS top_11,
--        MAX(CASE rn WHEN 12 THEN pdb_name END) AS top_12,
--        MAX(CASE rn WHEN 13 THEN pdb_name END) AS top_13,
--        MAX(CASE rn WHEN 14 THEN pdb_name END) AS top_14,
--        CASE WHEN COUNT(*) > 15 THEN (COUNT(*) - 15)||' OTHER PDBS' END AS others
--   FROM pdb
-- /
--
WITH
pdb AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_id,
       c.name,
       COUNT(DISTINCT h.xid) / SUM(COUNT(DISTINCT h.xid)) OVER (PARTITION BY h.snap_id) AS contribution,
       COUNT(DISTINCT snap_id) OVER () AS snaps
  FROM dba_hist_active_sess_history h, v$containers c
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND xid IS NOT NULL
   AND c.con_id = h.con_id
   AND ROWNUM >= 1
 GROUP BY
       h.snap_id,
       c.name
),
tps AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_id,
       h.end_time AS time,
       h.average
  FROM dba_hist_sysmetric_summary h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND h.group_id = 2
   AND h.metric_name = 'User Transaction Per Sec'
   AND ROWNUM >= 1
),
tps_per_pdb AS (
SELECT pdb.name AS pdb_name,
       SUM(pdb.contribution * tps.average) / MAX(pdb.snaps) tps,
       ROW_NUMBER() OVER (ORDER BY SUM(pdb.contribution * tps.average) / MAX(pdb.snaps) DESC) rn
  FROM pdb, tps
 WHERE tps.snap_id = pdb.snap_id 
 GROUP BY
       pdb.name
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
       CASE WHEN COUNT(*) > 15 THEN (COUNT(*) - 15)||' OTHER PDBS' END AS others,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN  1 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_01,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN  2 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_02,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN  3 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_03,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN  4 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_04,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN  5 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_05,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN  6 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_06,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN  7 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_07,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN  8 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_08,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN  9 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_09,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN 10 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_10,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN 11 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_11,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN 12 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_12,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN 13 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_13,
       LPAD(TO_CHAR(ROUND(SUM(CASE rn WHEN 14 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_14,
       LPAD(TO_CHAR(ROUND(SUM(CASE WHEN rn > 14 THEN tps END), 1), '999,990.0'), 10, ' ') AS value_others
  FROM tps_per_pdb
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
pdb AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_id,
       c.name,
       COUNT(DISTINCT h.xid) / SUM(COUNT(DISTINCT h.xid)) OVER (PARTITION BY h.snap_id) AS contribution
  FROM dba_hist_active_sess_history h, v$containers c
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND xid IS NOT NULL
   AND c.con_id = h.con_id
   AND ROWNUM >= 1
 GROUP BY
       h.snap_id,
       c.name
),
tps AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_id,
       h.end_time AS time,
       h.average
  FROM dba_hist_sysmetric_summary h
 WHERE h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND h.group_id = 2
   AND h.metric_name = 'User Transaction Per Sec'
   AND ROWNUM >= 1
),
my_query AS (
SELECT tps.time,
       ROUND(SUM(CASE pdb.name WHEN '&&top_01.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_01,
       ROUND(SUM(CASE pdb.name WHEN '&&top_02.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_02,
       ROUND(SUM(CASE pdb.name WHEN '&&top_03.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_03,
       ROUND(SUM(CASE pdb.name WHEN '&&top_04.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_04,
       ROUND(SUM(CASE pdb.name WHEN '&&top_05.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_05,
       ROUND(SUM(CASE pdb.name WHEN '&&top_06.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_06,
       ROUND(SUM(CASE pdb.name WHEN '&&top_07.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_07,
       ROUND(SUM(CASE pdb.name WHEN '&&top_08.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_08,
       ROUND(SUM(CASE pdb.name WHEN '&&top_09.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_09,
       ROUND(SUM(CASE pdb.name WHEN '&&top_10.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_10,
       ROUND(SUM(CASE pdb.name WHEN '&&top_11.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_11,
       ROUND(SUM(CASE pdb.name WHEN '&&top_12.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_12,
       ROUND(SUM(CASE pdb.name WHEN '&&top_13.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_13,
       ROUND(SUM(CASE pdb.name WHEN '&&top_14.' THEN pdb.contribution * tps.average ELSE 0 END), 3) AS top_14,
       ROUND(SUM(CASE WHEN pdb.name IN ('&&top_01.', '&&top_02.', '&&top_03.', '&&top_04.', '&&top_05.', '&&top_06.', '&&top_07.', '&&top_08.', '&&top_09.', '&&top_10.', '&&top_11.', '&&top_12.', '&&top_13.', '&&top_14.') THEN 0 ELSE pdb.contribution * tps.average END), 3) AS others
  FROM pdb, tps
 WHERE tps.snap_id = pdb.snap_id 
 GROUP BY
       tps.time
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
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
