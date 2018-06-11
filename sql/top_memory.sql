SET PAGES 100 LIN 300;
COL sql_text FOR A100;
BREAK ON REPORT;
COMPUTE SUM lABEL 'TOTAL' OF sharable_mem_mb cursors ON REPORT;
SELECT * FROM (
SELECT ROUND(SUM(sharable_mem)/POWER(2,20)) sharable_mem_mb,
       --con_id,
       sql_id,
       COUNT(*) cursors,
       sql_text
  FROM v$sql
 GROUP BY
       --con_id,
       sql_id,
       sql_text
HAVING SUM(sharable_mem)/POWER(2,20) > 10 -- MBs
 ORDER BY 1 DESC
) 
WHERE ROWNUM < 11 -- top 10
/
CLEAR BREAK COMPUTE;
