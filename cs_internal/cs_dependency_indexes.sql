COL table_owner FOR A30 HEA 'Table Owner';
COL table_name FOR A30 HEA 'Table Name';
COL index_name FOR A30 HEA 'Index Name';
COL partitioned FOR A4 HEA 'Part';
COL orphaned_entries FOR A8 HEA 'Orphaned|Entries';
COL degree FOR A10 HEA 'Degree';
COL index_type FOR A27 HEA 'Index Type';
COL uniqueness FOR A10 HEA 'Uniqueness';
COL columns FOR 999,999 HEA 'Columns';
COL status FOR A8 HEA 'Status';
COL visibility FOR A10 HEA 'Visibility';
COL blevel FOR 99,990 HEA 'BLevel';
COL leaf_blocks FOR 999,999,990 HEA 'Leaf Blocks';
COL size_MiB FOR 999,999,990.000 HEA 'Size MiB';
COL seg_size_MiB FOR 999,999,990.000 HEA 'Seg Size MiB';
COL size_MB FOR 999,999,990.000 HEA 'Size MB';
COL seg_size_MB FOR 999,999,990.000 HEA 'Seg Size MB';
COL distinct_keys FOR 999,999,999,990 HEA 'Dist Keys';
COL clustering_factor FOR 999,999,999,990 HEA 'Clust Fact';
COL num_rows FOR 999,999,999,990 HEA 'Num Rows';
COL sample_size FOR 999,999,999,990 HEA 'Sample Size';
COL last_analyzed FOR A19 HEA 'Last Analyzed';
COL compression FOR A13 HEA 'Compression';
COL tablespace_name FOR A30 HEA 'Tablespace';
--
PRO
PRO INDEXES (dba_indexes)
PRO ~~~~~~~
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
SELECT /*+ QB_NAME(get_stats) */
       i.table_owner,
       i.table_name,
       i.index_name,
       CASE i.partitioned WHEN 'YES' THEN (SELECT TRIM(TO_CHAR(COUNT(*))) FROM dba_ind_partitions ip WHERE ip.index_owner = i.owner AND ip.index_name = i.index_name) ELSE i.partitioned END AS partitioned,
       i.orphaned_entries,
       i.degree,
       i.index_type,
       i.uniqueness,
       (SELECT COUNT(*) FROM dba_ind_columns ic WHERE ic.index_owner = i.owner AND ic.index_name = i.index_name) AS columns,
       i.status,
       i.visibility,
       i.blevel,
       i.leaf_blocks,
       --i.leaf_blocks * COALESCE(b.block_size, TO_NUMBER(p.value)) / POWER(2,20) AS size_MiB,
       i.leaf_blocks * COALESCE(b.block_size, TO_NUMBER(p.value)) / POWER(10,6) AS size_MB,
       --(SELECT SUM(s.bytes) / POWER(2,20) FROM dba_segments s WHERE s.owner = i.owner AND s.segment_name = i.index_name AND s.segment_type LIKE 'INDEX%') AS seg_size_MiB,
       (SELECT SUM(s.bytes) / POWER(10,6) FROM dba_segments s WHERE s.owner = i.owner AND s.segment_name = i.index_name AND s.segment_type LIKE 'INDEX%') AS seg_size_MB,
       i.distinct_keys,
       i.clustering_factor,
       i.num_rows,
       i.sample_size,
       TO_CHAR(i.last_analyzed, '&&cs_datetime_full_format.') AS last_analyzed,
       i.compression,
       i.tablespace_name
  FROM dba_tables_m t,
       dba_indexes i,
       dba_tablespaces b,
       v$parameter p
 WHERE i.table_owner = t.owner
   AND i.table_name = t.table_name
   AND b.tablespace_name(+) = i.tablespace_name
   AND p.name = 'db_block_size'
 ORDER BY
       i.table_owner,
       i.table_name,
       i.index_name
/
--
COL object_type HEA 'Object Type';
COL object_id FOR 999999999 HEA 'Object ID';
COL object_name FOR A30 HEA 'Object Name' TRUNC;
COL created FOR A19 HEA 'Created';
COL last_ddl_time FOR A19 HEA 'Last DDL Time';
--
PRO
PRO INDEX OBJECTS (dba_objects) up to 100 
PRO ~~~~~~~~~~~~~
WITH /* OBJECTS */
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
SELECT o.object_type,
       o.owner,
       o.object_name,
       o.object_id,
       TO_CHAR(o.created, '&&cs_datetime_full_format.') AS created,
       TO_CHAR(o.last_ddl_time, '&&cs_datetime_full_format.') AS last_ddl_time
  FROM dba_tables_m t,
       dba_indexes i,
       dba_objects o
 WHERE i.table_owner = t.owner
   AND i.table_name = t.table_name
   AND o.owner = i.owner
   AND o.object_name = i.index_name
   AND o.object_type LIKE 'INDEX%'
 ORDER BY
       o.object_type,
       o.owner,
       o.object_name
FETCH FIRST 100 ROWS ONLY       
/
