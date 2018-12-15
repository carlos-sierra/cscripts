-- IOD_REPEATING_SPM_FPZ_CDB (every 3 hours) KIEV
-- SQL Plan Management - Flipping Plan Zapper
-- set p_report_only to N for update
DEF report_only = 'N';
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
ALTER SESSION SET tracefile_identifier = 'iod_spm';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 8';
SET ECHO OFF VER OFF FEED OFF HEA OFF PAGES 0 TAB OFF LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_spm_fpz_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, 'dd"T"hh24') output_file_name FROM DUAL;
SPO &&output_file_name..txt;
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
PRO Execute cs_spbl_zap_hist_list.sql and cs_spbl_zap_hist_report.sql for SQL_ID details
PRO &&output_file_name..txt;
EXEC c##iod.iod_spm.fpz(p_report_only => '&&report_only.');
PRO &&output_file_name..txt;
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
PRO Execute cs_spbl_zap_hist_list.sql and cs_spbl_zap_hist_report.sql for SQL_ID details
SPO OFF;
HOS zip -mj &&zip_file_name..zip &&output_file_name..txt
HOS unzip -l &&zip_file_name..zip
WHENEVER SQLERROR CONTINUE;
ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
ALTER SESSION SET SQL_TRACE = FALSE;
