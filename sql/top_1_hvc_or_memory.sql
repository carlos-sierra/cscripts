-- top_1_hvc_or_memory.sql
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL sql_text FOR A100;

SELECT /* top#1 sql as per hvc or memory */
       DISTINCT sql_id, pdbs, cursors, sharable_mem_mb, sql_text
 FROM (
SELECT sql_id,
       COUNT(DISTINCT con_id) pdbs,
       COUNT(*) cursors,
       ROUND(SUM(sharable_mem)/POWER(2,20)) sharable_mem_mb,
       ROW_NUMBER () OVER (ORDER BY COUNT(*) DESC) row_number_hvc,
       ROW_NUMBER () OVER (ORDER BY SUM(sharable_mem) DESC) row_number_mem,
       sql_text
  FROM v$sql
 --WHERE object_status = 'VALID'
   --AND is_obsolete = 'N'
 GROUP BY
       sql_id,
       sql_text
) 
WHERE row_number_hvc = 1
   OR row_number_mem = 1
ORDER BY
      sql_id
/
