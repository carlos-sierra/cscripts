----------------------------------------------------------------------------------------
--
-- File name:   cs_tx_cnt_awr_chart.sql
--
-- Purpose:     Chart of Distinct Transactions Count from AWR
--
-- Author:      Carlos Sierra
--
-- Version:     2019/02/21
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_tx_cnt_awr_chart.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_tx_cnt_awr_chart';
DEF cs_hours_range_default = '72';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--ALTER SESSION SET container = CDB$ROOT;
--
PRO 3. Granularity: [{MI}|SS|HH|DD]
DEF cs2_granularity = '&3';
COL cs2_granularity NEW_V cs2_granularity NOPRI;
SELECT NVL(UPPER(TRIM('&&cs2_granularity.')), 'MI') cs2_granularity FROM DUAL;
SELECT CASE WHEN '&&cs2_granularity.' IN ('MI', 'SS', 'HH', 'DD') THEN '&&cs2_granularity.' ELSE 'MI' END cs2_granularity FROM DUAL;
--
COL cs2_plus_days NEW_V cs2_plus_days NOPRI;
SELECT CASE '&&cs2_granularity.' WHEN 'MI' THEN '0.000694444444444' WHEN 'SS' THEN '0' WHEN 'HH' THEN '0.041666666666667' WHEN 'DD' THEN '1' ELSE '0.000694444444444' END cs2_plus_days FROM DUAL;
--
COL cs2_denominator NEW_V cs2_denominator NOPRI;
SELECT CASE '&&cs2_granularity.' WHEN 'MI' THEN '6' WHEN 'SS' THEN '1' WHEN 'HH' THEN '360' WHEN 'DD' THEN '8640' ELSE '6' END cs2_denominator FROM DUAL;
--
SELECT machine, 10*COUNT(*) db_time_secs
  FROM dba_hist_active_sess_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
 GROUP BY
       machine
 ORDER BY
       machine
/
PRO
PRO 4. Machine (opt): 
DEF cs2_machine = '&4';
--
PRO
PRO 5. SQL_ID (opt): 
DEF cs_sql_id = '&5.';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = 'Distinct Transactions Count AWR between &&cs_sample_time_from. and &&cs_sample_time_to. UTC';
DEF chart_title = '&&report_title.';
DEF xaxis_title = 'granularity:"&&cs2_granularity." machine:"&&cs2_machine." SQL_ID:"&&cs_sql_id."';
DEF vaxis_title = 'Distinct Transactions Count';
--
-- (isStacked is true and baseline is null) or (not isStacked and baseline >= 0)
--DEF is_stacked = "isStacked: false,";
DEF is_stacked = "isStacked: true,";
--DEF vaxis_baseline = ", baseline:&&cs_num_cpu_cores., baselineColor:'red'";
DEF vaxis_baseline = "";
DEF chart_foot_note_2 = "<br>2)";
DEF chart_foot_note_2 = "<br>2) Granularity: &&cs2_granularity. [{MI}|SS|HH|DD]";
DEF chart_foot_note_3 = "<br>";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "&&cs_script_name..sql";
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'Transactions'        
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
my_query AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       CASE '&&cs2_granularity.' WHEN 'SS' THEN CAST(sample_time AS DATE) ELSE TRUNC(CAST(sample_time AS DATE) + &&cs2_plus_days., '&&cs2_granularity.') END time,
       COUNT(DISTINCT xid) distinct_tx_cnt
  FROM dba_hist_active_sess_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND dbid = TO_NUMBER('&&cs_dbid.')
   AND instance_number = TO_NUMBER('&&cs_instance_number.')
   AND snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
   AND machine LIKE '%'||TRIM('&&cs2_machine.')||'%'
   AND ('&&cs_sql_id.' IS NULL OR sql_id = '&&cs_sql_id.')
   AND xid IS NOT NULL
 GROUP BY
       CASE '&&cs2_granularity.' WHEN 'SS' THEN CAST(sample_time AS DATE) ELSE TRUNC(CAST(sample_time AS DATE) + &&cs2_plus_days., '&&cs2_granularity.') END
)
SELECT ', [new Date('||
       TO_CHAR(q.time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(q.time, 'MM')) - 1)|| /* month - 1 */
       ','||TO_CHAR(q.time, 'DD')|| /* day */
       ','||TO_CHAR(q.time, 'HH24')|| /* hour */
       ','||TO_CHAR(q.time, 'MI')|| /* minute */
       ','||TO_CHAR(q.time, 'SS')|| /* second */
       ')'||
       ','||q.distinct_tx_cnt|| 
       ']'
  FROM my_query q
 ORDER BY
       q.time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area|Scatter]
DEF cs_chart_type = 'Area';
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs2_granularity." "&&cs2_machine." "&&cs_sql_id." 
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--