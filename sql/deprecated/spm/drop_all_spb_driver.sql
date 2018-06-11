SET HEA OFF FEED OFF ECHO OFF VER OFF;

SPO dynamy_drop_all_spb.sql

SELECT 'PRO *** '||name||' ***'||CHR(10)||
       'ALTER SESSION SET container = '||name||';'||CHR(10)||
       '@spm/drop_all_spb.sql'
  FROM v$containers
 WHERE open_mode = 'READ WRITE'
 ORDER BY
       con_id
/

SPO OFF;
SPO drop_all_spb_cdb.txt
@dynamy_drop_all_spb.sql
SPO OFF;

ALTER SESSION SET container = CDB$ROOT;