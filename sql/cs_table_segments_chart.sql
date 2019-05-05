----------------------------------------------------------------------------------------
--
-- File name:   cs_table_segments_chart.sql
--
-- Purpose:     Chart of Table, Index(es) and Lob(s) Segments for given Table
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
ALTER SESSION SET container = CDB$ROOT;
--
COL owner NEW_V owner FOR A30 HEA 'TABLE_OWNER';
SELECT DISTINCT h.owner
  FROM c##iod.segments_hist h,
       cdb_users u
 WHERE h.pdb_name = UPPER(TRIM('&&cs_con_name.'))
   AND u.con_id = h.con_id
   AND u.username = h.owner
   AND u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
 ORDER BY 1
/
COL table_owner NEW_V table_owner FOR A30;
PRO
PRO 1. Table Owner:
DEF table_owner = '&1.';
SELECT UPPER(NVL('&&table_owner.', '&&owner.')) table_owner FROM DUAL
/
--
SELECT DISTINCT h.segment_name table_name
  FROM c##iod.segments_hist h,
       cdb_users u
 WHERE h.pdb_name = UPPER(TRIM('&&cs_con_name.'))
   AND h.owner = UPPER(TRIM('&&table_owner.'))
   AND h.segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION')
   AND u.con_id = h.con_id
   AND u.username = h.owner
   AND u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
 ORDER BY 1
/
PRO
PRO 2. Table Name:
DEF table_name = '&2.';
COL table_name NEW_V table_name NOPRI;
SELECT UPPER(TRIM('&&table_name.')) table_name FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&table_owner..&&table_name.' cs_file_name FROM DUAL;
--
DEF report_title = "&&table_owner..&&table_name.";
DEF chart_title = "&&table_owner..&&table_name.";
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
PRO ,'Table MBs'
PRO ,'Index(es) MBs'
PRO ,'LOB(s) MBs'
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
seg_hist AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       owner,
       segment_name,
       segment_type,
       snap_time,
       SUM(bytes) bytes
  FROM c##iod.segments_hist
 WHERE owner = '&&table_owner.'
   AND pdb_name = '&&cs_con_name.'
   AND con_id = &&cs_con_id.
 GROUP BY
       owner,
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
indexes_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_time,
       SUM(h.bytes) bytes
  FROM cdb_indexes i,
       seg_hist h
 WHERE i.table_owner = '&&table_owner.'
   AND i.table_name = '&&table_name.'
   AND i.con_id = &&cs_con_id.
   AND h.owner = i.owner
   AND h.segment_name = i.index_name
   AND h.segment_type IN ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION', 'LOBINDEX')
 GROUP BY
       h.snap_time
),
lobs_h AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       DISTINCT
       owner,
       segment_name
  FROM c##iod.lobs_hist
 WHERE owner = '&&table_owner.'
   AND table_name = '&&table_name.'
   AND pdb_name = '&&cs_con_name.'
   AND con_id = &&cs_con_id.
),
lobs_ts AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.snap_time,
       SUM(h.bytes) bytes
  FROM lobs_h l,
       seg_hist h
 WHERE h.owner = l.owner
   AND h.segment_name = l.segment_name
   AND h.segment_type = 'LOBSEGMENT'
 GROUP BY
       h.snap_time
),
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       t.snap_time,
       NVL(ROUND(t.bytes/POWER(2,20),3),0) table_mbs,
       NVL(ROUND(i.bytes/POWER(2,20),3),0) indexes_mbs,
       NVL(ROUND(l.bytes/POWER(2,20),3),0) lobs_mbs
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
       ','||q.table_mbs|| 
       ','||q.indexes_mbs|| 
       ','||q.lobs_mbs|| 
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
PRO SQL> @&&cs_script_name..sql "&&table_owner." "&&table_name."
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
