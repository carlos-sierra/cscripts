COL full_scan FOR A10;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF count ON REPORT;
WITH
all_sql AS (
SELECT DISTINCT con_id, sql_id,
       CASE WHEN options IN ('FULL', 'FULL SCAN', 'FAST FULL SCAN') THEN 'Y' ELSE 'N' END full_scan
  FROM v$sql_plan
),
unique_sql AS (
SELECT con_id, sql_id,
       MAX(full_scan) full_scan -- if a SQL does at least one full scan then it gets a Y, else an N
  FROM all_sql
 GROUP BY
       con_id, sql_id
),
application_sql AS (
SELECT DISTINCT con_id, sql_id
  FROM v$sql s
 WHERE con_id > 2 -- exclude CDB$ROOT and PDB$SEED
   AND parsing_user_id > 0 -- exclude SYS
   AND parsing_schema_id > 0 -- exclude SYS
   AND parsing_schema_name NOT LIKE 'C##'||CHR(37)
   AND plan_hash_value > 0
   AND executions > 0
   AND elapsed_time > 0
   AND sql_text NOT LIKE '/* SQL Analyze'||CHR(37)
   AND EXISTS (SELECT NULL FROM cdb_users u WHERE u.con_id = s.con_id AND u.user_id = s.parsing_user_id AND u.oracle_maintained = 'N')
   AND EXISTS (SELECT NULL FROM cdb_users u WHERE u.con_id = s.con_id AND u.user_id = s.parsing_schema_id AND u.oracle_maintained = 'N')
)
SELECT u.full_scan,
       COUNT(*) count,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) percent
  FROM unique_sql u, application_sql s
 WHERE s.con_id = u.con_id
   AND s.sql_id = u.sql_id
 GROUP BY
       u.full_scan
/
