----------------------------------------------------------------------------------------
--
-- File name:   cs_table_mod_chart.sql
--
-- Purpose:     Table Modification History (INS, DEL and UPD) for given Table (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/025
--
-- Usage:       Execute connected to PDB.
--
--              Enter Table when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_table_mod_chart.sql
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
DEF cs_script_name = 'cs_table_mod_chart';
DEF cs_hours_range_default = '8760';
--
ALTER SESSION SET container = CDB$ROOT;
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(last_analyzed)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM &&cs_tools_schema..dbc_tables
/
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL owner NEW_V owner FOR A30 HEA 'TABLE_OWNER';
COL oracle_maintained FOR A4 HEA 'ORCL';
COL tables FOR 999,990;
BREAK ON oracle_maintained SKIP PAGE DUPL;
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       u.oracle_maintained,
       t.owner,
       COUNT(DISTINCT t.table_name) AS tables
  FROM &&cs_tools_schema..dbc_tables t,
       cdb_users u
 WHERE t.pdb_name = '&&cs_con_name.'
   AND t.snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND u.username = t.owner
 GROUP BY
       u.oracle_maintained,
       t.owner
 ORDER BY
       u.oracle_maintained DESC,
       t.owner
/
COL table_owner NEW_V table_owner FOR A30;
PRO
PRO 3. Table Owner:
DEF table_owner = '&3.';
UNDEF 3;
SELECT UPPER(NVL('&&table_owner.', '&&owner.')) table_owner FROM DUAL
/
--
COL table_name FOR A30 TRUNC PRI;
COL num_rows FOR 999,999,999,990;
COL blocks FOR 9,999,999,990;
WITH 
sq1 AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       t.table_name, t.num_rows, t.blocks, t.last_analyzed,
       ROW_NUMBER() OVER (PARTITION BY t.table_name ORDER BY t.snap_time DESC) AS rn
  FROM &&cs_tools_schema..dbc_tables t,
       v$containers c,
       cdb_users u
 WHERE t.pdb_name = '&&cs_con_name.'
   AND t.owner = '&&table_owner.'
   AND t.snap_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND c.name = t.pdb_name
   AND u.con_id = c.con_id
   AND u.username = t.owner
)
SELECT t.table_name, t.num_rows, t.blocks, t.last_analyzed
  FROM sq1 t
 WHERE t.rn = 1
 ORDER BY
       t.table_name
/
PRO
PRO 4. Table Name:
DEF table_name = '&4.';
UNDEF 4;
COL table_name NEW_V table_name FOR A30 TRUNC NOPRI;
SELECT UPPER(TRIM('&&table_name.')) table_name FROM DUAL;
--
PRO
PRO 5. Trendlines Type: &&cs_trendlines_types.
DEF cs_trendlines_type = '&5.';
UNDEF 5;
COL cs_trendlines_type NEW_V cs_trendlines_type NOPRI;
COL cs_trendlines NEW_V cs_trendlines NOPRI;
COL cs_hAxis_maxValue NEW_V cs_hAxis_maxValue NOPRI;
SELECT CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential', 'none') THEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) ELSE 'none' END AS cs_trendlines_type,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) = 'none' THEN '//' END AS cs_trendlines,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential') THEN '&&cs_hAxis_maxValue.' END AS cs_hAxis_maxValue
  FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&table_owner..&&table_name.' cs_file_name FROM DUAL;
--
DEF report_title = "&&table_owner..&&table_name.";
DEF chart_title = "&&table_owner..&&table_name.";
DEF xaxis_title = "";
DEF vaxis_title = "Rows per Second";
DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
DEF cs_trendlines_series = ", 0:{}, 1:{}, 2:{}";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
--DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&table_owner." "&&table_name." "&&cs_trendlines_type."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'Inserts', id:'1', type:'number'}
PRO ,{label:'Deletes', id:'2', type:'number'}
PRO ,{label:'Updates', id:'3', type:'number'}
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
SELECT timestamp,
       ROUND(inserts / ((timestamp - last_analyzed) * 24 * 60 * 60), 3) AS inserts_per_sec,
       ROUND(updates / ((timestamp - last_analyzed) * 24 * 60 * 60), 3) AS updates_per_sec,
       ROUND(deletes / ((timestamp - last_analyzed) * 24 * 60 * 60), 3) AS deletes_per_sec
  FROM &&cs_tools_schema..dbc_tab_modifications
 WHERE pdb_name = '&&cs_con_name.'
   AND owner = '&&table_owner.'
   AND table_name = '&&table_name.'
   AND timestamp BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND inserts + updates + deletes >= 0
   AND timestamp - last_analyzed > 0
)
SELECT ', [new Date('||
       TO_CHAR(q.timestamp, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.timestamp, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.timestamp, 'DD')|| /* day */
       ','||TO_CHAR(q.timestamp, 'HH24')|| /* hour */
       ','||TO_CHAR(q.timestamp, 'MI')|| /* minute */
       ','||TO_CHAR(q.timestamp, 'SS')|| /* second */
       ')'||
       ','||num_format(q.inserts_per_sec)|| 
       ','||num_format(q.deletes_per_sec)|| 
       ','||num_format(q.updates_per_sec)|| 
       ']'
  FROM my_query q
 ORDER BY
       q.timestamp
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
DEF cs_curve_type = '';
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
