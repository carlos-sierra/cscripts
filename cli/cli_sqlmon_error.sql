SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
DEF 1 = 'C##IOD';
COL pdb_name FOR A30;
COL sql_text FOR A80 TRUNC;
  WITH /*+ IOD_SPM.SQL_CANCEL_HANDLER */
  sqlmon AS (
  SELECT /*+ MATERIALIZE NO_MERGE */
         con_id, con_name AS pdb_name, sql_id, exact_matching_signature AS signature, sql_plan_hash_value AS plan_hash_value, sql_text, 
         CASE WHEN sql_text LIKE '/* performScanQuery(%' THEN SUBSTR(sql_text, INSTR(sql_text, '(') + 1, INSTR(sql_text, ',') - INSTR(sql_text, '(') - 1) END AS kiev_table_name,
         SUM(CASE WHEN status LIKE 'DONE%' THEN 1 ELSE 0 END) AS done,
         SUM(CASE WHEN status = 'DONE (ERROR)' THEN 1 ELSE 0 END) AS done_error
    FROM v$sql_monitor
   WHERE status LIKE 'DONE%'
     AND username <> 'SYS'
     AND sql_exec_start > SYSDATE - (1/24)
     AND ('ALL' IS NULL OR UPPER('ALL') IN ('ALL', 'CDB$ROOT') OR UPPER(con_name) = UPPER('ALL'))
     AND sql_id = NVL(NULLIF('ALL', 'ALL'), sql_id)
     AND ROWNUM >= 1 /* MATERIALIZE */
   GROUP BY
         con_id, con_name, sql_id, exact_matching_signature, sql_plan_hash_value, sql_text
  HAVING SUM(CASE WHEN status LIKE 'DONE%' THEN 1 ELSE 0 END) > 2 -- at least 2 executions!
     AND 100 * SUM(CASE WHEN status = 'DONE (ERROR)' THEN 1 ELSE 0 END) / SUM(CASE WHEN status LIKE 'DONE%' THEN 1 ELSE 0 END) > 50
  ),
  sqlmon_ext AS (
  SELECT /*+ MATERIALIZE NO_MERGE */
         m.pdb_name, m.sql_id, m.signature, MIN(m.plan_hash_value) AS min_phv, MAX(m.plan_hash_value) AS max_phv, m.sql_text, m.kiev_table_name, SUM(m.done) AS done, SUM(m.done_error) AS done_error,
         COUNT(DISTINCT s.sql_plan_baseline) AS baselines, COUNT(DISTINCT s.sql_profile) AS profiles, COUNT(DISTINCT s.sql_patch) AS patches
    FROM sqlmon m, v$sql s
   WHERE s.con_id(+) = m.con_id AND s.sql_id(+) = m.sql_id AND s.exact_matching_signature(+) = m.signature AND s.plan_hash_value(+) = m.plan_hash_value AND s.last_active_time(+) > SYSDATE - (1/24)
     AND ROWNUM >= 1 /* MATERIALIZE */
   GROUP BY
         m.pdb_name, m.sql_id, m.signature, m.sql_text, m.kiev_table_name
  )
  SELECT m.pdb_name, m.sql_id, m.signature, m.min_phv, m.max_phv, m.sql_text, m.kiev_table_name, m.done, m.done_error, m.baselines, m.profiles, m.patches
    FROM sqlmon_ext m
   WHERE (m.baselines + m.profiles + m.patches > 0 OR m.kiev_table_name IS NOT NULL) -- SQL has at least one a SPBL/SPRF/SPCH, OR SQL is a KIEV performScanQuery
     AND NOT EXISTS (SELECT NULL FROM &&1..zapper_ignore_sql i WHERE i.sql_id = m.sql_id)
     AND NOT EXISTS (SELECT NULL FROM &&1..zapper_ignore_signature i WHERE i.signature = m.signature)
     AND NOT EXISTS (SELECT NULL FROM &&1..zapper_ignore_sql_text i WHERE UPPER(m.sql_text) LIKE UPPER('%'||i.sql_text||'%'))
   ORDER BY
         m.pdb_name, m.sql_id, m.signature
/