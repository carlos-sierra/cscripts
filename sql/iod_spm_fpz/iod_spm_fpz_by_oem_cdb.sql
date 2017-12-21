WHENEVER SQLERROR EXIT SUCCESS;
PRO Error "ORA-01476: divisor is equal to zero" just means v$database.open_mode is not "READ WRITE"
SELECT CASE open_mode WHEN 'READ WRITE' THEN open_mode ELSE TO_CHAR(1/0) END open_mode FROM v$database;
SET ECHO OFF VER OFF FEED OFF HEA OFF PAGES 0 TAB OFF LINES 145 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
COL report_file NEW_V report_file;
COL zip_file NEW_V zip_file;
SELECT '/tmp/iod_spm_fpz_'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') zip_file FROM DUAL;
SELECT '/tmp/iod_spm_fpz_'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') report_file FROM DUAL;
SPO &&report_file..txt;
EXEC c##iod.iod_spm.fpz(p_report_only => 'Y');
SPO OFF;
HOS zip -mj &&zip_file..zip &&report_file..txt
HOS unzip -l &&zip_file..zip
