SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
COL pdb_name FOR A30 TRUNC;
COL sql_text FOR A100 TRUNC;
--
WITH
bad_plans AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT p.con_id, p.sql_id
  FROM v$sql_plan p
 WHERE p.other_xml LIKE '%baseline_repro_fail%'
   AND ROWNUM >= 1
),
queries AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT s.con_id, s.sql_id, s.exact_matching_signature AS signature, s.sql_text
  FROM v$sql s
 WHERE (s.con_id, s.sql_id) IN (SELECT /*+ NO_MERGE */ p.con_id, p.sql_id FROM bad_plans p)
   AND ROWNUM >= 1
),
bad_baselines AS (
SELECT /*+ MATERIALIZE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       DISTINCT b.con_id, b.signature, b.sql_handle, b.plan_name, q.sql_id, q.sql_text
  FROM cdb_sql_plan_baselines b, queries q
 WHERE b.con_id = q.con_id
   AND b.signature = q.signature
   AND b.enabled = 'YES'
   AND b.accepted = 'YES'
   AND ROWNUM >= 1
)
SELECT DISTINCT c.name AS pdb_name, b.sql_id, b.sql_handle, b.signature, b.plan_name, b.sql_text
  FROM bad_baselines b, v$containers c
 WHERE c.con_id = b.con_id
 ORDER BY
       1, 2
/

-- WITH
-- c AS (
-- SELECT  /*+ MATERIALIZE NO_MERGE */
--         c.con_id, c.name AS pdb_name
-- FROM    v$containers c, v$rsrcmgrmetric r, v$database d, v$instance i
-- WHERE   c.open_mode = 'READ WRITE' AND c.restricted = 'NO' AND c.con_id > 2
-- AND     r.con_id(+) = c.con_id -- DBPERF-6513
-- AND     r.consumer_group_name(+) = 'OTHER_GROUPS' -- DBPERF-6513
-- AND     ROWNUM >= 1 /* MATERIALIZE NO_MERGE */
-- GROUP BY
--         c.con_id,
--         c.name
-- HAVING  MAX(r.avg_running_sessions) > 0.25
-- )
-- SELECT  /*+ MATERIALIZE NO_MERGE */
--         s.con_id, s.exact_matching_signature AS signature, s.sql_id, s.plan_hash_value, s.sql_plan_baseline AS plan_name,
--         s.parsing_user_id, s.parsing_schema_id, s.parsing_schema_name, s.hash_value, s.address, s.sql_text,
--         CASE WHEN s.sql_text LIKE '/* performScanQuery(%' THEN SUBSTR(s.sql_text, INSTR(s.sql_text, '(') + 1, INSTR(s.sql_text, ',') - INSTR(s.sql_text, '(') - 1) END AS kiev_table_name,
--         MIN(TO_DATE(s.first_load_time, 'YYYY-MM-DD/HH24:MI:SS')) AS first_load_time,
--         MAX(s.last_active_time) AS last_active_time,
--         GREATEST(SUM(s.executions), 1) AS cur_executions,
--         SUM(s.cpu_time) AS cur_cpu_time,
--         SUM(s.rows_processed) AS cur_rows_processed,
--         SUM(s.buffer_gets) AS cur_buffer_gets,
--         s.sql_profile AS profile_name, s.sql_patch AS patch_name,
--         sp.baseline_repro_fail
-- FROM    c,
--         v$sql s
--         OUTER APPLY (
--               SELECT  COUNT(*) AS baseline_repro_fail /* "Failed to use SQL plan baseline for this statement" */
--               FROM    v$sql_plan sp /* X$KQLFXPL has an index on KQLFXPL_HADD, KQLFXPL_PHAD, KQLFXPL_HASH, KQLFXPL_SQLID */
--               WHERE   s.sql_plan_baseline IS NULL
--               AND     sp.child_address = s.child_address
--               AND     sp.address = s.address
--               AND     sp.hash_value = s.hash_value
--               AND     sp.sql_id = s.sql_id
--               AND     sp.other_xml LIKE '%baseline_repro_fail%'
--         ) sp
-- WHERE   1 = 1 -- CASE WHEN s.sql_plan_baseline IS NULL THEN 'CREATE' WHEN s.sql_plan_baseline IS NOT NULL THEN 'DISABLE'
-- AND     s.con_id = c.con_id
-- AND     s.parsing_user_id > 0 -- exclude SYS
-- AND     s.parsing_schema_id > 0 -- exclude SYS
-- AND     s.parsing_schema_name NOT IN ('SYS', 'SYSTEM', 'MDSYS', 'ORDDATA', 'CTXSYS', 'WMSYS', 'DVSYS', 'XDB', 'LBACSYS', 'DBSNMP', 'GSMADMIN_INTERNAL') -- to reduce selection
-- AND     s.parsing_schema_name NOT LIKE 'C##%' -- to reduce selection
-- AND     s.parsing_schema_name NOT LIKE 'APEX%' -- to reduce selection
-- AND     s.plan_hash_value > 0 -- e.g.: PL/SQL has 0 on PHV
-- AND     s.exact_matching_signature > 0 -- INSERT from values has 0 on signature
-- AND     s.executions > 0
-- AND     s.cpu_time > 0
-- AND     s.buffer_gets > 0
-- AND     s.buffer_gets > s.executions
-- AND     s.object_status = 'VALID'
-- AND     s.is_obsolete = 'N'
-- AND     s.is_shareable = 'Y'
-- AND     s.is_bind_aware = 'N' -- to ignore cursors using adaptive cursor sharing ACS as per CHANGE-190522
-- AND     s.is_resolved_adaptive_plan IS NULL -- to ignore adaptive plans which cause trouble when combined with SPM
-- AND     s.is_reoptimizable = 'N' -- to ignore cursors which require adjustments as per cardinality feedback  
-- AND     sp.baseline_repro_fail > 0 -- "Failed to use SQL plan baseline for this statement"
-- GROUP BY
--         s.con_id, s.exact_matching_signature, s.sql_id, s.plan_hash_value, s.sql_plan_baseline, s.sql_profile, s.sql_patch,
--         s.parsing_user_id, s.parsing_schema_id, s.parsing_schema_name, s.hash_value, s.address, s.sql_text,
--         sp.baseline_repro_fail
-- HAVING
--         SUM(s.executions) > 0 
-- AND     SUM(s.cpu_time) > 0
-- AND     SUM(s.buffer_gets) > 0
-- AND     SUM(s.buffer_gets) > SUM(s.executions) -- to avoid creating baselines on SQL that process little, then disable them because of regression (e.g. DELETE based on empty SELECT)
-- /

