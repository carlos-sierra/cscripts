----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlmon_mem.sql
--
-- Purpose:     SQL Monitor Report for a given SQL_ID (from MEM)
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
--              SQL> @cs_sqlmon_mem.sql
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
DEF cs_script_name = 'cs_sqlmon_mem';
--
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
COL pdb_name FOR A30 TRUNC;
--
WITH
individual_executions AS (
SELECT r.sql_id,
       r.sql_exec_id,
       r.sql_exec_start,
       r.status,
       MAX(r.last_refresh_time) AS last_refresh_time,
       MAX(r.sql_text) AS sql_text,
       MAX(r.elapsed_time)/1e6 AS seconds,
       c.name AS pdb_name
  FROM v$sql_monitor r, v$containers c
 WHERE r.sql_id IS NOT NULL
   AND c.con_id = r.con_id
   AND ROWNUM >= 1 /*+ MATERIALIZE NO_MERGE */
 GROUP BY
       r.sql_id,
       r.sql_exec_id,
       r.sql_exec_start,
       r.status,
       c.name
)
SELECT SUM(seconds) seconds,
       COUNT(*) reports,
       SUM(CASE status WHEN 'DONE' THEN 1 ELSE 0 END) AS done,
       SUM(CASE status WHEN 'DONE (ALL ROWS)' THEN 1 ELSE 0 END) AS done_all_rows,
       SUM(CASE status WHEN 'DONE (FIRST N ROWS)' THEN 1 ELSE 0 END) AS done_first_n_rows,
       SUM(CASE status WHEN 'DONE (ERROR)' THEN 1 ELSE 0 END) AS done_error,
       SUM(CASE status WHEN 'EXECUTING' THEN 1 ELSE 0 END) AS executing,
       SUM(CASE status WHEN 'QUEUED' THEN 1 ELSE 0 END) AS queued,
       MAX(seconds) secs_max,
       SUM(seconds)/COUNT(*) secs_avg,
       MIN(sql_exec_start) min_sql_exec_start,
       MAX(last_refresh_time) max_last_refresh_time,
       sql_id,
       REPLACE(MAX(sql_text), CHR(10), CHR(32)) sql_text,
       pdb_name
  FROM individual_executions
 GROUP BY
       sql_id,
       pdb_name
HAVING SUM(seconds) > 1
 ORDER BY
       1 DESC, 
       2 DESC
 FETCH FIRST 1000 ROWS ONLY
/
--
PRO
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
PRO
PRO 2. Top: [{100}|1-10000]
DEF sqlmon_top = '&2.';
UNDEF 2;
COL cs_sqlmon_top NEW_V cs_sqlmon_top NOPRI;
SELECT CASE WHEN TO_NUMBER('&&sqlmon_top.') BETWEEN 1 AND 10000 THEN '&&sqlmon_top.' ELSE '100' END AS cs_sqlmon_top FROM DUAL
/
--
@@cs_internal/cs_sqlmon_mem_internal.sql
COL sql_exec_id_a NEW_V sql_exec_id_a NOPRI;
SELECT TRIM(TO_CHAR('&&sql_exec_id.')) AS sql_exec_id_a FROM DUAL
/
--
PRO
PRO 3. SQL_EXEC_ID FROM: {&&sql_exec_id_a.}
DEF cs_sql_exec_id = '&3.';
UNDEF 3;
COL sql_exec_id_from NEW_V sql_exec_id_from NOPRI;
SELECT TRIM(COALESCE('&&cs_sql_exec_id.', '&&sql_exec_id_a.')) AS sql_exec_id_from FROM DUAL;
--
PRO
PRO 4. SQL_EXEC_ID TO: {&&sql_exec_id_from.}
DEF cs_sql_exec_id = '&4.';
UNDEF 4;
COL sql_exec_id_to NEW_V sql_exec_id_to NOPRI;
SELECT TRIM(COALESCE('&&cs_sql_exec_id.', '&&sql_exec_id_from.')) AS sql_exec_id_to FROM DUAL;
--
PRO
PRO 5. REPORT_TYPE: [{TEXT}|ACTIVE|HTML]
DEF report_type = '&5.';
UNDEF 5;
--
COL report_type NEW_V report_type NOPRI;
COL cs_report_type NEW_V cs_report_type NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&report_type.')) IN ('TEXT', 'HTML', 'ACTIVE') THEN UPPER(TRIM('&&report_type.')) ELSE 'TEXT' END AS report_type, CASE WHEN NVL(UPPER(TRIM('&&report_type.')), 'TEXT') IN ('HTML', 'ACTIVE') THEN 'html' ELSE 'txt' END AS cs_report_type FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_sqlmon_top." "&&sql_exec_id_from." "&&sql_exec_id_to." "&&report_type."
@@cs_internal/cs_spool_id.sql
@@cs_internal/cs_spool_id_list_sql_id.sql
--
PRO SQL_EXEC_ID  : FROM &&sql_exec_id_from. TO &&sql_exec_id_to.
PRO REPORT_TYPE  : "&&report_type." [{TEXT}|ACTIVE|HTML]
--
@@cs_internal/cs_print_sql_text.sql
@@cs_internal/cs_sqlmon_mem_internal.sql
--
SET PAGES 0;
SPO &&cs_file_name._driver.sql
SELECT 'SPO &&cs_file_name._'||TO_CHAR(r.sql_exec_id)||'.&&cs_report_type.;'||CHR(10)||
       'SELECT DBMS_SQLTUNE.report_sql_monitor(sql_id => ''&&cs_sql_id.'', sql_exec_start => TO_DATE('''||TO_CHAR(r.sql_exec_start, '&&cs_datetime_full_format.')||''', ''&&cs_datetime_full_format.''), sql_exec_id => '||TO_CHAR(r.sql_exec_id)||', type => NVL(TRIM(''&&report_type.''), ''ACTIVE'')) FROM DUAL;'||CHR(10)||
       'SPO OFF;'||CHR(10)||
       'HOS chmod 644 &&cs_file_name._'||TO_CHAR(r.sql_exec_id)||'.&&cs_report_type.'||CHR(10)||
       'HOS zip -mj &&cs_file_name..zip &&cs_file_name._'||TO_CHAR(r.sql_exec_id)||'.&&cs_report_type.'||CHR(10)
       AS line
  FROM v$sql_monitor r
 WHERE r.sql_id = '&&cs_sql_id.'
   AND r.sql_exec_id BETWEEN &&sql_exec_id_from. AND &&sql_exec_id_to.
 GROUP BY
       r.sql_id,
       r.sql_exec_id,
       r.sql_exec_start
 ORDER BY
       r.sql_id,
       r.sql_exec_id,
       r.sql_exec_start
/
SPO OFF;
@&&cs_file_name._driver.sql
SET PAGES 100;
--
SPO &&cs_file_name..txt APP
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_sqlmon_top." "&&sql_exec_id_from." "&&sql_exec_id_to." "&&report_type."
--
HOS chmod 644 &&cs_file_name._driver.sql
HOS chmod 644 &&cs_file_name..zip
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--