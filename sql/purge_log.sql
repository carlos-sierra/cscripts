SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

ALTER SESSION SET container = CDB$ROOT;

SPO purge_log_dynamic.sql

SELECT 'PRO *** '||name||'('||con_id||') ***'||CHR(10)||
       'ALTER SESSION SET container = '||name||';'||CHR(10)||
       'EXEC DBMS_SCHEDULER.PURGE_LOG(14);'||CHR(10)||
       'EXEC DBMS_STATS.GATHER_TABLE_STATS(''SYS'',''SCHEDULER$_EVENT_LOG'');'||CHR(10)||
       'EXEC DBMS_STATS.GATHER_TABLE_STATS(''SYS'',''SCHEDULER$_WINDOW'');'||CHR(10)
  FROM v$containers
 WHERE open_mode = 'READ WRITE'
 ORDER BY
       con_id
/

SPO OFF;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;

SET HEA ON ECHO ON VER ON FEED ON;
SPO purge_log_&&current_time..txt
@purge_log_dynamic.sql
SPO OFF;

ALTER SESSION SET container = CDB$ROOT;

