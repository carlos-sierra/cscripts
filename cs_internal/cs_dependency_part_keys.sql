COL part_sub FOR A12 HEA 'LEVEL';
COL object_type FOR A5 HEA 'TYPE';
COL owner FOR A30 TRUNC;
COL name FOR A30 TRUNC;
COL column_position FOR 999 HEA 'POS';
COL column_name FOR A30 TRUNC;
--
PRO
PRO PARTITION KEYS (dba_part_key_columns and dba_subpart_key_columns)
PRO ~~~~~~~~~~~~~~
--
WITH /* PART_KEY_COLUMNS */
v_sqlarea_m AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(sqlarea) */ 
       DISTINCT 
       hash_value, address
  FROM v$sqlarea 
 WHERE sql_id = '&&cs_sql_id.'
),
v_object_dependency_m AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(obj_dependency) */ 
       DISTINCT 
       o.to_owner, o.to_name
      --  o.to_hash, o.to_address 
  FROM v$object_dependency o,
       v_sqlarea_m s
 WHERE o.from_hash = s.hash_value 
   AND o.from_address = s.address
   AND o.to_type = 2 -- table
),
-- v_db_object_cache_m AS (
-- SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(obj_cache) */ 
--        DISTINCT 
--        SUBSTR(c.owner,1,30) AS object_owner, 
--        SUBSTR(c.name,1,30) AS object_name 
--   FROM v$db_object_cache c,
--        v_object_dependency_m d
--  WHERE c.type IN ('TABLE','VIEW') 
--    AND c.hash_value = d.to_hash
--    AND c.addr = d.to_address 
-- ),
dba_tables_m AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(dba_tables) */ 
       t.owner, 
       t.table_name
  FROM dba_tables t,
       v_object_dependency_m o
      --  v_db_object_cache_m c
--  WHERE t.owner = c.object_owner
--    AND t.table_name = c.object_name 
 WHERE t.owner = o.to_owner
   AND t.table_name = o.to_name 
),
dba_indexes_m AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(dba_indexes) */ 
       i.owner,
       i.index_name
  FROM dba_tables_m t,
       dba_indexes i
 WHERE i.table_owner = t.owner
   AND i.table_name = t.table_name
),
objects_m AS (
SELECT owner, table_name AS name, 'TABLE' AS object_type
  FROM dba_tables_m
 UNION
SELECT owner, index_name AS name, 'INDEX' AS object_type
  FROM dba_indexes_m
)
SELECT 'PARTITION' AS part_sub,
       p.object_type,
       p.owner,
       p.name,
       p.column_position,
       p.column_name
  FROM dba_part_key_columns p,
       objects_m o
 WHERE o.owner = p.owner
   AND o.name = p.name
   AND o.object_type = p.object_type
 UNION ALL
SELECT 'SUBPARTITION' AS part_sub,
       p.object_type,
       p.owner,
       p.name,
       p.column_position,
       p.column_name
  FROM dba_subpart_key_columns p,
       objects_m o
 WHERE o.owner = p.owner
   AND o.name = p.name
   AND o.object_type = p.object_type
 ORDER BY
       1 ASC, 2 DESC, 3, 4, 5
/
