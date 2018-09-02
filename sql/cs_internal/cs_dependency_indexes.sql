COL table_owner FOR A30 HEA 'Table Owner';
COL table_name FOR A30 HEA 'Table Name';
COL index_name FOR A30 HEA 'Index Name';
COL partitioned FOR A4 HEA 'Part';
COL degree FOR A10 HEA 'Degree';
COL index_type FOR A27 HEA 'Index Type';
COL uniqueness FOR A10 HEA 'Uniqueness';
COL columns FOR 999,999 HEA 'Columns';
COL status FOR A8 HEA 'Status';
COL visibility FOR A10 HEA 'Visibility';
COL blevel FOR 99,990 HEA 'BLevel';
COL leaf_blocks FOR 999,999,990 HEA 'Leaf Blocks';
COL distinct_keys FOR 999,999,999,990 HEA 'Dist Keys';
COL clustering_factor FOR 999,999,999,990 HEA 'Clust Fact';
COL num_rows FOR 999,999,999,990 HEA 'Num Rows';
COL sample_size FOR 999,999,999,990 HEA 'Sample Size';
COL last_analyzed FOR A19 HEA 'Last Analyzed';
COL compression FOR A13 HEA 'Compression';
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
       o.to_hash, o.to_address 
  FROM v$object_dependency o,
       v_sqlarea_m s
 WHERE o.from_hash = s.hash_value 
   AND o.from_address = s.address
),
v_db_object_cache_m AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(obj_cache) */ 
       DISTINCT 
       SUBSTR(c.owner,1,30) object_owner, 
       SUBSTR(c.name,1,30) object_name 
  FROM v$db_object_cache c,
       v_object_dependency_m d
 WHERE c.type IN ('TABLE','VIEW') 
   AND c.hash_value = d.to_hash
   AND c.addr = d.to_address 
),
dba_tables_m AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(dba_tables) */ 
       t.owner, 
       t.table_name
  FROM dba_tables t,
       v_db_object_cache_m c
 WHERE t.owner = c.object_owner
   AND t.table_name = c.object_name 
)
SELECT /*+ QB_NAME(get_stats) */
       i.table_owner,
       i.table_name,
       i.index_name,
       i.partitioned,
       i.degree,
       i.index_type,
       i.uniqueness,
       (SELECT COUNT(*) FROM dba_ind_columns ic WHERE ic.index_owner = i.owner AND ic.index_name = i.index_name) columns,
       i.status,
       i.visibility,
       i.blevel,
       i.leaf_blocks,
       i.distinct_keys,
       i.clustering_factor,
       i.num_rows,
       i.sample_size,
       TO_CHAR(i.last_analyzed, '&&cs_datetime_full_format.') last_analyzed,
       compression
  FROM dba_tables_m t,
       dba_indexes i
 WHERE i.table_owner = t.owner
   AND i.table_name = t.table_name
 ORDER BY
       i.table_owner,
       i.table_name,
       i.index_name
/
--