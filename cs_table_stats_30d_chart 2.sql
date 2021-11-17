----------------------------------------------------------------------------------------
--
-- File name:   cs_table_stats_30d_chart.sql
--
-- Purpose:     CBO Statistics History for given Table (30 days time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/09/13
--
-- Usage:       Execute connected to PDB.
--
--              Enter Table when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_table_stats_30d_chart.sql
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
DEF cs_script_name = 'cs_table_stats_30d_chart';
--
COL owner NEW_V owner FOR A30 TRUNC PRI HEA 'TABLE_OWNER';
COL tables FOR 999,990;
--
SELECT o.owner,
       COUNT(DISTINCT o.object_name) AS tables
  FROM wri$_optstat_tab_history h,
       dba_objects o,
       dba_users u
 WHERE o.object_id = h.obj#
   AND o.object_type = 'TABLE'
   AND u.username = o.owner
   AND u.oracle_maintained = 'N'
   AND u.common = 'NO'
 GROUP BY
       o.owner
 ORDER BY 1
/
--
COL table_owner NEW_V table_owner FOR A30 TRUNC PRI;
PRO
PRO 1. Table Owner:
DEF table_owner = '&1.';
UNDEF 1;
SELECT UPPER(NVL('&&table_owner.', '&&owner.')) AS table_owner FROM DUAL
/
--
COL table_name FOR A30 TRUNC PRI;
COL avg_rows FOR 999,999,999,990;
COL max_rows FOR 999,999,999,990;
COL min_last_analyzed FOR A19;
COL max_last_analyzed FOR A19;
--
SELECT o.object_name AS table_name,
       COUNT(*) + 1 AS samples,
       ROUND(AVG(h.rowcnt)) AS avg_rows,
       MAX(h.rowcnt) AS max_rows,
       TO_CHAR(MIN(h.analyzetime), '&&cs_datetime_full_format.') AS min_last_analyzed,
       TO_CHAR(MAX(h.analyzetime), '&&cs_datetime_full_format.') AS max_last_analyzed
  FROM wri$_optstat_tab_history h,
       dba_objects o
 WHERE o.object_id = h.obj#
   AND o.object_type = 'TABLE'
   AND o.owner = '&&table_owner.'
 GROUP BY
       o.object_name
 ORDER BY 1
/
PRO
PRO 2. Table Name:
DEF table_name = '&2.';
UNDEF 2;
COL table_name NEW_V table_name FOR A30 TRUNC NOPRI;
SELECT UPPER(TRIM('&&table_name.')) AS table_name FROM DUAL;
--
COL cs_gap_days NEW_V cs_gap_days NOPRI;
WITH
my_query AS (
SELECT h.analyzetime AS last_analyzed,
       h.rowcnt AS num_rows,
       h.blkcnt AS blocks,
       h.avgrln AS avg_row_len,
       h.samplesize AS sample_size
  FROM dba_objects o,
       wri$_optstat_tab_history h
 WHERE o.owner = '&&table_owner.'
   AND o.object_name = '&&table_name.' 
   AND o.object_type = 'TABLE'
   AND h.obj# = o.object_id
   AND h.analyzetime IS NOT NULL
 UNION
SELECT t.last_analyzed, 
       t.num_rows,
       t.blocks,
       t.avg_row_len,
       t.sample_size
  FROM dba_tables t
 WHERE t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.' 
)
SELECT 0.2 * (MAX(last_analyzed) - MIN(last_analyzed)) AS cs_gap_days FROM my_query
/
--
COL cs_hAxis_maxValue NEW_V cs_hAxis_maxValue NOPRI;
SELECT 'maxValue: new Date('||
       TO_CHAR(SYSDATE + &&cs_gap_days., 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(SYSDATE + &&cs_gap_days., 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(SYSDATE + &&cs_gap_days., 'DD')|| /* day */
       ','||TO_CHAR(SYSDATE + &&cs_gap_days., 'HH24')|| /* hour */
       ','||TO_CHAR(SYSDATE + &&cs_gap_days., 'MI')|| /* minute */
       ','||TO_CHAR(SYSDATE + &&cs_gap_days., 'SS')|| /* second */
       '), '
       AS cs_hAxis_maxValue
  FROM DUAL
/
--
PRO
PRO 3. Trendlines Type: &&cs_trendlines_types.
DEF cs_trendlines_type = '&3.';
UNDEF 3;
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
DEF vaxis_title = "";
DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
DEF cs_trendlines_series = ", 0:{}, 1:{}";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
--DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&table_owner." "&&table_name." "&&cs_trendlines_type."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'Num Rows', id:'1', type:'number'}
PRO ,{label:'Blocks', id:'2', type:'number'}
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
SELECT h.analyzetime AS last_analyzed,
       h.rowcnt AS num_rows,
       h.blkcnt AS blocks,
       h.avgrln AS avg_row_len,
       h.samplesize AS sample_size
  FROM dba_objects o,
       wri$_optstat_tab_history h
 WHERE o.owner = '&&table_owner.'
   AND o.object_name = '&&table_name.' 
   AND o.object_type = 'TABLE'
   AND h.obj# = o.object_id
   AND h.analyzetime IS NOT NULL
 UNION
SELECT t.last_analyzed, 
       t.num_rows,
       t.blocks,
       t.avg_row_len,
       t.sample_size
  FROM dba_tables t
 WHERE t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.' 
)
SELECT ', [new Date('||
       TO_CHAR(q.last_analyzed, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.last_analyzed, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.last_analyzed, 'DD')|| /* day */
       ','||TO_CHAR(q.last_analyzed, 'HH24')|| /* hour */
       ','||TO_CHAR(q.last_analyzed, 'MI')|| /* minute */
       ','||TO_CHAR(q.last_analyzed, 'SS')|| /* second */
       ')'||
       ','||num_format(q.num_rows)|| 
       ','||num_format(q.blocks)|| 
       ']'
  FROM my_query q
 ORDER BY
       q.last_analyzed
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
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
