-- IOD_REPEATING_AMW_RESET
-- Resets Auto Maintenance Windows and Tasks 
-- set p_report_only to N for update
DEF report_only = 'N';
WHENEVER SQLERROR EXIT SUCCESS;
PRO Error "ORA-01476: divisor is equal to zero" just means v$database.open_mode is not "READ WRITE"
SELECT CASE open_mode WHEN 'READ WRITE' THEN open_mode ELSE TO_CHAR(1/0) END open_mode FROM v$database;
WHENEVER SQLERROR EXIT FAILURE;
SET ECHO OFF VER OFF FEED OFF HEA OFF PAGES 0 TAB OFF LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_amw_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, 'dd"T"hh24') output_file_name FROM DUAL;
SPO &&output_file_name..txt;
EXEC c##iod.iod_amw.reset(p_report_only => '&&report_only.');
SPO OFF;
HOS zip -mj &&zip_file_name..zip &&output_file_name..txt
HOS unzip -l &&zip_file_name..zip
