----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlmon_hist.sql
--
-- Purpose:     SQL Monitor Report for a given SQL_ID (from AWR)
--
-- Author:      Carlos Sierra
--
-- Version:     2023/04/27
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
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sqlmon_hist';
--
DEF cs_hours_range_default = '168';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
COL key1 FOR A13 HEA 'SQL_ID';
COL seconds FOR 999,999,990;
COL secs_avg FOR 999,990;
COL secs_max FOR 999,999,990;
COL sql_text FOR A100 HEA 'SQL_TEXT' TRUNC;
COL reports FOR 999,990;
COL done FOR 999,990;
COL done_all_rows FOR 999,990 HEA 'DONE|ALL ROWS';
COL done_first_n_rows FOR 999,990 HEA 'DONE FIRST|N ROWS';
COL done_error FOR 999,990 HEA 'DONE|ERROR';
COL executing FOR 999,990;
COL queued FOR 999,990;
COL pdbs FOR 9,990;
COL pdb_name FOR A30 TRUNC;
--
WITH
sqlmonitor_raw AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       r.period_end_time,
       r.period_start_time,
       --Xmltype(r.report_summary).extract('//status/text()').getStringVal() AS status, -- too slow
       --REGEXP_REPLACE(REGEXP_SUBSTR(r.report_summary, '<status>[^\<]*'), '<status>') AS status, -- <status>DONE (ALL ROWS)</status>
       REGEXP_SUBSTR(r.report_summary, '[^\<]*', REGEXP_INSTR(r.report_summary, '<status>', 1, 1, 1)) AS status, -- <status>DONE (ALL ROWS)</status>
       r.con_id,
       r.key1,
       c.name AS pdb_name
  FROM cdb_hist_reports r, v$containers c
 WHERE (r.period_end_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') OR r.period_start_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.'))
   AND r.component_name = 'sqlmonitor'
   AND r.key1 IS NOT NULL
   AND LENGTH(r.key1) = 13
   AND r.dbid = TO_NUMBER('&&cs_dbid.')
   AND r.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND c.con_id = r.con_id
   AND ROWNUM >= 1 /*+ MATERIALIZE NO_MERGE */
)
, sqlmonitor_grouped AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       SUM(r.period_end_time - r.period_start_time) * 24 * 3600 AS seconds,
       COUNT(*) AS reports,
       SUM(CASE r.status WHEN 'DONE' THEN 1 ELSE 0 END) AS done,
       SUM(CASE r.status WHEN 'DONE (ALL ROWS)' THEN 1 ELSE 0 END) AS done_all_rows,
       SUM(CASE r.status WHEN 'DONE (FIRST N ROWS)' THEN 1 ELSE 0 END) AS done_first_n_rows,
       SUM(CASE r.status WHEN 'DONE (ERROR)' THEN 1 ELSE 0 END) AS done_error,
       SUM(CASE r.status WHEN 'EXECUTING' THEN 1 ELSE 0 END) AS executing,
       SUM(CASE r.status WHEN 'QUEUED' THEN 1 ELSE 0 END) AS queued,
       COUNT(DISTINCT r.con_id) AS pdbs,
       MAX(r.period_end_time - r.period_start_time) * 24 * 3600 AS secs_max,
       ROUND(SUM(r.period_end_time - r.period_start_time) * 24 * 3600 / COUNT(*)) AS secs_avg,
       MIN(r.period_start_time) AS min_start_time,
       MAX(r.period_end_time) AS max_end_time,
       r.key1,
       r.pdb_name
  FROM sqlmonitor_raw r
 WHERE ROWNUM >= 1 /*+ MATERIALIZE NO_MERGE */
 GROUP BY
       r.key1,
       r.pdb_name
HAVING SUM(r.period_end_time - r.period_start_time) * 24 * 3600 > 1
)
, sqlmonitor_extended AS (
SELECT r.seconds,
       r.reports,
       r.done,
       r.done_all_rows,
       r.done_first_n_rows,
       r.done_error,
       r.executing,
       r.queued,
       r.pdbs,
       r.secs_max,
       r.secs_avg,
       r.min_start_time,
       r.max_end_time,
       r.key1,
       r.pdb_name,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = r.key1 AND ROWNUM = 1) sql_text
  FROM sqlmonitor_grouped r
)
SELECT r.seconds,
       r.reports,
       r.done,
       r.done_all_rows,
       r.done_first_n_rows,
       r.done_error,
       r.executing,
       r.queued,
       r.pdbs,
       r.secs_max,
       r.secs_avg,
       r.min_start_time,
       r.max_end_time,
       r.key1,
       r.sql_text,
       r.pdb_name
  FROM sqlmonitor_extended r
 WHERE 1 = 1
   AND NVL(r.sql_text, 'NULL') NOT LIKE 'BEGIN%'
   AND NVL(r.sql_text, 'NULL') NOT LIKE '/* SQL Analyze(1) */%'
 ORDER BY
       r.seconds DESC, 
       r.reports DESC
 FETCH FIRST 1000 ROWS ONLY
