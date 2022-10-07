----------------------------------------------------------------------------------------
--
-- File name:   cs_table_segments_chart.sql 
--
-- Purpose:     Table-related Segment Size GBs (Table, Indexes and Lobs) for given Table (time series chart)
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
--              SQL> @cs_table_segments_chart.sql
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
DEF cs_script_name = 'cs_table_segments_chart';
--
@@cs_internal/&&cs_set_container_to_cdb_root.
ALTER SESSION SET "_px_cdb_view_enabled" = FALSE;
--
COL owner NEW_V owner FOR A30 HEA 'TABLE_OWNER';
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ DISTINCT h.owner
  FROM &&cs_tools_schema..dbc_segments h,
       cdb_users u
 WHERE h.pdb_name = '&&cs_con_name.'
   AND h.owner NOT LIKE 'C##'||CHR(37) 
   AND h.segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION')
   AND h.segment_name NOT LIKE 'BIN$%'
   AND h.segment_name NOT LIKE 'MLOG$%'
   AND h.segment_name NOT LIKE 'REDEF$%'
   AND u.con_id = &&cs_con_id.
   AND u.username = h.owner
   AND u.oracle_maintained = 'N' 
 ORDER BY 1
/
COL table_owner NEW_V table_owner FOR A30;
PRO
PRO 1. Table Owner:
DEF table_owner = '&1.';
UNDEF 1;
SELECT UPPER(NVL('&&table_owner.', '&&owner.')) table_owner FROM DUAL
/
--
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ DISTINCT h.segment_name table_name
  FROM &&cs_tools_schema..dbc_segments h,
       cdb_users u
 WHERE h.owner = '&&table_owner.'
   AND h.pdb_name = '&&cs_con_name.'
   AND h.segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION')
   AND h.segment_name NOT LIKE 'BIN$%'
   AND h.segment_name NOT LIKE 'MLOG$%'
   AND h.segment_name NOT LIKE 'REDEF$%'
   AND u.con_id = &&cs_con_id.
   AND u.username = h.owner
   AND u.oracle_maintained = 'N' 
 ORDER BY 1
/
PRO
PRO 2. Table Name:
DEF table_name = '&2.';
UNDEF 2;
COL table_name NEW_V table_name NOPRI;
SELECT UPPER(TRIM('&&table_name.')) table_name FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&table_owner..&&table_name.' cs_file_name FROM DUAL;
--
DEF report_title = "&&table_owner..&&table_name.";
DEF chart_title = "&&table_owner..&&table_name.";
DEF xaxis_title = "";
--DEF vaxis_title = "Gibibytes (GiB)";
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
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&table_owner." "&&table_name."';
--
@@cs_internal/cs_spool_head_chart.sql
--
--PRO ,'Table GiB'
--PRO ,'Index(es) GiB'
--PRO ,'LOB(s) GiB'
PRO ,{label:'Table Segment(s)', id:'1', type:'number'}
PRO ,{label:'Index(es) Segment(s)', id:'2', type:'number'}
PRO ,{label:'LOB(s) Segment(s)', id:'3', type:'number'}
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
seg_hist AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       segment_name,
       segment_type,
       snap_time,
       SUM(bytes) bytes
  FROM &&cs_tools_schema..dbc_segments
 WHERE owner = '&&table_owner.'
   AND pdb_name = '&&cs_con_name.'
   AND segment_name NOT LIKE 'BIN$%'
   AND segment_name NOT LIKE 'MLOG$%'
   AND segment_name NOT LIKE 'REDEF$%'
 GROUP BY
       segment_name,
       segment_type,
       snap_time
),
table_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       snap_time,
       SUM(bytes) bytes
  FROM seg_hist
 WHERE segment_name = '&&table_name.'
   AND segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION')
 GROUP BY
       snap_time
),
idx AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       DISTINCT
       index_name
  FROM cdb_indexes
 WHERE table_owner = '&&table_owner.'
   AND table_name = '&&table_name.'
   AND con_id = &&cs_con_id.
),
indexes_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_time,
       SUM(h.bytes) bytes
  FROM idx i,
       seg_hist h
 WHERE h.segment_name = i.index_name
   AND h.segment_type IN ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION', 'LOBINDEX')
 GROUP BY
       h.snap_time
),
lobs_h AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       DISTINCT
       segment_name
  FROM &&cs_tools_schema..dbc_lobs
 WHERE owner = '&&table_owner.'
   AND table_name = '&&table_name.'
   AND pdb_name = '&&cs_con_name.'
),
lobs_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_time,
       SUM(h.bytes) bytes
  FROM lobs_h l,
       seg_hist h
 WHERE h.segment_name = l.segment_name
   AND h.segment_type IN ('LOBSEGMENT', 'LOB PARTITION', 'LOB SUBPARTITION')
 GROUP BY
       h.snap_time
),
/****************************************************************************************/
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       t.snap_time,
--       NVL(ROUND(t.bytes/POWER(2,30), 3), 0) table_gibs,
--       NVL(ROUND(i.bytes/POWER(2,30), 3), 0) indexes_gibs,
--       NVL(ROUND(l.bytes/POWER(2,30), 3), 0) lobs_gibs,
       NVL(ROUND(t.bytes/POWER(10,9), 3), 0) table_gbs,
       NVL(ROUND(i.bytes/POWER(10,9), 3), 0) indexes_gbs,
       NVL(ROUND(l.bytes/POWER(10,9), 3), 0) lobs_gbs
  FROM table_ts t,
       indexes_ts i,
       lobs_ts l
 WHERE i.snap_time(+) = t.snap_time
   AND l.snap_time(+) = t.snap_time
)
SELECT ', [new Date('||
       TO_CHAR(q.snap_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.snap_time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.snap_time, 'DD')|| /* day */
       ','||TO_CHAR(q.snap_time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.snap_time, 'MI')|| /* minute */
       ','||TO_CHAR(q.snap_time, 'SS')|| /* second */
       ')'||
--       ','||q.table_gibs|| 
--       ','||q.indexes_gibs|| 
--       ','||q.lobs_gibs|| 
       ','||num_format(q.table_gbs, 3)|| 
       ','||num_format(q.indexes_gbs, 3)|| 
       ','||num_format(q.lobs_gbs, 3)|| 
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
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
