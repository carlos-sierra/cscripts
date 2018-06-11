SET HEA OFF FEED OFF ECHO OFF VER OFF;

SPO dynamic_disable_ora-13831_spbs.sql

SELECT 'PRO *** '||name||' ***'||CHR(10)||
       'ALTER SESSION SET container = '||name||';'||CHR(10)||
       '@spm/disable_ora-13831_spbs.sql'
  FROM v$pdbs
 WHERE con_id > 2
   AND open_mode = 'READ WRITE'
 ORDER BY
       con_id
/

SPO OFF;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;

SPO /tmp/disable_ora-13831_spbs_report_&&current_time..txt
@dynamic_disable_ora-13831_spbs
SPO OFF;

ALTER SESSION SET container = CDB$ROOT;