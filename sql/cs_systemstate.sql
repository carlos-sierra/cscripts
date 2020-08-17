ALTER SESSION SET tracefile_identifier = 'iod_systemstate';
COL trace_file NEW_V trace_file;
SELECT value trace_file FROM v$diag_info WHERE name = 'Default Trace File';
oradebug setmypid
oradebug unlimit
oradebug dump systemstate 266 
oradebug tracefile_name 
HOS cp &&trace_file. /tmp
