----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlmon_mem.sql
--
-- Purpose:     SQL Monitor report for a given SQL (MEM)
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
COL pdb_name FOR A30 TRUNC;
--
WITH
individual_executions AS (
SELECT r.sql_id,
       r.sql_exec_id,
       r.sql_exec_start,
       MAX(r.last_refresh_time) last_refresh_time,
       MAX(r.sql_text) sql_text,
       MAX(r.status) status,
       MAX(r.elapsed_time)/1e6 seconds
  FROM v$sql_monitor r
 WHERE r.sql_id IS NOT NULL
 GROUP BY
       r.sql_id,
       r.sql_exec_id,
       r.sql_exec_start
)
SELECT SUM(seconds) seconds,
       COUNT(*) reports,
       MAX(seconds) secs_max,
       SUM(seconds)/COUNT(*) secs_avg,
       MIN(sql_exec_start) min_sql_exec_start,
       MAX(last_refresh_time) max_last_refresh_time,
       sql_id,
       REPLACE(MAX(sql_text), CHR(10), CHR(32)) sql_text
  FROM individual_executions
 GROUP BY
       sql_id
 ORDER BY
       1 DESC, 2 DESC
/
--
PRO
PRO 1. SQL_ID: 
DEF cs_sql_id = '&1.';
--
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
--
PRO
PRO 2. SQL_EXEC_ID: {&&sql_exec_id.}
DEF cs_sql_exec_id = '&2.';
SELECT TRIM(NVL('&&cs_sql_exec_id.', '&&sql_exec_id.')) sql_exec_id FROM DUAL;
--
COL sql_exec_start NEW_V sql_exec_start FOR A19;
SELECT TO_CHAR(MAX(sql_exec_start), '&&cs_datetime_full_format.') sql_exec_start 
  FROM gv$sql_monitor
 WHERE sql_id = '&&cs_sql_id.'
   AND sql_exec_id = &&sql_exec_id.
/
PRO
PRO 3. REPORT_TYPE: [{ACTIVE}|TEXT|HTML]
DEF report_type = '&3.';
--
COL cs_report_type NEW_V cs_report_type;
SELECT CASE WHEN NVL(UPPER(TRIM('&&report_type.')), 'ACTIVE') IN ('HTML', 'ACTIVE') THEN 'html' ELSE 'txt' END cs_report_type FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&cs_sql_id._&&sql_exec_id._&&report_type.' cs_file_name FROM DUAL;
--
SET PAGES 0;
SPO &&cs_file_name..&&cs_report_type.;
SELECT DBMS_SQLTUNE.report_sql_monitor(sql_id => '&&cs_sql_id.', sql_exec_start => TO_DATE('&&sql_exec_start.', '&&cs_datetime_full_format.'), sql_exec_id => TO_NUMBER('&&sql_exec_id.'), type => NVL(TRIM('&&report_type.'), 'ACTIVE')) FROM DUAL;
SPO OFF;
HOS chmod 644 &&cs_file_name..&&cs_report_type.
SET PAGES 100;
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sql_id." "&&sql_exec_id." "&&report_type."
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