SELECT s.elapsed_time / POWER(10, 6) AS seconds,
       s.executions,
       s.elapsed_time / POWER(10, 3) / s.executions AS ms_per_exec,
       s.sql_id,
       s.plan_hash_value,
       s.sql_fulltext AS sql_text
  FROM v$sqlstats s
 WHERE s.executions > 0
   AND s.elapsed_time > 0
 ORDER BY
       s.elapsed_time DESC
FETCH FIRST 1000 ROWS ONLY
/

SELECT SUM(s.elapsed_time) / POWER(10, 6) AS seconds,
       SUM(s.executions) AS executions,
       SUM(s.elapsed_time) / POWER(10, 3) / SUM(s.executions) AS ms_per_exec,
       SUBSTR(s.sql_text, 1, 100) AS sql_text
  FROM v$sqlstats s
 WHERE s.executions > 0
   AND s.elapsed_time > 0
   AND s.sql_text NOT LIKE '%/*+%'
 GROUP BY
       SUBSTR(s.sql_text, 1, 100)
HAVING COUNT(*) > 100
 ORDER BY
       1 DESC
FETCH FIRST 10 ROWS ONLY
/
