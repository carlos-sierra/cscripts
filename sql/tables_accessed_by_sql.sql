SET PAGES 100 LINE 300
COL owner FOR A30;
COL table_name FOR A30;
WITH /*+ GATHER_PLAN_STATISTICS */
v_sqlarea_m AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(sqlarea) */ 
       hash_value, address
  FROM v$sqlarea 
 WHERE sql_id = '&sql_id.'
),
v_object_dependency_m AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(obj_dependency) */ 
       DISTINCT o.to_hash, o.to_address 
  FROM v$object_dependency o,
       v_sqlarea_m s
 WHERE o.from_hash = s.hash_value 
   AND o.from_address = s.address
),
v_db_object_cache_m AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(obj_cache) */ 
       SUBSTR(c.owner,1,30) object_owner, 
       SUBSTR(c.name,1,30) object_name 
  FROM v$db_object_cache c,
       v_object_dependency_m d
 WHERE c.type IN ('TABLE','VIEW') 
   AND c.hash_value = d.to_hash
   AND c.addr = d.to_address 
),
dba_tables_m AS (
SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(cdb_tables) */ 
       DISTINCT
       t.owner, 
       t.table_name, 
       t.temporary,
       t.blocks,
       t.num_rows, 
       t.avg_row_len,
       t.last_analyzed, 
       ROW_NUMBER() OVER (ORDER BY t.num_rows DESC NULLS LAST) row_number 
  FROM dba_tables t,
       v_db_object_cache_m c
 WHERE t.owner = c.object_owner
   AND t.table_name = c.object_name 
)
SELECT /*+ GATHER_PLAN_STATISTICS QB_NAME(main) */
       owner, 
       table_name, 
       temporary,
       blocks,
       num_rows,
       avg_row_len, 
       last_analyzed
  FROM dba_tables_m
 ORDER BY
       row_number
/