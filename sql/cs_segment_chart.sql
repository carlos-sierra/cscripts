----------------------------------------------------------------------------------------
--
-- File name:   cs_segment_chart.sql
--
-- Purpose:     Chart of Segment for given Table
--
-- Author:      Carlos Sierra
--
-- Version:     2018/10/29
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
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_segment_chart';
--
COL pdb_name NEW_V pdb_name FOR A30;
ALTER SESSION SET container = CDB$ROOT;
--
SELECT DISTINCT owner table_owner
  FROM c##iod.segments_hist
 WHERE pdb_name = '&&cs_con_name.'
 ORDER BY 1
/
PRO
PRO 1. Table Owner:
DEF table_owner = '&1.';
--
SELECT DISTINCT segment_name table_name
  FROM c##iod.segments_hist
 WHERE pdb_name = '&&cs_con_name.'
   AND owner = UPPER(TRIM('&&table_owner.'))
   AND segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION')
 ORDER BY 1
/
PRO
PRO 2. Table Name:
DEF table_name = '&2.';
--
COL segment_name FOR A30;
COL segment_type FOR A30;
--
SELECT DISTINCT segment_name, segment_type
  FROM c##iod.segments_hist
 WHERE pdb_name = '&&cs_con_name.'
   AND owner = UPPER(TRIM('&&table_owner.'))
   AND segment_name = UPPER(TRIM('&&table_name.'))
   AND segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION')
 UNION
SELECT DISTINCT h.segment_name, h.segment_type
  FROM cdb_indexes i,
       c##iod.segments_hist h
 WHERE i.table_owner = UPPER(TRIM('&&table_owner.'))
   AND i.table_name = UPPER(TRIM('&&table_name.'))
   AND h.con_id = i.con_id 
   AND h.pdb_name = '&&cs_con_name.'
   AND h.owner = i.owner
   AND h.segment_name = i.index_name
   AND h.segment_type IN ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION', 'LOBINDEX')
 UNION
SELECT DISTINCT h.segment_name, h.segment_type
  FROM cdb_lobs l,
       c##iod.segments_hist h
 WHERE l.owner = UPPER(TRIM('&&table_owner.'))
   AND l.table_name = UPPER(TRIM('&&table_name.'))
   AND h.con_id = l.con_id 
   AND h.pdb_name = '&&cs_con_name.'
   AND h.owner = l.owner
   AND h.segment_name = l.segment_name
   AND h.segment_type = 'LOBSEGMENT'
 ORDER BY
       2, 1
/
PRO
PRO 3. Segment Name:
DEF segment_name = '&3.';
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&table_owner..&&table_name._&&segment_name.' cs_file_name FROM DUAL;
--
DEF report_title = "&&table_owner..&&table_name. &&segment_name.";
DEF chart_title = "&&table_owner..&&table_name. &&segment_name.";
DEF xaxis_title = "";
DEF vaxis_title = "";
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
DEF report_foot_note = "&&cs_script_name..sql";
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'Segment MBs'
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
table_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       snap_time,
       SUM(bytes) bytes
  FROM c##iod.segments_hist
 WHERE pdb_name = '&&cs_con_name.'
   AND owner = UPPER(TRIM('&&table_owner.'))
   AND segment_name = UPPER(TRIM('&&table_name.'))
   AND segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION')
 GROUP BY
       snap_time
),
indexes_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_time,
       SUM(h.bytes) bytes
  FROM cdb_indexes i,
       c##iod.segments_hist h
 WHERE i.table_owner = UPPER(TRIM('&&table_owner.'))
   AND i.table_name = UPPER(TRIM('&&table_name.'))
   AND h.con_id = i.con_id 
   AND h.pdb_name = '&&cs_con_name.'
   AND h.owner = i.owner
   AND h.segment_name = UPPER(TRIM('&&segment_name.'))
   AND h.segment_name = i.index_name
   AND h.segment_type IN ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION', 'LOBINDEX')
 GROUP BY
       h.snap_time
),
lobs_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_time,
       SUM(h.bytes) bytes
  FROM cdb_lobs l,
       c##iod.segments_hist h
 WHERE l.owner = UPPER(TRIM('&&table_owner.'))
   AND l.table_name = UPPER(TRIM('&&table_name.'))
   AND h.con_id = l.con_id 
   AND h.pdb_name = '&&cs_con_name.'
   AND h.owner = l.owner
   AND h.segment_name = UPPER(TRIM('&&segment_name.'))
   AND h.segment_name = l.segment_name
   AND h.segment_type = 'LOBSEGMENT'
 GROUP BY
       h.snap_time
),
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       t.snap_time,
       CASE 
         WHEN UPPER(TRIM('&&table_name.')) = UPPER(TRIM('&&segment_name.')) THEN NVL(ROUND(t.bytes/POWER(2,20),3),0)
         ELSE NVL(ROUND(i.bytes/POWER(2,20),3),0) + NVL(ROUND(l.bytes/POWER(2,20),3),0)
       END mbs
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
       ','||q.mbs|| 
       ']'
  FROM my_query q
 ORDER BY
       q.snap_time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|Scatter]
DEF cs_chart_type = 'Area';
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
PRO SQL> @&&cs_script_name..sql "&&table_owner." "&&table_name." "&&segment_name."
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql

