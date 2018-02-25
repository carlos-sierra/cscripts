SET LIN 300 PAGES 100
BREAK ON con_id SKIP 1;
COMP SUM LABEL 'TOTAL' OF version_count loaded_versions open_versions users_opening ON con_id;
WITH /*+ GATHER_PLAN_STATISTICS */
v_db_object_cache_m AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(obj_cache) */ 
       c.hash_value, 
       c.addr 
  FROM v$db_object_cache c
 WHERE c.type IN ('TABLE','VIEW') 
   AND c.owner = UPPER('&owner.')
   AND c.name = UPPER('&table_name.')
),
v_object_dependency_m AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(obj_dependency) */ 
       o.from_hash, o.from_address
  FROM v$object_dependency o,
       v_db_object_cache_m s
 WHERE o.to_hash = s.hash_value
   AND o.to_address = s.addr
),
v_sqlarea_m AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(sqlarea) */ 
       DISTINCT
       s.con_id,
       s.sql_id,
       s.version_count,
       s.loaded_versions,
       s.open_versions,
       s.users_opening
  FROM v$sqlarea s,
       v_object_dependency_m d
 WHERE s.hash_value = d.from_hash
   AND s.address = d.from_address
)
SELECT /*+ GATHER_PLAN_STATISTICS QB_NAME(main) */
       s.con_id,
       s.sql_id,
       s.version_count,
       s.loaded_versions,
       s.open_versions,
       s.users_opening
  FROM v_sqlarea_m s
 ORDER BY
       s.con_id,
       s.sql_id
/
