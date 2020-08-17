COL owner FOR A30 TRUNC;
COL segment_name FOR A30 TRUNC;
COL partition_name FOR A30 TRUNC;
COL column_name FOR A30 TRUNC;
COL segments FOR 9,999,990;
--
COL mebibytes FOR 999,999,990.000 HEA 'Size MiB';
COL megabytes FOR 999,999,990.000 HEA 'Size MB';
COL tablespace_name FOR A30 HEA 'Tablespace';
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF MiB MB segments ON REPORT;
--
PRO
PRO SEGMENTS (dba_segments) top 100
PRO ~~~~~~~~
-- do not use cdb views since they perform very poorly
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
),
s AS (
SELECT 1 AS oby, s.segment_type, s.owner, s.segment_name, s.partition_name, NULL AS column_name, s.bytes, s.tablespace_name
  FROM dba_tables_m t, dba_segments s
 WHERE s.owner = t.owner
   AND s.segment_name = t.table_name
   AND s.segment_type LIKE 'TABLE%'
 UNION ALL
SELECT 2 AS oby, s.segment_type, s.owner, s.segment_name, s.partition_name, NULL AS column_name, s.bytes, s.tablespace_name
  FROM dba_tables_m t, dba_indexes i, dba_segments s
 WHERE i.table_owner = t.owner
   AND i.table_name = t.table_name
   AND s.owner = i.owner
   AND s.segment_name = i.index_name
   AND s.segment_type LIKE 'INDEX%'
 UNION ALL
SELECT 3 AS oby, s.segment_type, s.owner, s.segment_name, s.partition_name, l.column_name, s.bytes, s.tablespace_name
  FROM dba_tables_m t, dba_lobs l, dba_segments s
 WHERE l.owner = t.owner
   AND l.table_name = t.table_name
   AND s.owner = l.owner
   AND s.segment_name = l.segment_name
   AND s.segment_type LIKE 'LOB%'
)
--SELECT ROUND(bytes/POWER(2,20),3) AS MiB, segment_type, owner, column_name, segment_name, partition_name, tablespace_name
SELECT ROUND(bytes/POWER(10,6),3) AS MB, segment_type, owner, column_name, segment_name, partition_name, tablespace_name
  FROM s
 ORDER BY bytes DESC, oby, segment_type, owner, column_name, segment_name, partition_name
 FETCH FIRST 100 ROWS ONLY
/
--
PRO
PRO SEGMENT TYPE (dba_segments)
PRO ~~~~~~~~~~~~
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
),
s AS (
SELECT 1 AS oby, s.segment_type, s.owner, s.segment_name, s.partition_name, NULL AS column_name, s.bytes, s.tablespace_name
  FROM dba_tables_m t, dba_segments s
 WHERE s.owner = t.owner
   AND s.segment_name = t.table_name
   AND s.segment_type LIKE 'TABLE%'
 UNION ALL
SELECT 2 AS oby, s.segment_type, s.owner, s.segment_name, s.partition_name, NULL AS column_name, s.bytes, s.tablespace_name
  FROM dba_tables_m t, dba_indexes i, dba_segments s
 WHERE i.table_owner = t.owner
   AND i.table_name = t.table_name
   AND s.owner = i.owner
   AND s.segment_name = i.index_name
   AND s.segment_type LIKE 'INDEX%'
 UNION ALL
SELECT 3 AS oby, s.segment_type, s.owner, s.segment_name, s.partition_name, l.column_name, s.bytes, s.tablespace_name
  FROM dba_tables_m t, dba_lobs l, dba_segments s
 WHERE l.owner = t.owner
   AND l.table_name = t.table_name
   AND s.owner = l.owner
   AND s.segment_name = l.segment_name
   AND s.segment_type LIKE 'LOB%'
)
--SELECT segment_type, COUNT(*) AS segments, ROUND(SUM(bytes)/POWER(2,20),3) AS MiB, tablespace_name
SELECT segment_type, COUNT(*) AS segments, ROUND(SUM(bytes)/POWER(10,6),3) AS MB, tablespace_name
  FROM s
 GROUP BY oby, segment_type, tablespace_name
 ORDER BY oby, segment_type, tablespace_name
/
--
CLEAR BREAK COMPUTE;
