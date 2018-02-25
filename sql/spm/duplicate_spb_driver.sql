SET HEA OFF FEED OFF ECHO OFF VER OFF;

SPO dynamy_duplicate_spb.sql

SELECT 'PRO *** '||name||' ***'||CHR(10)||
       'ALTER SESSION SET container = '||name||';'||CHR(10)||
       '@spm/duplicate_spb.sql'
  FROM v$pdbs
 WHERE con_id > 2
   AND open_mode = 'READ WRITE'
 ORDER BY
       con_id
/

SPO OFF;
SPO duplicate_spb_cdb.txt
@dynamy_duplicate_spb.sql
SPO OFF;

ALTER SESSION SET container = CDB$ROOT;