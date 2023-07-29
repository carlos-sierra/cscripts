COL owner FOR A30 HEA 'Table Owner';
COL table_name FOR A30 HEA 'Table Name';
COL column_name FOR A30 HEA 'Column Name';
COL index_name FOR A30 HEA 'Index Name';
COL segment_name FOR A30 HEA 'Segment Name';
COL bytes FOR 999,999,999,999,990 HEA 'Bytes';
COL blocks FOR 999,999,990 HEA 'Blocks';
COL size_MiB FOR 999,999,990.000 HEA 'Size MiB';
COL size_MB FOR 999,999,990.000 HEA 'Size MB';
COL deduplication FOR A13 HEA 'Deduplication';
COL compression FOR A11 HEA 'Compression';
COL encrypt FOR A7 HEA 'Encrypt';
COL cache FOR A5 HEA 'Cache';
COL securefile FOR A10 HEA 'SecureFile';
COL in_row FOR A6 HEA 'In Row';
COL tablespace_name FOR A30 HEA 'Tablespace';
--
BRE ON owner ON table_name SKIP 1;
--
PRO
PRO LOBS (dba_lobs) 
PRO ~~~~
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
       t.owner,
       t.table_name,
       l.column_name,
       SUM(s.bytes) AS bytes,
       SUM(s.blocks) AS blocks,
       --SUM(s.blocks) * COALESCE(b.block_size, TO_NUMBER(p.value)) / POWER(2,20) AS size_MiB,
       SUM(s.blocks) * COALESCE(b.block_size, TO_NUMBER(p.value)) / POWER(10,6) AS size_MB,
       l.deduplication,
       l.compression,
       l.encrypt,
       l.cache,
       l.securefile,
       l.in_row,
       l.index_name,
       l.segment_name,
       l.tablespace_name
  FROM dba_tables_m t,
       dba_lobs l,
       dba_segments s,
       dba_tablespaces b,
       v$parameter p
 WHERE l.owner = t.owner
   AND l.table_name = t.table_name
   AND s.owner = l.owner
   AND s.segment_name = l.segment_name
   AND s.segment_type IN ('LOBSEGMENT', 'LOB PARTITION')
   AND b.tablespace_name(+) = l.tablespace_name
   AND p.name = 'db_block_size'
 GROUP BY
       t.owner,
       t.table_name,
       l.column_name,
       l.index_name,
       l.segment_name,
       l.deduplication,
       l.compression,
       l.encrypt,
       l.cache,
       l.securefile,
       l.in_row,
       l.tablespace_name,
       b.block_size,
       p.value
 ORDER BY
       t.owner,
       t.table_name,
       l.column_name
/
--
CL BRE;
--