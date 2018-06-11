SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL name FOR A30;
COL type FOR A30;
COL text FOR A100;
SELECT name, type, text 
  FROM dba_source 
 WHERE owner = 'C##IOD' 
   AND line <= 3 
   AND type LIKE 'PACKAGE%' 
   AND text LIKE '%Header%'
 ORDER BY
       name, type
/

