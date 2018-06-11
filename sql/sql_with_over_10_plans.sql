SELECT sql_id, SUBSTR(sql_text, 1, 40),
       COUNT(DISTINCT plan_hash_value)
  FROM v$sql
 GROUP BY
       sql_id,
       sql_text
 HAVING COUNT(DISTINCT plan_hash_value) > 10
/