-- SET SERVEROUT ON HEA OFF PAGES 0 LIN 300;
-- list sql with plans where a baseline exists but it is ignored
-- DECLARE
--   l_plans NUMBER;
-- BEGIN
--   FOR i IN (WITH
--             b AS (SELECT /*+ MATERIALIZE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ DISTINCT con_id, signature, sql_handle FROM cdb_sql_plan_baselines WHERE enabled = 'YES' AND accepted = 'YES' /*AND created < SYSDATE - (1/24)*/ AND con_id > 2 AND ROWNUM >= 1),
--             c AS (SELECT /*+ MATERIALIZE NO_MERGE */ DISTINCT con_id, name AS pdb_name FROM v$containers WHERE con_id > 2 AND ROWNUM >= 1),
--             -- p AS (SELECT /*+ MATERIALIZE NO_MERGE */ con_id, address, hash_value, sql_id, plan_hash_value, child_address, child_number FROM v$sql_plan p, 
--             --       XMLTABLE('other_xml/info' PASSING XMLTYPE(p.other_xml) COLUMNS type VARCHAR2(30) PATH '@type', note VARCHAR2(4) PATH '@note', value VARCHAR2(30) PATH '.') x 
--             --       WHERE p.con_id > 2 AND p.other_xml LIKE '%baseline_repro_fail%' AND x.type = 'baseline_repro_fail' AND x.value = 'yes' AND ROWNUM >= 1),
--             s AS (SELECT /*+ MATERIALIZE NO_MERGE */ DISTINCT con_id, address, hash_value, sql_id, plan_hash_value, child_address, child_number, exact_matching_signature AS signature, elapsed_time, sql_text FROM v$sql 
--                   WHERE con_id > 2 AND parsing_user_id > 0 AND parsing_schema_id > 0 AND exact_matching_signature > 0 AND cpu_time > 0 AND buffer_gets > executions AND object_status = 'VALID' 
--                   AND is_obsolete = 'N' AND is_shareable = 'Y' AND is_bind_aware = 'N'  AND is_resolved_adaptive_plan IS NULL  AND is_reoptimizable = 'N' AND last_active_time > SYSDATE - (1/24) AND ROWNUM >= 1),
--             x AS (
--             SELECT  /*+ MATERIALIZE NO_MERGE */ DISTINCT s.con_id, s.sql_id, s.signature, s.elapsed_time, s.sql_text
--             FROM    v$sql_plan p,
--                     XMLTABLE('other_xml/info' PASSING XMLTYPE(p.other_xml) COLUMNS type VARCHAR2(30) PATH '@type', note VARCHAR2(4) PATH '@note', value VARCHAR2(30) PATH '.') x,
--                     s
--             WHERE   p.con_id > 2
--             AND     p.plan_hash_value > 0
--             AND     p.other_xml LIKE '%baseline_repro_fail%'
--             AND     p.con_id = s.con_id
--             AND     p.address = s.address
--             AND     p.hash_value = s.hash_value
--             AND     p.sql_id = s.sql_id
--             AND     p.plan_hash_value = s.plan_hash_value
--             AND     p.child_address = s.child_address
--             AND     p.child_number = s.child_number
--             AND     x.type = 'baseline_repro_fail' 
--             AND     x.value = 'yes'
--             AND     ROWNUM >= 1)
--             SELECT  SUM(x.elapsed_time) AS elapsed_time, c.pdb_name, x.sql_id, b.sql_handle, x.sql_text
--               FROM  x, c, b
--              WHERE  c.con_id = x.con_id
--              AND    b.con_id = x.con_id
--              AND    b.signature = x.signature
--             GROUP BY c.pdb_name, x.sql_id, b.sql_handle, x.sql_text
--             ORDER BY 1 DESC)
--   LOOP
--     DBMS_OUTPUT.put_line(i.pdb_name||' '||i.sql_id||' '||i.sql_handle||' '||SUBSTR(i.sql_text, 1, 80));
--   END LOOP;
-- END;
-- /

-- SELECT   p.con_id, p.sql_id, p.plan_hash_value, p.child_number
--  FROM    v$sql_plan p,
--          XMLTABLE('other_xml/info' PASSING XMLTYPE(p.other_xml) COLUMNS type VARCHAR2(30) PATH '@type', note VARCHAR2(4) PATH '@note', value VARCHAR2(30) PATH '.') x
--  WHERE   p.con_id > 2
--  AND     p.plan_hash_value > 0
--  AND     p.other_xml LIKE '%baseline_repro_fail%'
--  AND     x.type = 'baseline_repro_fail' 
--  AND     x.value = 'yes'
--  ORDER BY
--          p.con_id, p.sql_id, p.plan_hash_value, p.child_number
-- /
-- SELECT   DISTINCT p.con_id, p.sql_id, p.plan_hash_value, p.child_number
--  FROM    v$sql_plan p
--  WHERE   p.other_xml LIKE '%baseline_repro_fail%'
--  ORDER BY
--          p.con_id, p.sql_id, p.plan_hash_value, p.child_number
-- /
