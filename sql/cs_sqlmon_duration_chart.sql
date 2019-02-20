----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlmon_duration_chart.sql
--
-- Purpose:     Charts duration of SQL for which there exist a SQL Monitor report
--
-- Author:      Carlos Sierra
--
-- Version:     2019/01/27
--
-- Usage:       Execute connected to PDB.
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
--COL pdb_name NEW_V pdb_name FOR A30;
--SELECT SYS_CONTEXT('USERENV', 'CON_NAME') pdb_name FROM DUAL;
--ALTER SESSION SET container = CDB$ROOT;
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
--
SELECT '&&cs_file_prefix._&&cs_sql_id._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
DEF report_title = "Monitored Executions of &&cs_sql_id.";
DEF chart_title = "&&cs_sql_id. duration";
DEF xaxis_title = "End Time";
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
DEF report_foot_note = "&&cs_script_name..sql";
--
@@cs_internal/cs_spool_head_chart.sql
--
PRO ,'Elapsed Time'
PRO ,'Avg Last 3'
PRO ,'Avg Last 10'
PRO ]
--
SET HEA OFF PAGES 0;
/****************************************************************************************/
WITH
sqlmonitor AS (
SELECT TO_DATE(key3, 'MM/DD/YYYY HH24:MI:SS') sql_exec_start, 
       period_start_time start_time,
       period_end_time end_time,
       (period_end_time - period_start_time) * 24 * 3600 seconds,
       session_id,
       session_serial#,
       report_id
  FROM dba_hist_reports
 WHERE component_name = 'sqlmonitor'
   AND key1 = '&&cs_sql_id.'
),
my_query AS (
SELECT --sql_exec_start, 
       --start_time,
       end_time,
       ROUND(seconds) seconds,
       ROUND(AVG(seconds) OVER (ORDER BY end_time ROWS BETWEEN 3 PRECEDING AND CURRENT ROW)) avg3,
       ROUND(AVG(seconds) OVER (ORDER BY end_time ROWS BETWEEN 10 PRECEDING AND CURRENT ROW)) avg10
       --session_id,
       --session_serial#,
       --report_id
  FROM sqlmonitor
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
       ','||q.avg3|| 
       ','||q.avg10|| 
       ']'
  FROM my_query q
 ORDER BY
       q.end_time
/
/****************************************************************************************/
SET HEA ON PAGES 100;
--
-- [Line|Area]
DEF cs_chart_type = 'Line';
@@cs_internal/cs_spool_id_chart.sql
@@cs_internal/cs_spool_tail_chart.sql
PRO scp &&cs_host_name.:&&cs_file_prefix._*_&&cs_reference_sanitized._*.* &&cs_local_dir.
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." 
--
--ALTER SESSION SET CONTAINER = &&pdb_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
