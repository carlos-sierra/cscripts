----------------------------------------------------------------------------------------
--
-- File name:   cs_top_table_size_chart.sql
--
-- Purpose:     Top Table Disk Size Utilization Chart
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/14
--
-- Usage:       Execute connected to PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_table_size_chart.sql
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
DEF cs_script_name = 'cs_top_table_size_chart';
DEF cs_hours_range_default = '4320';
--
ALTER SESSION SET container = CDB$ROOT;
ALTER SESSION SET "_px_cdb_view_enabled" = FALSE;
--
COL cs_hours_range_default NEW_V cs_hours_range_default NOPRI;
SELECT TRIM(TO_CHAR(LEAST(TRUNC((SYSDATE - MIN(snap_time)) * 24), TO_NUMBER('&&cs_hours_range_default.')))) AS cs_hours_range_default FROM c##iod.segments_hist
/
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "Top Tables in terms of Used Disk Space between &&cs_sample_time_from. and &&cs_sample_time_to. UTC";
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
seg_hist AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       owner,
       segment_name,
       CASE 
         WHEN segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION') THEN 'TABLE' 
         WHEN segment_type IN ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION', 'LOBINDEX') THEN 'INDEX'
         WHEN segment_type IN ('LOBSEGMENT', 'LOB PARTITION', 'LOB SUBPARTITION') THEN 'LOB'
       END AS segment_type,
       snap_time,
       SUM(bytes) AS bytes
  FROM c##iod.segments_hist
 WHERE snap_time = (SELECT MAX(snap_time) FROM c##iod.segments_hist WHERE snap_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND snap_time < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.'))
   AND pdb_name = '&&cs_con_name.'
   AND con_id = &&cs_con_id.
   AND segment_name NOT LIKE 'BIN$%'
   AND segment_name NOT LIKE 'MLOG$%'
   AND segment_name NOT LIKE 'REDEF$%'
   AND owner NOT LIKE 'C##%'
   AND owner IN (SELECT username FROM cdb_users WHERE con_id = &&cs_con_id. AND oracle_maintained = 'N' AND username NOT LIKE 'C##%')
 GROUP BY
       owner,
       segment_name,
       CASE 
         WHEN segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION') THEN 'TABLE' 
         WHEN segment_type IN ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION', 'LOBINDEX') THEN 'INDEX'
         WHEN segment_type IN ('LOBSEGMENT', 'LOB PARTITION', 'LOB SUBPARTITION') THEN 'LOB'
       END,
       snap_time
),
table_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       owner AS table_owner,
       segment_name AS table_name,
       snap_time,
       SUM(bytes) bytes
  FROM seg_hist
 WHERE segment_type = 'TABLE'
 GROUP BY
       owner,
       segment_name,
       snap_time
),
idx AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       DISTINCT
       table_owner,
       table_name,
       owner,
       index_name
  FROM cdb_indexes
 WHERE con_id = &&cs_con_id.
),
indexes_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       i.table_owner,
       i.table_name,
       h.snap_time,
       SUM(h.bytes) bytes
  FROM idx i,
       seg_hist h
 WHERE h.owner = i.owner
   AND h.segment_name = i.index_name
   AND h.segment_type = 'INDEX'
 GROUP BY
       i.table_owner,
       i.table_name,
       h.snap_time
),
lobs_h AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       DISTINCT
       owner,
       table_name,
       segment_name
  FROM c##iod.lobs_hist
 WHERE pdb_name = '&&cs_con_name.'
   AND con_id = &&cs_con_id.
),
lobs_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       l.owner AS table_owner,
       l.table_name,
       h.snap_time,
       SUM(h.bytes) bytes
  FROM lobs_h l,
       seg_hist h
 WHERE h.owner = l.owner
   AND h.segment_name = l.segment_name
   AND h.segment_type = 'LOB'
 GROUP BY
       l.owner,
       l.table_name,
       h.snap_time
),
table_plus_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       t.table_owner,
       t.table_name,
       t.snap_time,
       --ROUND((NVL(SUM(t.bytes), 0) + NVL(SUM(i.bytes), 0) + NVL(SUM(l.bytes), 0)) / POWER(2,30), 3) AS gibs,
       --ROUND((NVL(SUM(t.bytes), 0) + NVL(SUM(i.bytes), 0) + NVL(SUM(l.bytes), 0)) / POWER(10,9), 3) AS gbs,
       ROW_NUMBER() OVER (ORDER BY (NVL(SUM(t.bytes), 0) + NVL(SUM(i.bytes), 0) + NVL(SUM(l.bytes), 0)) DESC) AS rn
  FROM table_ts t,
       indexes_ts i,
       lobs_ts l
 WHERE i.table_owner(+) = t.table_owner
   AND i.table_name(+) = t.table_name
   AND i.snap_time(+) = t.snap_time
   AND l.table_owner(+) = t.table_owner
   AND l.table_name(+) = t.table_name
   AND l.snap_time(+) = t.snap_time
 GROUP BY
       t.table_owner,
       t.table_name,
       t.snap_time
)
SELECT MAX(CASE rn WHEN  1 THEN table_name||'('||table_owner||')' END) AS top_01,
       MAX(CASE rn WHEN  2 THEN table_name||'('||table_owner||')' END) AS top_02,
       MAX(CASE rn WHEN  3 THEN table_name||'('||table_owner||')' END) AS top_03,
       MAX(CASE rn WHEN  4 THEN table_name||'('||table_owner||')' END) AS top_04,
       MAX(CASE rn WHEN  5 THEN table_name||'('||table_owner||')' END) AS top_05,
       MAX(CASE rn WHEN  6 THEN table_name||'('||table_owner||')' END) AS top_06,
       MAX(CASE rn WHEN  7 THEN table_name||'('||table_owner||')' END) AS top_07,
       MAX(CASE rn WHEN  8 THEN table_name||'('||table_owner||')' END) AS top_08,
       MAX(CASE rn WHEN  9 THEN table_name||'('||table_owner||')' END) AS top_09,
       MAX(CASE rn WHEN 10 THEN table_name||'('||table_owner||')' END) AS top_10,
       CASE WHEN COUNT(*) > 10 THEN (COUNT(*) - 10)||' OTHERS' END AS others
  FROM table_plus_ts
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
WITH
seg_hist AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       owner,
       segment_name,
       CASE 
         WHEN segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION') THEN 'TABLE' 
         WHEN segment_type IN ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION', 'LOBINDEX') THEN 'INDEX'
         WHEN segment_type IN ('LOBSEGMENT', 'LOB PARTITION', 'LOB SUBPARTITION') THEN 'LOB'
       END AS segment_type,
       snap_time,
       SUM(bytes) AS bytes
  FROM c##iod.segments_hist
 WHERE snap_time >= TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND snap_time < TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND pdb_name = '&&cs_con_name.'
   AND con_id = &&cs_con_id.
   AND segment_name NOT LIKE 'BIN$%'
   AND segment_name NOT LIKE 'MLOG$%'
   AND segment_name NOT LIKE 'REDEF$%'
   AND owner NOT LIKE 'C##%'
   AND owner IN (SELECT username FROM cdb_users WHERE con_id = &&cs_con_id. AND oracle_maintained = 'N' AND username NOT LIKE 'C##%')
 GROUP BY
       owner,
       segment_name,
       CASE 
         WHEN segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION') THEN 'TABLE' 
         WHEN segment_type IN ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION', 'LOBINDEX') THEN 'INDEX'
         WHEN segment_type IN ('LOBSEGMENT', 'LOB PARTITION', 'LOB SUBPARTITION') THEN 'LOB'
       END,
       snap_time
),
table_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       owner AS table_owner,
       segment_name AS table_name,
       snap_time,
       SUM(bytes) bytes
  FROM seg_hist
 WHERE segment_type = 'TABLE'
 GROUP BY
       owner,
       segment_name,
       snap_time
),
idx AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       DISTINCT
       table_owner,
       table_name,
       owner,
       index_name
  FROM cdb_indexes
 WHERE con_id = &&cs_con_id.
),
indexes_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       i.table_owner,
       i.table_name,
       h.snap_time,
       SUM(h.bytes) bytes
  FROM idx i,
       seg_hist h
 WHERE h.owner = i.owner
   AND h.segment_name = i.index_name
   AND h.segment_type = 'INDEX'
 GROUP BY
       i.table_owner,
       i.table_name,
       h.snap_time
),
lobs_h AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       DISTINCT
       owner,
       table_name,
       segment_name
  FROM c##iod.lobs_hist
 WHERE pdb_name = '&&cs_con_name.'
   AND con_id = &&cs_con_id.
),
lobs_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       l.owner AS table_owner,
       l.table_name,
       h.snap_time,
       SUM(h.bytes) bytes
  FROM lobs_h l,
       seg_hist h
 WHERE h.owner = l.owner
   AND h.segment_name = l.segment_name
   AND h.segment_type = 'LOB'
 GROUP BY
       l.owner,
       l.table_name,
       h.snap_time
),
table_plus_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       t.table_owner,
       t.table_name,
       t.snap_time,
       --ROUND((NVL(SUM(t.bytes), 0) + NVL(SUM(i.bytes), 0) + NVL(SUM(l.bytes), 0)) / POWER(2,30), 3) AS gibs,
       ROUND((NVL(SUM(t.bytes), 0) + NVL(SUM(i.bytes), 0) + NVL(SUM(l.bytes), 0)) / POWER(10,9), 3) AS gbs
  FROM table_ts t,
       indexes_ts i,
       lobs_ts l
 WHERE i.table_owner(+) = t.table_owner
   AND i.table_name(+) = t.table_name
   AND i.snap_time(+) = t.snap_time
   AND l.table_owner(+) = t.table_owner
   AND l.table_name(+) = t.table_name
   AND l.snap_time(+) = t.snap_time
 GROUP BY
       t.table_owner,
       t.table_name,
       t.snap_time
),
/****************************************************************************************/
my_query AS (
SELECT snap_time,
--       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_01.' THEN gibs ELSE 0 END) AS top_01,
--       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_02.' THEN gibs ELSE 0 END) AS top_02,
--       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_03.' THEN gibs ELSE 0 END) AS top_03,
--       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_04.' THEN gibs ELSE 0 END) AS top_04,
--       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_05.' THEN gibs ELSE 0 END) AS top_05,
--       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_06.' THEN gibs ELSE 0 END) AS top_06,
--       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_07.' THEN gibs ELSE 0 END) AS top_07,
--       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_08.' THEN gibs ELSE 0 END) AS top_08,
--       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_09.' THEN gibs ELSE 0 END) AS top_09,
--       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_10.' THEN gibs ELSE 0 END) AS top_10,
--       SUM(CASE WHEN table_name||'('||table_owner||')' IN ('&&top_01.', '&&top_02.', '&&top_03.', '&&top_04.', '&&top_05.', '&&top_06.', '&&top_07.', '&&top_08.', '&&top_09.', '&&top_10.') THEN 0 ELSE gibs END) AS others
       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_01.' THEN gbs ELSE 0 END) AS top_01,
       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_02.' THEN gbs ELSE 0 END) AS top_02,
       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_03.' THEN gbs ELSE 0 END) AS top_03,
       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_04.' THEN gbs ELSE 0 END) AS top_04,
       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_05.' THEN gbs ELSE 0 END) AS top_05,
       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_06.' THEN gbs ELSE 0 END) AS top_06,
       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_07.' THEN gbs ELSE 0 END) AS top_07,
       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_08.' THEN gbs ELSE 0 END) AS top_08,
       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_09.' THEN gbs ELSE 0 END) AS top_09,
       SUM(CASE table_name||'('||table_owner||')' WHEN '&&top_10.' THEN gbs ELSE 0 END) AS top_10,
       SUM(CASE WHEN table_name||'('||table_owner||')' IN ('&&top_01.', '&&top_02.', '&&top_03.', '&&top_04.', '&&top_05.', '&&top_06.', '&&top_07.', '&&top_08.', '&&top_09.', '&&top_10.') THEN 0 ELSE gbs END) AS others
  FROM table_plus_ts
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
