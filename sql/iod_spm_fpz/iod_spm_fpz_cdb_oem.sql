-- IOD_REPEATING_SPM_FPZ_CDB
DEF report_only = 'Y';
WHENEVER SQLERROR EXIT SUCCESS;
PRO Error "ORA-01476: divisor is equal to zero" just means v$database.open_mode is not "READ WRITE"
SELECT CASE open_mode WHEN 'READ WRITE' THEN open_mode ELSE TO_CHAR(1/0) END open_mode FROM v$database;
WHENEVER SQLERROR EXIT FAILURE;
SET ECHO OFF VER OFF FEED OFF HEA OFF PAGES 0 TAB OFF LINES 145 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_spm_fpz_cdb_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM v$database, v$instance;
SPO &&output_file_name..txt;
-- change p_report_only to N for update
EXEC c##iod.iod_spm.fpz(p_report_only => '&&report_only.');
SPO OFF;
HOS zip -mj &&output_file_name..zip &&output_file_name..txt
HOS unzip -l &&output_file_name..zip
