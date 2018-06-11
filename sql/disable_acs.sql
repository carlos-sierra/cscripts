SET HEA OFF FEED OFF ECHO OFF VER OFF FEED OFF;

ALTER SESSION SET container = CDB$ROOT;

SPO disable_acs_dynamic.sql

SELECT 'PRO *** '||name||' ***'||CHR(10)||
       'ALTER SESSION SET container = '||name||';'||CHR(10)||
       'ALTER SYSTEM SET "_optimizer_adaptive_cursor_sharing" = FALSE;'||CHR(10)||
       'ALTER SYSTEM SET "_optimizer_extended_cursor_sharing" = "NONE";'||CHR(10)||
       'ALTER SYSTEM SET "_optimizer_extended_cursor_sharing_rel" = "NONE";'||CHR(10)
  FROM v$containers
 WHERE open_mode = 'READ WRITE'
 ORDER BY
       con_id
/

SPO OFF;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;

SET HEA ON ECHO ON VER ON FEED ON;
SPO disable_acs_&&current_time..txt
@disable_acs_dynamic.sql
SPO OFF;

ALTER SESSION SET container = CDB$ROOT;

