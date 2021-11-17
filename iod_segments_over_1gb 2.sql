COL gbs FOR 9,990;
COL segment_name FOR A30 TRUNC;
--
SELECT ROUND(SUM(bytes)/POWER(2,30)) gbs,
       segment_name
  FROM dba_segments
 WHERE owner = 'C##IOD'
HAVING ROUND(SUM(bytes)/POWER(2,30)) > 0
 GROUP BY
       segment_name
 ORDER BY 
       1 DESC
/
