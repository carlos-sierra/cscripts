SET HEA OFF FEED OFF ECHO OFF VER OFF FEED OFF;

SPO for_all_pdbs_dynamic.sql

SELECT 'PRO *** '||name||' ***'||CHR(10)||
       'ALTER SESSION SET container = '||name||';'||CHR(10)||
       'EXEC DBMS_STATS.LOCK_TABLE_STATS(''SYS'', ''X$QESRSTATALL'');'||CHR(10)||
       'EXEC DBMS_STATS.LOCK_TABLE_STATS(''SYS'', ''X$KQLFSQCE'');'||CHR(10)
  FROM v$pdbs
 WHERE con_id > 2
   AND open_mode = 'READ WRITE'
 ORDER BY
       con_id
/

SPO OFF;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;

SET HEA ON ECHO ON VER ON FEED ON;
SPO for_all_pdbs_report_&&current_time..txt
@for_all_pdbs_dynamic.sql
SPO OFF;

ALTER SESSION SET container = CDB$ROOT;