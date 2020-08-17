----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_transactions_gc_chart.sql
--
-- Purpose:     GC for given Bucket (rows deleted over time)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/14
--
-- Usage:       Execute connected to PDB.
--
--              Enter Table when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_transactions_gc_chart.sql
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
DEF cs_script_name = 'cs_kiev_transactions_gc_chart';
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
--
--ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'Rows deleted on KievTransactions between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
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
DEF report_foot_note = 'SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&owner."';
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'ROWS DELETED'      
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
my_query AS (
SELECT CAST(eventtime AS DATE) time,
       TO_NUMBER(DBMS_LOB.substr(message, DBMS_LOB.instr(message, ' rows were deleted') - 1)) num_rows
  FROM &&owner..kievGCevents_part
 WHERE bucketname IS NULL
   AND DBMS_LOB.instr(message, ' rows were deleted') > 0
   AND eventtime >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND eventtime < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND gctype = 'TRANSACTION' -- versus BUCKET or TRANSACTION_KEY
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||q.num_rows|| 
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
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--