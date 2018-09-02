COL owner FOR A30 HEA 'Owner';
COL table_name FOR A30 HEA 'Table Name';
COL partitioned FOR A4 HEA 'Part';
COL degree FOR A10 HEA 'Degree';
COL temporary FOR A4 HEA 'Temp';
COL blocks FOR 999,999,990 HEA 'Blocks';
COL num_rows FOR 999,999,999,990 HEA 'Num Rows';
COL avg_row_len FOR 999,999,990 HEA 'Avg Row Len';
COL sample_size FOR 999,999,999,990 HEA 'Sample Size';
COL last_analyzed FOR A19 HEA 'Last Analyzed';
COL compression FOR A12 HEA 'Compression';
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
       t.table_name, 
       t.partitioned,
       t.degree,
       t.temporary,
       t.blocks,
       t.num_rows, 
       t.avg_row_len,
       t.sample_size,
       t.last_analyzed,
       t.compression
  FROM dba_tables t,
       v_db_object_cache_m c
 WHERE t.owner = c.object_owner
   AND t.table_name = c.object_name 
)
SELECT /*+ QB_NAME(get_stats) */
       owner, 
       table_name, 
       partitioned,
       degree,
       temporary,
       blocks,
       num_rows,
       avg_row_len, 
       sample_size,
       TO_CHAR(last_analyzed, '&&cs_datetime_full_format.') last_analyzed,
       compression
  FROM dba_tables_m
 ORDER BY
       owner,
       table_name
/
--