/
--
PRO
PRO 3. SQL_ID: 
DEF cs_sql_id = '&3.';
UNDEF 3;
--
PRO
PRO 4. Top: [{100}|1-10000]
DEF sqlmon_top = '&4.';
UNDEF 4;
COL cs_sqlmon_top NEW_V cs_sqlmon_top NOPRI;
SELECT CASE WHEN TO_NUMBER('&&sqlmon_top.') BETWEEN 1 AND 10000 THEN '&&sqlmon_top.' ELSE '100' END AS cs_sqlmon_top FROM DUAL
/
--
@@cs_internal/cs_sqlmon_hist_internal.sql
COL report_id_a NEW_V report_id_a NOPRI;
SELECT TRIM(TO_CHAR('&&report_id.')) AS report_id_a FROM DUAL
/
--
PRO
PRO 5. REPORT_ID from: {&&report_id_a.}
DEF cs_report_id = '&5.';
UNDEF 5;
COL report_id_from NEW_V report_id_from NOPRI;
SELECT TRIM(COALESCE('&&cs_report_id.', '&&report_id_a.')) AS report_id_from FROM DUAL
/
--
PRO
PRO 6. REPORT_ID to: {&&report_id_from.}
DEF cs_report_id = '&6.';
UNDEF 6;
COL report_id_to NEW_V report_id_to NOPRI;
SELECT TRIM(COALESCE('&&cs_report_id.', '&&report_id_from.')) AS report_id_to FROM DUAL;
--
PRO
PRO 7. REPORT_TYPE: [{TEXT}|ACTIVE|HTML]
DEF report_type = '&7.';
UNDEF 7;
COL report_type NEW_V report_type NOPRI;
COL cs_report_type NEW_V cs_report_type NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&report_type.')) IN ('TEXT', 'HTML', 'ACTIVE') THEN UPPER(TRIM('&&report_type.')) ELSE 'TEXT' END AS report_type, CASE WHEN NVL(UPPER(TRIM('&&report_type.')), 'TEXT') IN ('HTML', 'ACTIVE') THEN 'html' ELSE 'txt' END AS cs_report_type FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&cs_sqlmon_top." "&&report_id_from." "&&report_id_to." "&&report_type."
@@cs_internal/cs_spool_id.sql
@@cs_internal/cs_spool_id_sample_time.sql
@@cs_internal/cs_spool_id_list_sql_id.sql
--
PRO REPORT_ID    : FROM &&report_id_from. TO &&report_id_to.
PRO REPORT_TYPE  : "&&report_type." [{TEXT}|ACTIVE|HTML]
--
@@cs_internal/cs_print_sql_text.sql
@@cs_internal/cs_sqlmon_hist_internal.sql
--
SET PAGES 0;
SPO &&cs_file_name._driver.sql
SELECT 'SPO &&cs_file_name._'||TO_CHAR(r.report_id)||'.&&cs_report_type.;'||CHR(10)||
       'SELECT DBMS_AUTO_REPORT.report_repository_detail(rid => '||r.report_id||', type => NVL(TRIM(''&&report_type.''), ''ACTIVE'')) FROM DUAL;'||CHR(10)||
       'SPO OFF;'||CHR(10)||
       'HOS chmod 644 &&cs_file_name._'||TO_CHAR(r.report_id)||'.&&cs_report_type.'||CHR(10)||
       'HOS zip -mj &&cs_file_name..zip &&cs_file_name._'||TO_CHAR(r.report_id)||'.&&cs_report_type.'||CHR(10)
       AS line
  FROM cdb_hist_reports r
 WHERE (r.period_end_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.') OR r.period_start_time BETWEEN TO_DATE('&&cs_sample_time_from.', '&&cs_datetime_full_format.') AND TO_DATE('&&cs_sample_time_to.', '&&cs_datetime_full_format.'))
   AND r.component_name = 'sqlmonitor'
   AND r.key1 = '&&cs_sql_id.'
   AND r.dbid = TO_NUMBER('&&cs_dbid.')
   AND r.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND r.report_id BETWEEN &&report_id_from. AND &&report_id_to.
 ORDER BY
       r.report_id
/
SPO OFF;
@&&cs_file_name._driver.sql
SET PAGES 100;
--
SPO &&cs_file_name..txt APP
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." "&&cs_sql_id." "&&cs_sqlmon_top." "&&report_id_from." "&&report_id_to." "&&report_type."
--
HOS chmod 644 &&cs_file_name._driver.sql
HOS chmod 644 &&cs_file_name..zip
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--