SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL sql_text_100 FOR A100;
WITH 
kt_sql AS (
SELECT DISTINCT p.sql_id
  FROM v$sql_plan p
 WHERE p.object_owner <> 'SYS'
   AND p.operation = 'INDEX'
   AND p.object_name LIKE 'KIEVTRANSACTIONS\_%' ESCAPE '\'
)
SELECT s.sql_id,
       s.plan_hash_value,
       ROUND(SUM(s.elapsed_time)/SUM(s.executions)/1e3,3) ms_per_exec,
       ROUND(SUM(s.buffer_gets)/SUM(s.executions),1) bg_per_exec,
       SUBSTR(s.sql_text, 1, 100) sql_text_100
  FROM v$sql s,
       kt_sql k
 WHERE s.sql_id = k.sql_id
   AND s.sql_text NOT LIKE '%/*+%'
 GROUP BY
       s.sql_id,
       s.plan_hash_value,
       SUBSTR(s.sql_text, 1, 100)
 ORDER BY 
       s.sql_id, 
       s.plan_hash_value
/