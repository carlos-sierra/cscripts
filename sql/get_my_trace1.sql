COL full_trace_name NEW_V full_trace_name;
SELECT value full_trace_name
FROM v$diag_info 
WHERE name = 'Default Trace File';

HOS cp &&full_trace_name. .
HOS more &&full_trace_name.
