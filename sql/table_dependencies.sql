WITH
v_sqlarea_m AS (
SELECT /*+ MATERIALIZE NO_MERGE */ con_id, hash_value, address FROM v$sqlarea WHERE sql_id = '&&sql_id.'
),
v_object_dependency_m AS (
SELECT /*+ MATERIALIZE NO_MERGE */ con_id, to_hash, to_address FROM v$object_dependency WHERE (con_id, from_hash, from_address) IN (SELECT con_id, hash_value, address FROM v_sqlarea_m)
),
v_db_object_cache_m AS (
SELECT /*+ MATERIALIZE NO_MERGE */ con_id, SUBSTR(owner,1,30) object_owner, SUBSTR(name,1,30) object_name FROM v$db_object_cache WHERE type IN ('TABLE','VIEW') AND (con_id, hash_value, addr) IN (SELECT con_id, to_hash, to_address FROM v_object_dependency_m)
),
cdb_tables_m AS (
SELECT /*+ MATERIALIZE NO_MERGE */ owner, table_name, num_rows, last_analyzed, ROW_NUMBER() OVER (ORDER BY num_rows DESC NULLS LAST) row_number FROM cdb_tables WHERE (con_id, owner, table_name) IN (SELECT con_id, object_owner, object_name FROM v_db_object_cache_m)
)
SELECT * FROM cdb_tables_m
/
