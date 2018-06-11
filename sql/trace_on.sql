-- turns sql trace on using event 10046 level 12 (include binds and waits)
--ALTER SESSION SET tracefile_identifier = 'iod_amw_02';
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 12';