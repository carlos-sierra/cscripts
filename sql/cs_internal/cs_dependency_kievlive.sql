COL owner FOR A30 HEA 'Owner';
COL table_name FOR A30 HEA 'Table Name';
COL num_rows FOR 999,999,999,990 HEA 'Num Rows';
COL kievlive FOR A8 HEA 'KievLive';
--
PRO
PRO KIEV LIVE (dba_tab_histograms)
PRO ~~~~~~~~~
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
       h.owner, 
       h.table_name,
       SUBSTR(UTL_RAW.CAST_TO_VARCHAR2(SUBSTR(LPAD(TO_CHAR(h.endpoint_value,'fmxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'),30,'0'),1,12)), 1, 8) kievlive,
       h.endpoint_number - LAG(h.endpoint_number, 1, 0) OVER (ORDER BY h.endpoint_value) num_rows
  FROM dba_tables_m t,
       dba_tab_histograms h
 WHERE h.owner = t.owner
   AND h.table_name = t.table_name
   AND h.column_name = 'KIEVLIVE'
 ORDER BY
       1, 2, 3
/
--