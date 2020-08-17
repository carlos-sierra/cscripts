----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlmon_duration_chart.sql
--
-- Purpose:     Charts duration of SQL for which there exist a SQL Monitor report
--
-- Author:      Carlos Sierra
--
-- Version:     2020/06/14
--
-- Usage:       Execute connected to PDB or CDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlmon_duration_chart.sql
--
-- Notes:       *** Requires Oracle Tuning Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sqlmon_duration_chart';
--
COL key1 FOR A13 HEA 'SQL_ID';
COL seconds FOR 999,999,990;
COL secs_avg FOR 999,990;
COL secs_max FOR 999,999,990;
COL sql_text FOR A100 HEA 'SQL_TEXT' TRUNC;
COL reports FOR 999,990;
COL pdbs FOR 9,990;
COL pdb_name FOR A30 TRUNC;
--
WITH 
sqlmonitor AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       SUM(r.period_end_time - r.period_start_time) * 24 * 3600 seconds,
       COUNT(*) reports,
       COUNT(DISTINCT r.con_id) pdbs,
       MAX(r.period_end_time - r.period_start_time) * 24 * 3600 secs_max,
       ROUND(SUM(r.period_end_time - r.period_start_time) * 24 * 3600 / COUNT(*)) secs_avg,
       MIN(r.period_start_time) min_start_time,
       MAX(r.period_end_time) max_end_time,
       r.key1
  FROM cdb_hist_reports r
 WHERE r.component_name = 'sqlmonitor'
   AND r.key1 IS NOT NULL
   AND LENGTH(r.key1) = 13
   AND r.dbid = TO_NUMBER('&&cs_dbid.')
   AND r.instance_number = TO_NUMBER('&&cs_instance_number.')
 GROUP BY
       r.key1
)
, sqlmonitor_extended AS (
SELECT r.seconds,
       r.reports,
       r.pdbs,
       r.secs_max,
       r.secs_avg,
       r.min_start_time,
       r.max_end_time,
       r.key1,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = r.key1 AND ROWNUM = 1) sql_text
  FROM sqlmonitor r
)
SELECT r.seconds,
       r.reports,
       r.pdbs,
       r.secs_max,
       r.secs_avg,
       r.min_start_time,
       r.max_end_time,
       r.key1,
       r.sql_text
  FROM sqlmonitor_extended r
 WHERE r.sql_text IS NOT NULL
   AND r.sql_text NOT LIKE 'BEGIN%'
   AND r.sql_text NOT LIKE '/* SQL Analyze(1) */%'
 ORDER BY
       r.seconds DESC, 
       r.reports DESC
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Enter additional SQL Text filtering, such as Table name or SQL Text piece
PRO
PRO 1. SQL Text piece (opt):
DEF cs2_sql_text_piece = '&1.';
UNDEF 1;
--
PRO
PRO 2. SQL_ID (opt if text was entered): 
DEF cs_sql_id = '&2.';
UNDEF 2;
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
COL min_time NEW_V min_time FOR A19 NOPRI;
COL max_time NEW_V max_time FOR A19 NOPRI;
WITH
my_query AS (
SELECT period_end_time AS end_time,
       ROUND((period_end_time - period_start_time) * 24 * 3600) AS seconds
  FROM cdb_hist_reports h
 WHERE component_name = 'sqlmonitor'
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND ('&&cs2_sql_text_piece.' IS NULL OR UPPER((SELECT s.sql_text FROM v$sql s WHERE s.sql_id = h.key1 AND ROWNUM = 1)) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37) OR h.key1 = '&&cs2_sql_text_piece.')
   AND ('&&cs_sql_id.' IS NULL OR h.key1 = '&&cs_sql_id.')
 UNION
SELECT MAX(r.last_refresh_time) AS end_time,
       ROUND(MAX(r.elapsed_time)/1e6) AS seconds
  FROM v$sql_monitor r
 WHERE ('&&cs2_sql_text_piece.' IS NULL OR UPPER(r.sql_text) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37) OR r.sql_id = '&&cs2_sql_text_piece.')
   AND ('&&cs_sql_id.' IS NULL OR r.sql_id = '&&cs_sql_id.')
 GROUP BY
       r.sql_exec_id,
       r.sql_exec_start
)
SELECT TO_CHAR(MIN(end_time), '&&cs_datetime_full_format.') AS min_time, TO_CHAR(MAX(end_time), '&&cs_datetime_full_format.') AS max_time FROM my_query
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
DEF report_title = 'Monitored Executions of TEXT:"&&cs2_sql_text_piece." SQL_ID:"&&cs_sql_id."';
DEF chart_title = '&&report_title.';
DEF xaxis_title = "between &&min_time. and &&max_time.";
DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
DEF cs_trendlines_series = ", 0:{}, 1:{}";
DEF vaxis_title = "Elapsed Seconds";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
DEF is_stacked = "isStacked: false,";
--DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:1200";
DEF vaxis_baseline = "";
--DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs2_sql_text_piece." "&&cs_sql_id." "&&cs_trendlines_type."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'Elapsed Time'
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
my_query AS (
SELECT period_end_time AS end_time,
       ROUND((period_end_time - period_start_time) * 24 * 3600) AS seconds
  FROM cdb_hist_reports h
 WHERE component_name = 'sqlmonitor'
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND ('&&cs2_sql_text_piece.' IS NULL OR UPPER((SELECT s.sql_text FROM v$sql s WHERE s.sql_id = h.key1 AND ROWNUM = 1)) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37) OR h.key1 = '&&cs2_sql_text_piece.')
   AND ('&&cs_sql_id.' IS NULL OR h.key1 = '&&cs_sql_id.')
 UNION
SELECT MAX(r.last_refresh_time) AS end_time,
       ROUND(MAX(r.elapsed_time)/1e6) AS seconds
  FROM v$sql_monitor r
 WHERE ('&&cs2_sql_text_piece.' IS NULL OR UPPER(r.sql_text) LIKE CHR(37)||UPPER('&&cs2_sql_text_piece.')||CHR(37) OR r.sql_id = '&&cs2_sql_text_piece.')
   AND ('&&cs_sql_id.' IS NULL OR r.sql_id = '&&cs_sql_id.')
 GROUP BY
       r.sql_exec_id,
       r.sql_exec_start
)
SELECT ', [new Date('||
       TO_CHAR(q.end_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.end_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.end_time, 'DD')|| /* day */
       ','||TO_CHAR(q.end_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.end_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.end_time, 'SS')|| /* second */
       ')'||
       ','||q.seconds|| 
       ']'
  FROM my_query q
 ORDER BY
       q.end_time
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
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
