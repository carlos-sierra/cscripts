SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL pdb_name FOR A30 TRUNC;
COL plan_name FOR A30 TRUNC;
COL baselines FOR 999,990;
COL cursors FOR 999,990;
COL executions FOR 999,999,990;
COL ms_per_exec FOR 999,999,990.0;
COL last_active_time FOR A19;
COL sql_text FOR A80 TRUNC;
--
BREAK ON pdb_name SKIP PAGE DUPL ON sql_id SKIP 1 DUPL;
--
WITH
b AS (
SELECT  /*+ MATERIALIZE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
        b.con_id, b.signature, COUNT(*) AS baselines
FROM    cdb_sql_plan_baselines b
WHERE   b.enabled = 'YES'
AND     b.accepted = 'YES'
AND     ROWNUM >= 1 /* MATERIALIZE */
GROUP BY
        b.con_id, b.signature
),
s AS (
SELECT  c.name AS pdb_name,
        s.exact_matching_signature AS signature,
        s.sql_id,
        s.plan_hash_value,
        s.sql_plan_baseline AS plan_name,
        s.sql_text,
        SUM(s.executions) AS executions,
        SUM(s.cpu_time) / SUM(s.executions) / POWER(10, 3) AS ms_per_exec,
        MAX(b.baselines) AS baselines,
        MAX(s.last_active_time) AS last_active_time,
        COUNT(DISTINCT s.plan_hash_value) OVER (PARTITION BY c.name, s.exact_matching_signature, s.sql_id) AS distinct_plans,
        COUNT(*) AS cursors
FROM    v$sql s, v$containers c, b
WHERE   1 = 1
AND     s.parsing_user_id > 0
AND     s.parsing_schema_id > 0
AND     s.plan_hash_value > 0
AND     s.exact_matching_signature > 0
AND     s.executions > 0
AND     s.cpu_time > 0 
AND     s.buffer_gets > 0
AND     s.buffer_gets > s.executions
AND     s.object_status = 'VALID'
AND     s.is_obsolete = 'N'
AND     s.is_shareable = 'Y'
AND     s.is_bind_aware = 'N' 
AND     s.is_resolved_adaptive_plan IS NULL
AND     s.is_reoptimizable = 'N'
AND     s.last_active_time > SYSDATE - (1/24) -- executed during last 1h
AND     c.con_id = s.con_id
AND     c.open_mode = 'READ WRITE'
AND     b.con_id(+) = s.con_id
AND     b.signature(+) = s.exact_matching_signature
AND     ROWNUM >= 1 /* MATERIALIZE */
GROUP BY
        c.name,
        s.exact_matching_signature,
        s.sql_id,
        s.plan_hash_value,
        s.sql_plan_baseline,
        s.sql_text
)
SELECT  pdb_name, signature, sql_id, plan_hash_value, plan_name, distinct_plans, baselines, executions, ms_per_exec, last_active_time, sql_text
FROM    s
-- WHERE   baselines <> distinct_plans OR distinct_plans > 1 OR baselines > 1
WHERE   baselines <> distinct_plans -- implicit: baselines > 0
ORDER BY
        pdb_name, signature, sql_id, plan_hash_value, plan_name
/
--
CLEAR BREAK;
