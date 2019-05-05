----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlmon_hist.sql
--
-- Purpose:     SQL Monitor report for a given SQL (AWR)
--
-- Author:      Carlos Sierra
--
-- Version:     2019/01/27
--
-- Usage:       Execute connected to PDB or CDB.
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
--@@cs_internal/cs_cdb_warn.sql
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
COL sql_text FOR A100 HEA 'SQL_TEXT' TRUNC;
COL reports FOR 999,990;
COL pdbs FOR 9,990;
COL pdb_name FOR A30 TRUNC;
--
WITH 
sqlmonitor AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       SUM(r.period_end_time - r.period_start_time) * 24 * 3600 seconds,
       COUNT(*) reports,
       COUNT(DISTINCT r.con_id) pdbs,
       MAX(r.period_end_time - r.period_start_time) * 24 * 3600 secs_max,
       ROUND(SUM(r.period_end_time - r.period_start_time) * 24 * 3600 / COUNT(*)) secs_avg,
       MIN(r.period_start_time) min_start_time,
       MAX(r.period_end_time) max_end_time,
       r.key1
  FROM cdb_hist_reports r
 WHERE r.component_name = 'sqlmonitor'
   AND r.key1 IS NOT NULL
   AND LENGTH(r.key1) = 13
   AND r.dbid = TO_NUMBER('&&cs_dbid.')
   AND r.instance_number = TO_NUMBER('&&cs_instance_number.')
 GROUP BY
       r.key1
)
, sqlmonitor_extended AS (
SELECT r.seconds,
       r.reports,
       r.pdbs,
       r.secs_max,
       r.secs_avg,
       r.min_start_time,
       r.max_end_time,
       r.key1,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = r.key1 AND ROWNUM = 1) sql_text
  FROM sqlmonitor r
)
SELECT r.seconds,
       r.reports,
       r.pdbs,
       r.secs_max,
       r.secs_avg,
       r.min_start_time,
       r.max_end_time,
       r.key1,
       r.sql_text
  FROM sqlmonitor_extended r
 WHERE r.sql_text IS NOT NULL
   AND r.sql_text NOT LIKE 'BEGIN%'
   AND r.sql_text NOT LIKE '/* SQL Analyze(1) */%'
 ORDER BY
       r.seconds,
       r.reports
/
--
PRO
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
--
COL report_id NEW_V report_id FOR A10;
COL sid_serial FOR A13 HEA '  SID,SERIAL#'; 
--
WITH 
reports AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       --TO_CHAR(TO_DATE(key3, 'MM/DD/YYYY HH24:MI:SS'), '&&cs_datetime_full_format.') sql_exec_start, 
       r.period_start_time start_time,
       r.period_end_time end_time,
       (r.period_end_time - r.period_start_time) * 24 * 3600 seconds,
       LPAD(r.session_id,5)||','||r.session_serial# sid_serial,
       TO_CHAR(r.report_id) report_id,
       c.name pdb_name,
       ROW_NUMBER() OVER (ORDER BY r.period_start_time, r.period_end_time) row_number_by_date,
       ROW_NUMBER() OVER (ORDER BY r.period_end_time - r.period_start_time) row_number_by_seconds
  FROM dba_hist_reports r,
       v$containers c
 WHERE r.component_name = 'sqlmonitor'
   AND r.key1 = '&&cs_sql_id.'
   AND r.dbid = TO_NUMBER('&&cs_dbid.')
   AND r.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND c.con_id = r.con_id
   AND c.open_mode = 'READ WRITE'
)
SELECT r1.start_time,
       r1.end_time,
       r1.seconds,
       r1.sid_serial,
       r1.report_id,
       r1.pdb_name,
       '|' "+",
       r2.seconds,
       r2.start_time,
       r2.end_time,
       r2.sid_serial,
       r2.report_id,
       r2.pdb_name
  FROM reports r1, reports r2
 WHERE r1.row_number_by_date = r2.row_number_by_seconds
 ORDER BY
       r1.row_number_by_date
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
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id._&&report_id._&&report_type.' cs_file_name FROM DUAL;
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
PRO scp &&cs_host_name.:&&cs_file_dir.&&cs_reference_sanitized._*.* &&cs_local_dir.
--
UNDEF 1 2 3 4 5 6 7 8 9 10
SET HEA ON LIN 80 PAGES 14 TAB ON FEED ON ECHO OFF VER ON TRIMS OFF TRIM ON TI OFF TIMI OFF LONG 80 LONGC 80 SERVEROUT OFF;
CLEAR BREAK COLUMNS COMPUTE;
--