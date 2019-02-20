----------------------------------------------------------------------------------------
--
-- File name:   OEM IOD_REPEATING_SPACE_TABLE_HIST
--
-- Purpose:     CDB Tables, Table Modifications and Tablespaces History
--
-- Frequency:   Hourly
--
-- Author:      Carlos Sierra
--
-- Version:     2019/02/04
--
-- Usage:       Execute connected into CDB 
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @IOD_REPEATING_SPACE_TABLE_HIST.sql
--
-- Notes:       For CDB_TABLES and CDB_TAB_MODIFICATIONS it MERGES new rows.
--
---------------------------------------------------------------------------------------
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
--
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET tracefile_identifier = 'iod_tables';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 8';
--
SET ECHO OFF VER OFF FEED OFF HEA OFF PAGES 0 TAB OFF LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_tables_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, '"d"d"_h"hh24') output_file_name FROM DUAL;
COL trace_file NEW_V trace_file;
--
SPO &&output_file_name..txt;
SELECT value trace_file FROM v$diag_info WHERE name = 'Default Trace File';
PRO &&output_file_name..txt;
--
EXEC c##iod.iod_space.tablespaces_hist;
EXEC c##iod.iod_space.table_stats_hist;
DECLARE
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows  INTEGER;
  l_identifier_must_be_declared EXCEPTION;
  PRAGMA EXCEPTION_INIT(l_identifier_must_be_declared, -06550);
BEGIN
  l_statement := 'BEGIN DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO; END;';
  l_cursor_id := DBMS_SQL.OPEN_CURSOR;
  FOR i IN (SELECT name FROM v$containers WHERE open_mode = 'READ WRITE')
  LOOP
    BEGIN
      DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => i.name);
      l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    EXCEPTION
      WHEN l_identifier_must_be_declared THEN
        DBMS_OUTPUT.PUT_LINE(i.name||' '||SQLERRM);
    END;
  END LOOP;
  DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
END;
/
EXEC c##iod.iod_space.tab_modifications_hist;
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
