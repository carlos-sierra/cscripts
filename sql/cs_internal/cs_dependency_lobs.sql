COL owner FOR A30 HEA 'Table Owner';
COL table_name FOR A30 HEA 'Table Name';
COL column_name FOR A30 HEA 'Column Name';
COL index_name FOR A30 HEA 'Index Name';
COL segment_name FOR A30 HEA 'Segment Name';
COL bytes FOR 999,999,999,990 HEA 'Bytes';
COL blocks FOR 999,999,990 HEA 'Blocks';
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
       t.owner,
       t.table_name,
       l.column_name,
       l.index_name,
       l.segment_name,
       s.bytes,
       s.blocks
  FROM dba_tables_m t,
       dba_lobs l,
       dba_segments s
 WHERE l.owner = t.owner
   AND l.table_name = t.table_name
   AND s.owner = l.owner
   AND s.segment_name = l.segment_name
   AND s.segment_type = 'LOBSEGMENT'
 ORDER BY
       t.owner,
       t.table_name,
       l.column_name
/
--
CL BRE;
--