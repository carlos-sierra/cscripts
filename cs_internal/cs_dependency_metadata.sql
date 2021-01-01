DEF max_partitions = '1000';
--
COL owner FOR A30 HEA 'Owner';
COL table_name FOR A30 HEA 'Table Name';
COL index_name FOR A30 HEA 'Index Name';
COL metadata FOR A200 HEA 'Metadata';
--
BREAK ON table_name SKIP PAGE;
PRO
PRO TABLE METADATA DBMS_METADATA.get_ddl('TABLE', table_name, owner) only if up to &&max_partitions. partitions
PRO ~~~~~~~~~~~~~~
WITH /* TABLES */
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
)
SELECT owner, table_name, DBMS_METADATA.get_ddl('TABLE', table_name, owner) AS metadata
  FROM dba_tables_m
 ORDER BY
       owner, table_name
/
--
BREAK ON index_name SKIP PAGE;
PRO
PRO INDEX METADATA DBMS_METADATA.get_ddl('INDEX', index_name, owner) only if up to &&max_partitions. partitions
PRO ~~~~~~~~~~~~~~
WITH /* INDEXES */
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
)
SELECT i.owner, i.table_name, i.index_name, DBMS_METADATA.get_ddl('INDEX', i.index_name, i.owner) AS metadata
  FROM dba_tables_m t,
       dba_indexes i
 WHERE i.table_owner = t.owner
   AND i.table_name = t.table_name
   AND CASE i.partitioned WHEN 'YES' THEN -- include only indexes with up to &&max_partitions. partitions
       CASE WHEN (SELECT COUNT(*) FROM dba_ind_partitions ip WHERE ip.index_owner = i.owner AND ip.index_name = i.index_name) <= &&max_partitions. THEN 1 ELSE 0 END
       ELSE 1 END = 1
 ORDER BY
       i.owner,
       i.table_name,
       i.index_name
/
--
CLEAR BREAK;