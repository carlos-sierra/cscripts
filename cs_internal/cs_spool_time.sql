DEF cs_total_time = '';
DEF cs_elapsed_time = '';
COL cs_total_time NEW_V cs_total_time NOPRI;
COL cs_elapsed_time NEW_V cs_elapsed_time NOPRI;
SET HEA OFF PAGES 0;
SELECT 'Total:'||TRIM(TO_CHAR(((DBMS_UTILITY.get_time - :cs_begin_total_time) / 100), '99,990.00'))||'s' AS cs_total_time, 
       'Elapsed:'||TRIM(TO_CHAR(((DBMS_UTILITY.get_time - :cs_begin_elapsed_time) / 100), '99,990.00'))||'s' AS cs_elapsed_time
  FROM DUAL
/
SET HEA ON PAGES 100;