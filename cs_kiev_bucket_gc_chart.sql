 ----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_bucket_gc_chart.sql
--
-- Purpose:     GC (rows deleted) for given Bucket (time series chart)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/02/07
--
-- Usage:       Execute connected to PDB.
--
--              Enter Table when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_bucket_gc_chart.sql
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
DEF cs_script_name = 'cs_kiev_bucket_gc_chart';
DEF cs_hours_range_default = '168';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL username NEW_V username FOR A30 HEA 'OWNER';
SELECT u.username
  FROM dba_users u
 WHERE u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
   AND (SELECT COUNT(*) FROM dba_tables t WHERE t.owner = u.username AND t.table_name = 'KIEVBUCKETS') > 0
 ORDER BY u.username
/
PRO
COL owner NEW_V owner FOR A30;
PRO 3. Enter Owner
DEF owner = '&3.';
UNDEF 3;
SELECT UPPER(NVL('&&owner.', '&&username.')) owner FROM DUAL
/
COL cs2_tabl_name NEW_V cs2_tabl_name NOPRI;
SELECT table_name AS cs2_tabl_name FROM dba_tables WHERE owner = '&&owner.' AND table_name LIKE 'KIEVGCEVENTS_PART%' ORDER BY last_analyzed DESC NULLS LAST FETCH FIRST 1 ROW ONLY
/ 
--
COL table_name FOR A30;
COL num_rows FOR 999,999,999,990;
COL kievlive_y FOR 999,999,999,990;
COL kievlive_n FOR 999,999,999,990;
--
WITH
sqf1 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       table_name,
       SUBSTR(UTL_RAW.CAST_TO_VARCHAR2(SUBSTR(LPAD(TO_CHAR(endpoint_value,'fmxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'),30,'0'),1,12)), 1, 1) kievlive,
       endpoint_number - LAG(endpoint_number, 1, 0) OVER (PARTITION BY table_name ORDER BY endpoint_value) num_rows
  FROM dba_tab_histograms
 WHERE owner = '&&owner.'
   AND column_name = 'KIEVLIVE'
),
sqf2 AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       table_name,
       kievlive,
       MAX(num_rows) num_rows
  FROM sqf1
 WHERE kievlive IN ('Y', 'N')
 GROUP BY
       table_name,
       kievlive
)
SELECT b.name table_name,
       b.maxgarbageage,
       t.num_rows,
       CASE WHEN NVL(y.num_rows, 0) + NVL(n.num_rows, 0) > 0 THEN ROUND(y.num_rows * t.num_rows / (NVL(y.num_rows, 0) + NVL(n.num_rows, 0))) END kievlive_y,
       CASE WHEN NVL(y.num_rows, 0) + NVL(n.num_rows, 0) > 0 THEN ROUND(n.num_rows * t.num_rows / (NVL(y.num_rows, 0) + NVL(n.num_rows, 0))) END kievlive_n
  FROM &&owner..kievbuckets b,
       dba_tables t,
       sqf2 y,
       sqf2 n
 WHERE t.owner = '&&owner.'
   AND t.table_name = UPPER(b.name)
   AND y.table_name(+) = t.table_name
   AND y.kievlive(+) = 'Y'
   AND n.table_name(+) = t.table_name
   AND n.kievlive(+) = 'N'
 ORDER BY
       b.name
/
PRO
PRO 4. Enter Table Name
DEF table_name = '&4.';
--
--@@cs_internal/&&cs_set_container_to_cdb_root.
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'Rows deleted from &&table_name. between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF xaxis_title = '';
DEF vaxis_title = 'Rows Deleted';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
DEF is_stacked = "isStacked: false,";
--DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = '<br>2)';
--DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&owner." "&&table_name."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,{label:'ROWS DELETED from &&table_name.', id:'1', type:'number'}      
-- PRO ,{label:'ROWS DELETED from KievTransactionKeys', id:'2', type:'number'}      
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
events_part AS (
SELECT CAST(eventtime AS DATE) time,
       gctype,
       TO_NUMBER(DBMS_LOB.substr(message, DBMS_LOB.instr(message, ' rows were deleted') - 1)) num_rows
  FROM &&owner..&&cs2_tabl_name.
 WHERE UPPER(bucketname) = UPPER(TRIM('&&table_name.'))
   AND DBMS_LOB.instr(message, ' rows were deleted') > 0
   AND eventtime >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND eventtime < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND gctype IN ('BUCKET', 'TRANSACTION_KEY')
),
my_query AS (
SELECT time,
       SUM(CASE gctype WHEN 'BUCKET' THEN num_rows ELSE 0 END) bucket,
       SUM(CASE gctype WHEN 'TRANSACTION_KEY' THEN num_rows ELSE 0 END) transaction_key
  FROM events_part
 GROUP BY
       time
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||num_format(q.bucket)|| 
      --  ','||num_format(q.transaction_key)|| 
       ']'
  FROM my_query q
 ORDER BY
       q.time
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
--@@cs_internal/&&cs_set_container_to_curr_pdb.
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--