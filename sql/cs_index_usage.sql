SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
DEF table_name = 'FINDINGS';
--
COL owner FOR A30 TRUNC;
COL index_name FOR A30 TRUNC;
--
WITH 
p AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT
       h.sql_id,
       h.plan_hash_value,
       h.object#,
       h.object_owner,
       h.object_name
  FROM dba_hist_sql_plan h
 WHERE h.object_type LIKE 'INDEX%'
),
a AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       p.sql_id,
       p.plan_hash_value,
       p.object_owner,
       p.object_name,
       COUNT(*) AS samples
  FROM dba_hist_active_sess_history h, p
 WHERE h.sample_time > SYSDATE - 7
   AND h.sql_id = p.sql_id
   AND h.sql_plan_hash_value = p.plan_hash_value
 GROUP BY
       p.sql_id,
       p.plan_hash_value,
       p.object_owner,
       p.object_name
),
i AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       d.owner,
       d.index_name
  FROM dba_indexes d
 WHERE d.table_name = '&&table_name.'
)
SELECT i.owner,
       i.index_name,
       SUM(a.samples) AS samples
  FROM i, a
 WHERE a.object_owner(+) = i.owner
   AND a.object_name(+) = i.index_name
 GROUP BY
       i.owner,
       i.index_name
 ORDER BY
       3 DESC NULLS LAST
/
