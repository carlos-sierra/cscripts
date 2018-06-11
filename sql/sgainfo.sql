COL gbs FOR 9,990.000
SELECT ROUND(bytes / POWER(2,30), 3) gbs,
       name
  FROM v$sgainfo
 ORDER BY
       1 DESC
/
