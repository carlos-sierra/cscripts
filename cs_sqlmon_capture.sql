----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlmon_capture.sql
--
-- Purpose:     Generate SQL Monitor Reports for given SQL_ID for a short period of time
--
-- Author:      Carlos Sierra
--
-- Version:     2021/07/21
--
-- Usage:       Execute connected to PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlmon_capture.sql
--
-- Notes:       *** Requires Oracle Tuning Pack License ***
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
DEF cbo_hints = 'GATHER_PLAN_STATISTICS MONITOR';
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sqlmon_capture';
--
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
UNDEF 1;
--
PRO
PRO 2. Additional CBO_HINTS (opt) e.g.: FIRST_ROWS(1) OPT_PARAM('_fix_control' '5922070:OFF') 
PRO
PRO Other less common CBO Hints: OPT_PARAM('_fix_control' '21971099:OFF') OPT_PARAM('_fix_control' '13321547:OFF') CARDINALITY(T 1) BIND_AWARE
PRO
DEF cs_additional_cbo_hints = "&2.";
UNDEF 2;
--
PRO
PRO 3. REPORT_TYPE: [{ACTIVE}|TEXT|HTML]
DEF report_type = '&3.';
UNDEF 3;
--
COL report_type NEW_V report_type NOPRI;
COL cs_report_type NEW_V cs_report_type NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&report_type.')) IN ('TEXT', 'HTML', 'ACTIVE') THEN UPPER(TRIM('&&report_type.')) ELSE 'ACTIVE' END AS report_type, CASE WHEN NVL(UPPER(TRIM('&&report_type.')), 'ACTIVE') IN ('HTML', 'ACTIVE') THEN 'html' ELSE 'txt' END AS cs_report_type FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_signature.sql
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_additional_cbo_hints." "&&report_type."
@@cs_internal/cs_spool_id.sql
--
PRO SQL_ID       : &&cs_sql_id.
PRO SQLHV        : &&cs_sqlid.
PRO SIGNATURE    : &&cs_signature.
PRO SQL_HANDLE   : &&cs_sql_handle.
PRO APPLICATION  : &&cs_application_category.
PRO CBO_HINTS    : &&cbo_hints. &&cs_additional_cbo_hints.
PRO REPORT_TYPE  : "&&report_type." [{ACTIVE}|TEXT|HTML]
--
SET HEA OFF;
PRINT :cs_sql_text
SET HEA ON;
--
PRO
PRO Drop SQL Patch(es) for: "&&cs_sql_id."
BEGIN
  FOR i IN (SELECT name FROM dba_sql_patches WHERE signature = &&cs_signature.)
  LOOP
    DBMS_SQLDIAG.drop_sql_patch(name => i.name); 
  END LOOP;
END;
/
-- gets some hash on hints to allow multiple patches
COL hash NEW_V hash NOPRI;
SELECT TO_CHAR(ORA_HASH(q'[&&cbo_hints. &&cs_additional_cbo_hints.]',9999)) hash FROM DUAL;
-- capture start time
COL capture_start_time NEW_V capture_start_time NOPRI;
SELECT TO_CHAR(SYSDATE, '&&cs_datetime_full_format.') AS capture_start_time FROM DUAL;
-- create patch
PRO
PRO Create name: "spch_&&cs_sql_id._&&hash.."
DECLARE
  l_sql_text CLOB := :cs_sql_text;
  l_name VARCHAR2(64);
BEGIN
  $IF DBMS_DB_VERSION.ver_le_12_1
  $THEN
    DBMS_SQLDIAG_INTERNAL.i_create_patch(sql_id => '&&cs_sql_id.', hint_text => q'[&&cbo_hints. &&cs_additional_cbo_hints.]', name => 'spch_&&cs_sql_id._&&hash.', description => q'[cs_sqlmon_capture.sql /*+ &&cbo_hints. &&cs_additional_cbo_hints. */ &&cs_reference_sanitized.]'); -- 12c
  $ELSE
    l_name := DBMS_SQLDIAG.create_sql_patch(sql_id => '&&cs_sql_id.',  hint_text => q'[&&cbo_hints. &&cs_additional_cbo_hints.]', name => 'spch_&&cs_sql_id._&&hash.', description => q'[cs_sqlmon_capture.sql /*+ &&cbo_hints. &&cs_additional_cbo_hints. */ &&cs_reference_sanitized.]'); -- 19c
  $END
  NULL;
END;
/
--
PRO
PAUSE Capturing SQL Monitor reports for &&cs_sql_id.. Press RETURN to stop capturing them. Current Time: &&capture_start_time..
PRO
--
PRO
PRO Drop SQL Patch(es) for: "&&cs_sql_id."
BEGIN
  FOR i IN (SELECT name FROM dba_sql_patches WHERE signature = &&cs_signature.)
  LOOP
    DBMS_SQLDIAG.drop_sql_patch(name => i.name); 
  END LOOP;
END;
/
--
--
COL seconds FOR 999,999,990;
COL secs_avg FOR 999,990;
COL secs_max FOR 999,999,990;
COL sql_text FOR A100 HEA 'SQL_TEXT' TRUNC;
COL reports FOR 999,990;
COL pdb_name FOR A30 TRUNC;
COL sql_exec_id NEW_V sql_exec_id FOR A12;
--
WITH 
reports AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       r.sql_exec_start,
       MAX(r.last_refresh_time) last_refresh_time,
       TO_CHAR(r.sql_exec_id) sql_exec_id,
       SUM(r.elapsed_time)/1e6 seconds,
       c.name pdb_name,
       ROW_NUMBER() OVER (ORDER BY r.sql_exec_start) row_number_by_date,
       ROW_NUMBER() OVER (ORDER BY SUM(r.elapsed_time)) row_number_by_seconds
  FROM v$sql_monitor r,
       v$containers c
 WHERE r.sql_id = '&&cs_sql_id.'
   AND c.con_id = r.con_id
   AND c.open_mode = 'READ WRITE'
   AND r.sql_exec_start >= TO_DATE('&&capture_start_time.', '&&cs_datetime_full_format.')
 GROUP BY
       c.name,
       r.sql_exec_id,
       r.sql_exec_start
)
SELECT r1.sql_exec_start,
       r1.last_refresh_time,
       r1.seconds,
       r1.sql_exec_id,
       r1.pdb_name,
       '|' "+",
       r2.seconds,
       r2.sql_exec_start,
       r2.last_refresh_time,
       r2.sql_exec_id,
       r2.pdb_name
  FROM reports r1, reports r2
 WHERE r1.row_number_by_date = r2.row_number_by_seconds
 ORDER BY
       r1.row_number_by_date
/
PRO
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
   AND r.sql_exec_start >= TO_DATE('&&capture_start_time.', '&&cs_datetime_full_format.')
 ORDER BY
       r.sql_exec_start
/
SPO OFF;
@&&cs_file_name._driver.sql
SET PAGES 100;
--
SPO &&cs_file_name..txt APP
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&cs_additional_cbo_hints." "&&report_type."
--
HOS chmod 644 &&cs_file_name._driver.sql
HOS chmod 644 &&cs_file_name..zip
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--