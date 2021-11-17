
-- percent_of_kiev_sql_doing_full_scans.sql - Percentage of KIEV SQL doing Full Scans per Application Category
COL full_scan FOR A10;
COL appl FOR A4;
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
SELECT DISTINCT con_id, c##iod.iod_spm.application_category(sql_text) AS appl, sql_id
  FROM v$sql s
 WHERE con_id > 2 -- exclude CDB$ROOT and PDB$SEED
   AND parsing_user_id > 0 -- exclude SYS
   AND parsing_schema_id > 0 -- exclude SYS
   AND parsing_schema_name NOT LIKE 'C##'||CHR(37)
   AND plan_hash_value > 0
   AND executions > 0
   AND elapsed_time > 0
   AND sql_text NOT LIKE '/* SQL Analyze'||CHR(37)
   AND c##iod.iod_spm.application_category(sql_text) IN ('RO', 'TP', 'BG')
   --AND EXISTS (SELECT NULL FROM cdb_users u WHERE u.con_id = s.con_id AND u.user_id = s.parsing_user_id AND u.oracle_maintained = 'N')
   --AND EXISTS (SELECT NULL FROM cdb_users u WHERE u.con_id = s.con_id AND u.user_id = s.parsing_schema_id AND u.oracle_maintained = 'N')
)
SELECT s.appl, u.full_scan,
       COUNT(*) count,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY s.appl), 1) percent
  FROM unique_sql u, application_sql s
 WHERE s.con_id = u.con_id
   AND s.sql_id = u.sql_id
 GROUP BY
       s.appl, u.full_scan
 ORDER BY
       s.appl, u.full_scan
/
