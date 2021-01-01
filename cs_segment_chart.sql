----------------------------------------------------------------------------------------
--
-- File name:   cs_segment_chart.sql
--
-- Purpose:     Segment Size GBs for given Segment (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/25
--
-- Usage:       Execute connected to PDB.
--
--              Enter Table when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_segment_chart.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
-- 1 GiG = 1.073741824 GB
DEF GiB_to_GB = '1.073741824';
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_segment_chart';
DEF cs_hours_range_default = '4320';
--
ALTER SESSION SET container = CDB$ROOT;
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(snap_time)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM &&cs_tools_schema..dbc_segments
/
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL max_snap_time NEW_V max_snap_time NOPRI;
SELECT TO_CHAR(MAX(snap_time), '&&cs_datetime_full_format.') AS max_snap_time FROM &&cs_tools_schema..dbc_segments WHERE pdb_name = '&&cs_con_name.';
COL sum_GB FOR 999,990.000 HEA 'SUM_GB';
COL sum_GiB FOR 999,990.000 HEA 'SUM_GiB';
COL max_GB FOR 999,990.000 HEA 'MAX_GB';
COL max_GiB FOR 999,990.000 HEA 'MAX_GiB';
COL owners FOR 999,999,990;
COL segments FOR 999,999,990;
COL partitions FOR 999,999,990;
COL tablespace_name FOR A30 TRUNC;
COL owner FOR A30 TRUNC;
COL segment_name FOR A30 TRUNC;
COL partition_name FOR A30 TRUNC;
COL segment_type NEW_V segment_type NOPRI;
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF sum_GB sum_GiB owners segments partitions ON REPORT;
--
SELECT SUM(bytes)/1e9 AS sum_GB,
       --SUM(bytes)/1e9/&&GiB_to_GB. AS sum_GiB,
       MAX(bytes)/1e9 AS max_GB,
       --MAX(bytes)/1e9/&&GiB_to_GB. AS max_GiB,
       COUNT(DISTINCT owner) AS owners,
       COUNT(DISTINCT owner||'.'||segment_name) AS segments,
       COUNT(DISTINCT owner||'.'||segment_name||'.'||partition_name) AS partitions,
       tablespace_name
  FROM &&cs_tools_schema..dbc_segments
 WHERE pdb_name = '&&cs_con_name.'
   AND snap_time = TO_DATE('&&max_snap_time.', '&&cs_datetime_full_format.')
 GROUP BY
       tablespace_name
 ORDER BY 
       1 DESC
 FETCH FIRST 30 ROWS ONLY
/
PRO
PRO 3. Tablespace Name:
DEF tablespace_name = '&3.';
UNDEF 3;
--
SELECT SUM(bytes)/1e9 AS sum_GB,
       --SUM(bytes)/1e9/&&GiB_to_GB. AS sum_GiB,
       MAX(bytes)/1e9 AS max_GB,
       --MAX(bytes)/1e9/&&GiB_to_GB. AS max_GiB,
       COUNT(DISTINCT owner||'.'||segment_name) AS segments,
       COUNT(DISTINCT owner||'.'||segment_name||'.'||partition_name) AS partitions,
       owner
  FROM &&cs_tools_schema..dbc_segments
 WHERE pdb_name = '&&cs_con_name.'
   AND snap_time = TO_DATE('&&max_snap_time.', '&&cs_datetime_full_format.')
   AND tablespace_name = '&&tablespace_name.'
 GROUP BY
       owner
 ORDER BY 
       1 DESC
 FETCH FIRST 30 ROWS ONLY
/
PRO
PRO 4. Owner:
DEF owner = '&4.';
UNDEF 4;
--
SELECT SUM(bytes)/1e9 AS sum_GB,
       --SUM(bytes)/1e9/&&GiB_to_GB. AS sum_GiB,
       MAX(bytes)/1e9 AS max_GB,
       --MAX(bytes)/1e9/&&GiB_to_GB. AS max_GiB,
       COUNT(DISTINCT owner||'.'||segment_name||'.'||partition_name) AS partitions,
       segment_name
  FROM &&cs_tools_schema..dbc_segments
 WHERE pdb_name = '&&cs_con_name.'
   AND snap_time = TO_DATE('&&max_snap_time.', '&&cs_datetime_full_format.')
   AND tablespace_name = '&&tablespace_name.'
   AND owner = '&&owner.'
 GROUP BY
       segment_name
 ORDER BY 
       1 DESC
 FETCH FIRST 30 ROWS ONLY
/
PRO
PRO 5. Segment Name:
DEF segment_name = '&5.';
UNDEF 5;
--
SELECT SUM(bytes)/1e9 AS sum_GB,
       --SUM(bytes)/1e9/&&GiB_to_GB. AS sum_GiB,
       partition_name
  FROM &&cs_tools_schema..dbc_segments
 WHERE pdb_name = '&&cs_con_name.'
   AND snap_time = TO_DATE('&&max_snap_time.', '&&cs_datetime_full_format.')
   AND tablespace_name = '&&tablespace_name.'
   AND owner = '&&owner.'
   AND segment_name = '&&segment_name.'
 GROUP BY
       partition_name
 ORDER BY 
       1 DESC
 FETCH FIRST 30 ROWS ONLY
/
PRO
PRO 6. Partition Name (opt):
DEF partition_name = '&6.';
UNDEF 6;
--
SELECT segment_type
  FROM &&cs_tools_schema..dbc_segments
 WHERE pdb_name = '&&cs_con_name.'
   AND snap_time = TO_DATE('&&max_snap_time.', '&&cs_datetime_full_format.')
   AND tablespace_name = '&&tablespace_name.'
   AND owner = '&&owner.'
   AND segment_name = '&&segment_name.'
   AND ('&&partition_name.' IS NULL OR partition_name = '&&partition_name.')
 GROUP BY
       segment_type
 ORDER BY 
       segment_type
/
--
PRO
PRO 7. Trendlines Type: &&cs_trendlines_types.
DEF cs_trendlines_type = '&7.';
UNDEF 7;
COL cs_trendlines_type NEW_V cs_trendlines_type NOPRI;
COL cs_trendlines NEW_V cs_trendlines NOPRI;
COL cs_hAxis_maxValue NEW_V cs_hAxis_maxValue NOPRI;
SELECT CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential', 'none') THEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) ELSE 'none' END AS cs_trendlines_type,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) = 'none' THEN '//' END AS cs_trendlines,
       CASE WHEN LOWER(TRIM(NVL('&&cs_trendlines_type.', 'none'))) IN ('linear', 'polynomial', 'exponential') THEN '&&cs_hAxis_maxValue.' END AS cs_hAxis_maxValue
  FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&tablespace_name._&&owner._&&segment_name.'||CASE WHEN '&&partition_name.' IS NOT NULL THEN '_&&partition_name.' END AS cs_file_name FROM DUAL;
--
DEF report_title = "&&tablespace_name.: &&owner..&&segment_name. &&partition_name. (&&segment_type.)";
DEF chart_title = "&&tablespace_name.: &&owner..&&segment_name. &&partition_name. (&&segment_type.)";
DEF xaxis_title = "";
DEF hAxis_maxValue = "&&cs_hAxis_maxValue.";
DEF cs_trendlines_series = ", 0:{}";
DEF vaxis_title = "Gigabytes (GB)";
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2) ";
DEF chart_foot_note_2 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&tablespace_name." "&&owner." "&&segment_name." "&&partition_name." "&&cs_trendlines_type."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'Size GB', id:'1', type:'number'}
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
       ROUND(SUM(bytes)/1e9, 3) AS sum_GB,
       ROUND(SUM(bytes)/1e9/&&GiB_to_GB., 3) AS sum_GiB
  FROM &&cs_tools_schema..dbc_segments
 WHERE pdb_name = '&&cs_con_name.'
   AND tablespace_name = '&&tablespace_name.'
   AND owner = '&&owner.'
   AND segment_name = '&&segment_name.'
   AND ('&&partition_name.' IS NULL OR partition_name = '&&partition_name.')
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
       ','||num_format(q.sum_GB, 3)|| 
       ']'
  FROM my_query q
 ORDER BY
       q.snap_time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|SteppedArea|Scatter]
DEF cs_chart_type = 'Line';
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

