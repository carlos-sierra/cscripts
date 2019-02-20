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
individual_executions AS (
SELECT /*+ NO_MERGE */
       r.con_id,
       r.sql_id,
       r.sql_exec_id,
       r.sql_exec_start,
       MAX(r.last_refresh_time) last_refresh_time,
       MAX(r.sql_text) sql_text,
       MAX(r.status) status,
       SUM(r.elapsed_time)/1e6 seconds
  FROM v$sql_monitor r
 WHERE r.sql_id = '&&cs_sql_id.'
 GROUP BY
       r.con_id,
       r.sql_id,
       r.sql_exec_id,
       r.sql_exec_start
)
SELECT r.sql_exec_start,
       r.last_refresh_time,
       r.seconds,
       TO_CHAR(r.sql_exec_id) sql_exec_id,
       c.name pdb_name
  FROM individual_executions r,
       v$containers c
 WHERE c.con_id = r.con_id
   AND c.open_mode = 'READ WRITE'
 ORDER BY
       1, 2
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
SELECT '&&cs_file_prefix._&&cs_sql_id._&&cs_file_date_time._&&sql_exec_id._&&report_type._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
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
PRO scp &&cs_host_name.:&&cs_file_prefix._*_&&cs_reference_sanitized._*.* &&cs_local_dir.
--