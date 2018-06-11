-- IOD_SPACE_SEGMENT_HIST (IOD_REPEATING_SPACE_SEGMENT_HIST)
-- Segments History - Collector
--
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
--
-- exit graciously if package does not exist
WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  DBMS_OUTPUT.PUT_LINE('API version: '||c##iod.iod_space.gk_package_version);
END;
/
WHENEVER SQLERROR EXIT FAILURE;
--
ALTER SESSION SET tracefile_identifier = 'iod_space_segment';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 8';
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET HEA OFF;
--
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_space_segments_hist_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, 'dd"T"hh24') output_file_name FROM DUAL;
--
SET TIMI ON;
SET SERVEROUT ON SIZE UNLIMITED;
SPO &&output_file_name..txt;
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
PRO &&output_file_name..txt;
--
EXEC c##iod.iod_space.segments_hist;
--
PRO &&output_file_name..txt;
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
SPO OFF;
HOS zip -mj &&zip_file_name..zip &&output_file_name..txt
HOS unzip -l &&zip_file_name..zip
WHENEVER SQLERROR CONTINUE;
--
ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
ALTER SESSION SET SQL_TRACE = FALSE;
