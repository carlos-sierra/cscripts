COL owner FOR A30 HEA 'Owner';
COL table_name FOR A30 HEA 'Table Name';
COL partitioned FOR A4 HEA 'Part';
COL degree FOR A10 HEA 'Degree';
COL temporary FOR A4 HEA 'Temp';
COL blocks FOR 999,999,990 HEA 'Blocks';
COL num_rows FOR 999,999,999,990 HEA 'Num Rows';
COL avg_row_len FOR 999,999,990 HEA 'Avg Row Len';
COL size_MiB FOR 999,999,990.000 HEA 'Size MiB';
COL seg_size_MiB FOR 999,999,990.000 HEA 'Seg Size MiB';
COL estimated_MiB FOR 999,999,990.000 HEA 'Estimated MiB';
COL size_MB FOR 999,999,990.000 HEA 'Size MB';
COL seg_size_MB FOR 999,999,990.000 HEA 'Seg Size MB';
COL estimated_MB FOR 999,999,990.000 HEA 'Estimated MB';
COL sample_size FOR 999,999,999,990 HEA 'Sample Size';
COL last_analyzed FOR A19 HEA 'Last Analyzed';
COL compression FOR A12 HEA 'Compression';
COL tablespace_name FOR A30 HEA 'Tablespace';
--
PRO
PRO TABLES (dba_tables)
PRO ~~~~~~
WITH /* TABLES ACCESSED */
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
       t.table_name, 
       CASE t.partitioned WHEN 'YES' THEN (SELECT TRIM(TO_CHAR(COUNT(*))) FROM dba_tab_partitions tp WHERE tp.table_owner = t.owner AND tp.table_name = t.table_name) ELSE t.partitioned END AS partitioned,
       t.degree,
       t.temporary,
       t.blocks,
       COALESCE(b.block_size, TO_NUMBER(p.value)) AS block_size,
       --(SELECT SUM(s.bytes) / POWER(2,20) FROM dba_segments s WHERE s.owner = t.owner AND s.segment_name = t.table_name AND s.segment_type LIKE 'TABLE%') AS seg_size_MiB,
       (SELECT SUM(s.bytes) / POWER(10,6) FROM dba_segments s WHERE s.owner = t.owner AND s.segment_name = t.table_name AND s.segment_type LIKE 'TABLE%') AS seg_size_MB,
       t.num_rows, 
       t.avg_row_len,
       t.sample_size,
       t.last_analyzed,
       t.compression,
       t.tablespace_name
  FROM dba_tables t,
     --   v_db_object_cache_m c,
       v_object_dependency_m o,
       dba_tablespaces b,
       v$parameter p
--  WHERE t.owner = c.object_owner
--    AND t.table_name = c.object_name 
 WHERE t.owner = o.to_owner
   AND t.table_name = o.to_name 
   AND b.tablespace_name(+) = t.tablespace_name
   AND p.name = 'db_block_size'
)
SELECT /*+ QB_NAME(get_stats) */
       owner, 
       table_name, 
       partitioned,
       degree,
       temporary,
       blocks,
       --blocks * block_size / POWER(2,20) AS size_MiB,
       blocks * block_size / POWER(10,6) AS size_MB,
       --seg_size_MiB,
       seg_size_MB,
       num_rows,
       avg_row_len, 
       --num_rows * avg_row_len / POWER(2,20) AS estimated_MiB,
       num_rows * avg_row_len / POWER(10,6) AS estimated_MB,
       sample_size,
       TO_CHAR(last_analyzed, '&&cs_datetime_full_format.') AS last_analyzed,
       compression,
       tablespace_name
  FROM dba_tables_m
 ORDER BY
       owner,
       table_name
/
--
COL object_id FOR 999999999 HEA 'Object ID';
COL object_name FOR A30 HEA 'Object Name' TRUNC;
COL created FOR A19 HEA 'Created';
COL last_ddl_time FOR A19 HEA 'Last DDL Time';
--
PRO
PRO TABLE OBJECTS (dba_objects)
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
SELECT o.owner,
       o.object_name,
       o.object_id,
       TO_CHAR(o.created, '&&cs_datetime_full_format.') AS created,
       TO_CHAR(o.last_ddl_time, '&&cs_datetime_full_format.') AS last_ddl_time
  FROM dba_tables_m t,
       dba_objects o
 WHERE o.owner = t.owner
   AND o.object_name = t.table_name
   AND o.object_type = 'TABLE'
 ORDER BY
       o.owner,
       o.object_name
/
--
