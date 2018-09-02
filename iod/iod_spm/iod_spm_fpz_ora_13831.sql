ALTER SESSION SET CONTAINER = CDB$ROOT;
SET ECHO OFF VER OFF FEED OFF HEA OFF PAGES 0 TAB OFF LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
COL report_file NEW_V report_file;
SELECT '/tmp/iod_spm_fpz_ora_13831_'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') report_file FROM DUAL;
SPO &&report_file..txt;
EXEC c##iod.iod_spm.workaround_ora_13831(p_report_only => 'N');
SPO OFF;
HOS zip -mj &&report_file..zip &&report_file..txt
HOS unzip -l &&report_file..zip