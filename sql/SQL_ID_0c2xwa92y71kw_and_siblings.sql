WHENEVER SQLERROR EXIT SUCCESS;
PRO
PRO Error "ORA-01476: divisor is equal to zero" just means v$database.open_mode is not "READ WRITE"
SELECT CASE open_mode WHEN 'READ WRITE' THEN open_mode ELSE TO_CHAR(1/0) END open_mode FROM v$database;
SET LIN 350 PAGES 100 TAB OFF HEA ON VER OFF FEED OFF ECHO OFF TRIMS ON;
COL region FOR A15;
COL loc FOR A3;
COL created FOR A20;
COL kiev_api_and_schema FOR A100; 
COL et_ms_per_exec FOR 999,999,990.000;
COL cpu_ms_per_exec FOR 999,999,990.000;
BRE ON region ON loc ON db_name ON pdb_name SKIP PAGE ON sql_id SKIP 1 ON kiev_api_and_schema;
SPO SQL_ID_0c2xwa92y71kw.txt
WITH 
sql_at_risk AS (
SELECT i.host_name,
       d.name db_name,
       p.name pdb_name,
       s.sql_id,
       s.sql_text,
       s.plan_hash_value,
       SUM(s.executions) executions,
       COUNT(*) cursors,
       ROUND(SUM(s.elapsed_time)/SUM(s.executions)/1e3, 3) et_ms_per_exec,
       ROUND(SUM(s.cpu_time)/SUM(s.executions)/1e3, 3) cpu_ms_per_exec,
       s.sql_plan_baseline,
       s.parsing_schema_name,
       b.created,
       ROW_NUMBER () OVER (PARTITION BY i.host_name, d.name, p.name, s.sql_id ORDER BY SUM(s.elapsed_time)/SUM(s.executions) ASC NULLS LAST) rank
  FROM v$sql s,
       v$pdbs p,
       v$database d,
       v$instance i,
       cdb_sql_plan_baselines b
 WHERE (    s.sql_id = '0c2xwa92y71kw' 
         OR s.plan_hash_value IN (1917891576,99953997,3650324870,3559532534,3019880278,1117133894)
         OR s.sql_text LIKE '/* performScanQuery(leases,HashRangeIndex'||CHR(37)
       )
   AND s.sql_text NOT LIKE '/* SQL Analyze'||CHR(37)
   AND s.elapsed_time > 0
   AND s.executions > 0
   AND p.con_id = s.con_id
   AND b.signature(+) = s.exact_matching_signature
   AND b.plan_name(+) = s.sql_plan_baseline
   AND b.con_id(+) = s.con_id
 GROUP BY
       i.host_name,
       d.name,
       p.name,
       s.sql_id,
       s.sql_text,
       s.plan_hash_value,
       s.sql_plan_baseline,
       s.parsing_schema_name,
       b.created
),
enhanced_list AS (
SELECT SUBSTR(host_name, INSTR(host_name, '.', -1) +1) region,
       CASE
         WHEN UPPER(db_name) LIKE CHR(37)||'R'||CHR(37) OR UPPER(db_name) IN ('KIEV1', 'KIEV01') THEN 'RGN'
         ELSE UPPER(SUBSTR(host_name, INSTR(host_name, '.', -1, 2) +1, INSTR(host_name, '.', -1) - INSTR(host_name, '.', -1, 2) -1))
       END loc,
       db_name,
       pdb_name,
       sql_id,
       rank,
       plan_hash_value,
       CASE 
         WHEN plan_hash_value IN (3650324870, 99953997, 3100459980, 1917891576, 3218358398, 3559532534, 28764554, 1973483947, 1160025957) THEN 'OK' 
         WHEN plan_hash_value IN (3019880278, 2159378220, 2801547148) THEN 'BAD' 
       END flg,
       executions,
       cursors,
       et_ms_per_exec,
       cpu_ms_per_exec,
       sql_plan_baseline,
       TO_CHAR(created, 'YYYY-MM-DD"T"HH24:MI:SS') created,
       SUBSTR(sql_text, 1, INSTR(sql_text, '*/') + 1)||' '||parsing_schema_name kiev_api_and_schema
  FROM sql_at_risk
)
SELECT *
  FROM enhanced_list
 ORDER BY
       1, 2, 3, 4, 5, 6, 7
/
SPO OFF;