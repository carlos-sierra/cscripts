-- trace_10053_mysid_on.sql - Turn ON CBO EVENT 10053 LEVEL 1 on own Session
ALTER SESSION SET tracefile_identifier = '10053';
--
COL host_name NEW_V host_name;
COL trace_file NEW_V trace_file;
COL filename NEW_V filename;
--
SELECT host_name, value trace_file, SUBSTR(value, INSTR(value, '/', -1) +1) filename FROM v$instance, v$diag_info WHERE name = 'Default Trace File';
--
ALTER SESSION SET EVENTS '10053 TRACE NAME CONTEXT FOREVER, LEVEL 1';