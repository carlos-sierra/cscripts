----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlmon_duration_chart.sql
--
-- Purpose:     SQL Monitor Reports duration for a given SQL_ID (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2022/10/11
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
DEF cs_hours_range_default = '168';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL key1 FOR A13 HEA 'SQL_ID';
COL seconds FOR 999,999,990;
COL secs_avg FOR 999,990;
COL secs_max FOR 999,999,990;
COL sql_text FOR A100 HEA 'SQL_TEXT' TRUNC;
COL reports FOR 999,990;
COL done FOR 999,990;
COL done_all_rows FOR 999,990 HEA 'DONE|ALL ROWS';
COL done_first_n_rows FOR 999,990 HEA 'DONE FIRST|N ROWS';
COL done_error FOR 999,990 HEA 'DONE|ERROR';
COL executing FOR 999,990;
COL queued FOR 999,990;
COL pdbs FOR 9,990;
COL pdb_name FOR A30 TRUNC;
--
WITH
sqlmonitor_raw AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       r.period_end_time,
       r.period_start_time,
       --Xmltype(r.report_summary).extract('//status/text()').getStringVal() AS status, -- too slow
       --REGEXP_REPLACE(REGEXP_SUBSTR(r.report_summary, '<status>[^\<]*'), '<status>') AS status, -- <status>DONE (ALL ROWS)</status>
       REGEXP_SUBSTR(r.report_summary, '[^\<]*', REGEXP_INSTR(r.report_summary, '<status>', 1, 1, 1)) AS status, -- <status>DONE (ALL ROWS)</status>
       r.con_id,
       r.key1
  FROM cdb_hist_reports r
 WHERE r.component_name = 'sqlmonitor'
   AND r.key1 IS NOT NULL
   AND LENGTH(r.key1) = 13
   AND r.dbid = TO_NUMBER('&&cs_dbid.')
   AND r.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND r.period_end_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND ROWNUM >= 1 /*+ MATERIALIZE NO_MERGE */
)
, sqlmonitor_grouped AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       SUM(r.period_end_time - r.period_start_time) * 24 * 3600 AS seconds,
       COUNT(*) AS reports,
       SUM(CASE r.status WHEN 'DONE' THEN 1 ELSE 0 END) AS done,
       SUM(CASE r.status WHEN 'DONE (ALL ROWS)' THEN 1 ELSE 0 END) AS done_all_rows,
       SUM(CASE r.status WHEN 'DONE (FIRST N ROWS)' THEN 1 ELSE 0 END) AS done_first_n_rows,
       SUM(CASE r.status WHEN 'DONE (ERROR)' THEN 1 ELSE 0 END) AS done_error,
       SUM(CASE r.status WHEN 'EXECUTING' THEN 1 ELSE 0 END) AS executing,
       SUM(CASE r.status WHEN 'QUEUED' THEN 1 ELSE 0 END) AS queued,
       COUNT(DISTINCT r.con_id) AS pdbs,
       MAX(r.period_end_time - r.period_start_time) * 24 * 3600 AS secs_max,
       ROUND(SUM(r.period_end_time - r.period_start_time) * 24 * 3600 / COUNT(*)) AS secs_avg,
       MIN(r.period_start_time) AS min_start_time,
       MAX(r.period_end_time) AS max_end_time,
       r.key1
  FROM sqlmonitor_raw r
 WHERE ROWNUM >= 1 /*+ MATERIALIZE NO_MERGE */
 GROUP BY
       r.key1
)
, sqlmonitor_extended AS (
SELECT r.seconds,
       r.reports,
       r.done,
       r.done_all_rows,
       r.done_first_n_rows,
       r.done_error,
       r.executing,
       r.queued,
       r.pdbs,
       r.secs_max,
       r.secs_avg,
       r.min_start_time,
       r.max_end_time,
       r.key1,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = r.key1 AND ROWNUM = 1) sql_text
  FROM sqlmonitor_grouped r
)
SELECT r.seconds,
       r.reports,
       r.done,
       r.done_all_rows,
       r.done_first_n_rows,
       r.done_error,
       r.executing,
       r.queued,
       r.pdbs,
       r.secs_max,
       r.secs_avg,
       r.min_start_time,
       r.max_end_time,
       r.key1,
       r.sql_text
  FROM sqlmonitor_extended r
 WHERE 1 = 1
   AND NVL(r.sql_text, 'NULL') NOT LIKE 'BEGIN%'
   AND NVL(r.sql_text, 'NULL') NOT LIKE '/* SQL Analyze(1) */%'
 ORDER BY
       r.seconds DESC, 
       r.reports DESC
 FETCH FIRST 1000 ROWS ONLY
/
--
PRO
PRO 3. SQL_ID: 
DEF cs_sql_id = '&3.';
UNDEF 3;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
PRO
PRO 4. Trendlines Type: &&cs_trendlines_types.
DEF cs_trendlines_type = '&4.';
UNDEF 4;
COL cs_trendlines_type NEW_V cs_trendlines_type NOPRI;
COL cs_trendlines NEW_V cs_trendlines NOPRI;
COL cs_hAxis_maxValue NEW_V cs_hAxis_maxValue NOPRI;
SELECT CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential', 'none') THEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) ELSE 'none' END AS cs_trendlines_type,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) = 'none' THEN '//' END AS cs_trendlines,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential') THEN '&&cs_hAxis_maxValue.' END AS cs_hAxis_maxValue
  FROM DUAL
/
--
DEF report_title = 'SQL Monitored Executions of: &&cs_sql_id.';
DEF chart_title = '&&report_title.';
DEF xaxis_title = "between &&cs_sample_time_from. and &&cs_sample_time_to. UTC";
DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
DEF cs_trendlines_series = ", 0:{}, 1:{}, 2:{}, 3:{}";
DEF vaxis_title = "Seconds";
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
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&cs_trendlines_type."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'Duration Seconds', id:'1', type:'number'}
-- PRO ,{label:'Elapsed Seconds', id:'1', type:'number'}
-- PRO ,{label:'CPU Seconds', id:'1', type:'number'}
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
SELECT period_end_time AS end_time,
       ROUND((period_end_time - period_start_time) * 24 * 3600) AS duration_seconds,
       TO_NUMBER(NULL) AS elapsed_seconds,
       TO_NUMBER(NULL) AS cpu_seconds
  FROM cdb_hist_reports h
 WHERE component_name = 'sqlmonitor'
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND ('&&cs_sql_id.' IS NULL OR h.key1 = '&&cs_sql_id.')
   AND period_end_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 UNION
SELECT MAX(r.last_refresh_time) AS end_time,
       ROUND(MAX(r.last_refresh_time - r.sql_exec_start) * 24 * 3600) AS duration_seconds,
       ROUND(MAX(r.elapsed_time)/1e6) AS elapsed_seconds,
       ROUND(MAX(r.cpu_time)/1e6) AS cpu_seconds
  FROM v$sql_monitor r
 WHERE ('&&cs_sql_id.' IS NULL OR r.sql_id = '&&cs_sql_id.')
   AND r.last_refresh_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
 GROUP BY
       r.key
)
SELECT ', [new Date('||
       TO_CHAR(q.end_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.end_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.end_time, 'DD')|| /* day */
       ','||TO_CHAR(q.end_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.end_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.end_time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.duration_seconds)|| 
      --  ','||num_format(q.elapsed_seconds)|| 
      --  ','||num_format(q.cpu_seconds)|| 
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
