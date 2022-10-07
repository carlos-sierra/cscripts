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
COL rn FOR 999;
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
COL object_type HEA 'Object Type';
COL owner FOR A30 HEA 'Owner';
COL object_id FOR 999999999 HEA 'Object ID';
COL object_name FOR A30 HEA 'Object Name' TRUNC;
COL created FOR A19 HEA 'Created';
COL last_ddl_time FOR A19 HEA 'Last DDL Time';
--
PRO
PRO TABLE OBJECTS (dba_objects) up to 1000
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
       dba_objects o
 WHERE o.owner = t.owner
   AND o.object_name = t.table_name
   AND o.object_type LIKE 'TABLE%'
 ORDER BY
       o.object_type,
       o.owner,
       o.object_name
FETCH FIRST 1000 ROWS ONLY       
/
--
COL object_type HEA 'Object Type';
COL owner FOR A30 HEA 'Owner';
COL object_id FOR 999999999 HEA 'Object ID';
COL object_name FOR A30 HEA 'Object Name' TRUNC;
COL created FOR A19 HEA 'Created';
COL last_ddl_time FOR A19 HEA 'Last DDL Time';
COL analyzetime FOR A19 HEA 'Analyze Time';
COL savtime FOR A23 HEA 'Saved Time';
COL rowcnt FOR 999,999,999,990 HEA 'Row Count';
COL blkcnt FOR 999,999,990 HEA 'Block Count';
COL avgrln FOR 999,999,990 HEA 'Avg Row Len';
COL samplesize FOR 999,999,999,990 HEA 'Sample Size';
--
BREAK ON object_id SKIP 1 ON owner ON object_name ON created ON last_ddl_time;
--
PRO
PRO CBO STAT TABLE HISTORY (wri$_optstat_tab_history) up to 100 per Table
PRO ~~~~~~~~~~~~~~~~~~~~~~
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
),
dba_tables_o AS (
SELECT --o.object_type,
       o.owner,
       o.object_name,
       o.object_id,
       o.created,
       o.last_ddl_time,
       h.analyzetime,
       h.savtime,
       h.rowcnt,
       h.blkcnt,
       h.avgrln,
       h.samplesize,
       ROW_NUMBER() OVER (PARTITION BY o.object_id ORDER BY h.analyzetime DESC NULLS LAST, h.savtime DESC NULLS LAST) AS rn
  FROM dba_tables_m t,
       dba_objects o,
       wri$_optstat_tab_history h
 WHERE o.owner = t.owner
   AND o.object_name = t.table_name
   AND o.object_type = 'TABLE'
   AND h.obj# = o.object_id
)
SELECT DISTINCT
       --o.object_type,
       o.owner,
       o.object_name,
       o.object_id,
       TO_CHAR(o.created, '&&cs_datetime_full_format.') AS created,
       TO_CHAR(o.last_ddl_time, '&&cs_datetime_full_format.') AS last_ddl_time,
       TO_CHAR(o.analyzetime, '&&cs_datetime_full_format.') AS analyzetime,
       TO_CHAR(o.savtime, '&&cs_timestamp_full_format.') AS savtime,
       o.rowcnt,
       o.blkcnt,
       o.avgrln,
       o.samplesize
     --   o.rn
  FROM dba_tables_o o
 WHERE o.rn <= 100
--    AND h.analyzetime IS NOT NULL
 ORDER BY 1, 2, 3, 4, 5, 6 NULLS FIRST, 7 NULLS FIRST
       --o.object_type,
     --   o.owner,
     --   o.object_name,
     --   o.object_id,
     --   o.created,
     --   o.last_ddl_time,
     --   o.analyzetime NULLS FIRST,
     --   o.savtime NULLS FIRST
-- FETCH FIRST 1000 ROWS ONLY       
/
--
CLEAR BREAK;
