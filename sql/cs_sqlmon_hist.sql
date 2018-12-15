----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlmon_hist.sql
--
-- Purpose:     SQL Monitor report for a given SQL (AWR)
--
-- Author:      Carlos Sierra
--
-- Version:     2018/11/25
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlmon_hist.sql
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
DEF cs_script_name = 'cs_sqlmon_hist';
--
COL key1 FOR A13 HEA 'SQL_ID';
COL seconds FOR 999,999,990;
COL secs_avg FOR 999,990;
COL secs_max FOR 999,999,990;
COL sql_text_60 FOR A60 HEA 'SQL_TEXT';
COL reports FOR 999,990;
--
SELECT SUM(period_end_time - period_start_time) * 24 * 3600 seconds,
       COUNT(*) reports,
       MAX(period_end_time - period_start_time) * 24 * 3600 secs_max,
       ROUND(SUM(period_end_time - period_start_time) * 24 * 3600 / COUNT(*)) secs_avg,
       MIN(period_start_time) min_start_time,
       MAX(period_end_time) max_end_time,
       key1,
       (SELECT SUBSTR(sql_text, 1, 60) FROM v$sql WHERE sql_id = key1 AND ROWNUM = 1) sql_text_60
  FROM dba_hist_reports
 WHERE component_name = 'sqlmonitor'
   AND EXISTS (SELECT NULL FROM v$sql WHERE sql_id = key1)
 GROUP BY
       key1
 ORDER BY
       1 DESC, 2 DESC
/
--
PRO
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
--
COL report_id NEW_V report_id FOR A10;
COL sid_serial FOR A13 HEA '  SID,SERIAL#'; 
--
SELECT --TO_CHAR(TO_DATE(key3, 'MM/DD/YYYY HH24:MI:SS'), '&&cs_datetime_full_format.') sql_exec_start, 
       period_start_time start_time,
       period_end_time end_time,
       (period_end_time - period_start_time) * 24 * 3600 seconds,
       LPAD(session_id,5)||','||session_serial# sid_serial,
       TO_CHAR(report_id) report_id
  FROM dba_hist_reports
 WHERE component_name = 'sqlmonitor'
   AND key1 = '&&cs_sql_id.'
 ORDER BY
       1, 2
/
--
PRO
PRO 2. REPORT_ID: {&&report_id.}
DEF cs_report_id = '&2.';
SELECT TRIM(NVL('&&cs_report_id.', '&&report_id.')) report_id FROM DUAL;
--
PRO
PRO 3. REPORT_TYPE: [{ACTIVE}|TEXT|HTML]
DEF report_type = '&3.';
--
COL cs_report_type NEW_V cs_report_type;
SELECT CASE WHEN NVL(UPPER(TRIM('&&report_type.')), 'ACTIVE') IN ('HTML', 'ACTIVE') THEN 'html' ELSE 'txt' END cs_report_type FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_sql_id._&&cs_file_date_time._&&report_id._&&report_type._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
SET PAGES 0;
SPO &&cs_file_name..&&cs_report_type.;
SELECT DBMS_AUTO_REPORT.report_repository_detail(rid => TO_NUMBER('&&report_id.'), type => NVL(TRIM('&&report_type.'), 'ACTIVE')) FROM DUAL;
SPO OFF;
HOS chmod 644 &&cs_file_name..&&cs_report_type.
SET PAGES 100;
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&report_id." "&&report_type."
--
PRO
PRO If you want to preserve script output, execute scp command below, from a TERM session running on your Mac/PC:
PRO scp &&cs_host_name.:&&cs_file_name..&&cs_report_type. &&cs_local_dir.
PRO scp &&cs_host_name.:&&cs_file_prefix._*_&&cs_reference_sanitized._*.* &&cs_local_dir.
--