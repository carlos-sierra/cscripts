PRO
PRO TOP_KEYS
PRO ~~~~~~~~
--
SET HEA OFF;
SPO /tmp/cs_driver.sql;
--
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
SELECT 'SELECT COUNT(*), SUM(CASE WHEN kievlive = ''Y'' THEN 1 ELSE 0 END) kievlive_y, SUM(CASE WHEN kievlive = ''N'' THEN 1 ELSE 0 END) kievlive_n, '||
       LISTAGG(c.column_name, ',') WITHIN GROUP (ORDER BY c.column_position)||' FROM '||t.owner||'.'||t.table_name||' GROUP BY '||
       LISTAGG(c.column_name, ',') WITHIN GROUP (ORDER BY c.column_position)||' ORDER BY 1 DESC, 2 DESC, 3 DESC FETCH FIRST 10 ROWS ONLY;' dynamic_sql
  FROM dba_tables_m t,
       dba_indexes i,
       dba_ind_columns c
 WHERE i.table_owner = t.owner
   AND i.table_name = t.table_name
   AND i.index_type = 'NORMAL'
   --AND i.uniqueness = 'UNIQUE'
   AND c.index_owner = i.owner
   AND c.index_name = i.index_name
   AND c.column_name <> 'KIEVTXNID'
 GROUP BY
       t.owner,
       t.table_name,
       i.owner,
       i.index_name
/
SPO OFF;
SET HEA ON;
--
SPO &&cs_file_name..txt APP
@/tmp/cs_driver.sql;

