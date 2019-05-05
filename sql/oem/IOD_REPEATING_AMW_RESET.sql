----------------------------------------------------------------------------------------
--
-- File name:   OEM IOD_REPEATING_AMW_RESET
--
-- Purpose:     Set Auto Maintenance Windows and Tasks
--
-- Frequency:   Daily at 4PM UTC
--
-- Author:      Carlos Sierra
--
-- Version:     2019/04/19
--
-- Usage:       Execute connected into CDB 
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @IOD_REPEATING_AMW_RESET.sql
--
-- Notes:       Sets Auto Maintenance Windows [{4}|1|0|2|3|6] per day
--              Disables Auto functions for: accept SQL Profiles from Tuning Advisor,
--              Auto Evolve SQL Plan Baselines, SQ Tuning Advisor and Segment Advisor.
--              Enables CBO Statistics Gathering.
--
---------------------------------------------------------------------------------------
--
DEF report_only = 'N';
-- to use these parameters below, uncomment also the call to c##iod.iod_amw.reset_amw that references them
-- windows: [{4}|1|0|2|3|6]
DEF windows = '4';
DEF pdb_name = '';
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Not PRIMARY');
  END IF;
END;
/
-- exit not graciously if any error
WHENEVER SQLERROR EXIT FAILURE;
-- remove traces older than 1 day
DEF diag_trace = 'non-existent-directory-prefix-in-case-select-below-returns-null';
COL diag_trace NEW_V diag_trace;
SELECT value diag_trace FROM v$diag_info WHERE name = 'Diag Trace';
HOS find &&diag_trace./ -type f -name '*iod_amw*.tr*' -mtime +1 -exec rm {} \;;
HOS find /tmp/iod* -type f -name 'iod_amw_*.txt' -mtime +1 -exec rm {} \;;
--
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET tracefile_identifier = 'iod_amw';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 8';
--
SET ECHO OFF VER OFF FEED OFF HEA OFF PAGES 0 TAB OFF LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_amw_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, '"d"d"_h"hh24') output_file_name FROM DUAL;
COL trace_file NEW_V trace_file;
--
SPO &&output_file_name..txt;
SELECT value trace_file FROM v$diag_info WHERE name = 'Default Trace File';
PRO &&output_file_name..txt;
--
--EXEC c##iod.iod_amw.reset_amw(p_report_only => '&&report_only.', p_pdb_name => '&&pdb_name.', p_windows => TO_NUMBER('&&windows.'));
EXEC c##iod.iod_amw.reset_amw(p_report_only => '&&report_only.');
--
PRO &&output_file_name..txt;
SELECT value trace_file FROM v$diag_info WHERE name = 'Default Trace File';
SPO OFF;
--
--HOS tkprof &&trace_file. &&output_file_name._tkprof_nosort.txt
HOS tkprof &&trace_file. &&output_file_name._tkprof_sort.txt sort=exeela,fchela
HOS zip -mj &&zip_file_name..zip &&output_file_name.*.txt
HOS unzip -l &&zip_file_name..zip
--
ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
ALTER SESSION SET SQL_TRACE = FALSE;
--
---------------------------------------------------------------------------------------