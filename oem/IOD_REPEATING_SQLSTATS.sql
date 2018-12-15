-- IOD_REPEATING_SQLSTATS (every 5 mins) KIEV
-- Collects SQL with potential performance regression
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR EXIT FAILURE;
--SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
--ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
--ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 8';
--SET HEA ON LIN 32767 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 327670 LONGC 32767 SERVEROUT OFF;
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_sqlstats_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, 'hh24mi') output_file_name FROM DUAL;
SPO &&output_file_name..txt;
--ALTER SESSION SET tracefile_identifier = 'iod_sqlstats';
PRO &&output_file_name..txt;
PRO
PRO Takes snapshot
PRO ~~~~~~~~~~~~~~
PRO
EXEC c##iod.iod_sqlstats.snapshot;
PRO
PRO Done!
PRO ~~~~~
SPO OFF;
HOS zip -mj &&zip_file_name..zip &&output_file_name..txt
HOS unzip -l &&zip_file_name..zip
--WHENEVER SQLERROR CONTINUE;
--ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
--ALTER SESSION SET SQL_TRACE = FALSE;
