SPO driver_dynamic2.sql
SET SERVEROUT ON
BEGIN
  FOR i IN 1..1000
  LOOP
   DBMS_OUTPUT.PUT_LINE('DEF b1 = '''||i||'''; '||CHR(10)||'@driven2.sql');
  END LOOP;
END;
/
SPO OFF
SET SERVEROUT OFF

ALTER SESSION SET tracefile_identifier = 'IOD_PARSE_TEST';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 12';

@driver_dynamic2.sql

ALTER SESSION SET SQL_TRACE = FALSE;
COL trace NEW_V trace;
SELECT value trace FROM v$diag_info WHERE name = 'Default Trace File';
HOS cp &&trace. .
HOS tkprof &&trace. tkprof_parse_test.txt
HOS more tkprof.txt


