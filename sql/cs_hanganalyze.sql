ALTER SESSION SET tracefile_identifier = 'iod_hanganalyze';
COL trace_file NEW_V trace_file;
SELECT value trace_file FROM v$diag_info WHERE name = 'Default Trace File';
oradebug setmypid
oradebug unlimit
oradebug hanganalyze 3
oradebug hanganalyze 3
oradebug hanganalyze 3
oradebug hanganalyze 3
oradebug hanganalyze 3
oradebug hanganalyze 3
oradebug tracefile_name 
HOS cp &&trace_file. /tmp
