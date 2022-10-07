SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL name FOR A15 TRUNC;
COL type FOR A13 TRUNC;
COL text FOR A100 TRUNC;
SELECT /*name, */type, text 
  FROM dba_source 
 WHERE owner = 'C##IOD' 
   AND line <= 3 
   AND type LIKE 'PACKAGE%' 
   AND text LIKE '%Header%'
   AND name = 'IOD_SPM'
   AND text NOT LIKE '%2022-05-05T21:11:58%'
   AND text NOT LIKE '%2022-05-28T21:46:10%'
 ORDER BY
       name, type
/
