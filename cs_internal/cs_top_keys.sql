PRO
PRO TOP_KEYS (if dba_tables.num_rows < 25MM)
PRO ~~~~~~~~
--
SET HEA OFF;
CLEAR COL;
COL row_count FOR 999,999,990 HEA 'Row Count';
COL avg_version_age_seconds FOR 999,999,990.000 HEA 'Version Avg|Age Seconds';
COL p50_version_age_seconds FOR 999,999,999,990 HEA 'Version p50|Age Seconds';
COL min_version_age_seconds FOR 999,999,999,990 HEA 'Version Min|Age Seconds';
COL max_version_age_seconds FOR 999,999,999,990 HEA 'Version Max|Age Seconds';
COL kievlive_y FOR 999,999,990 HEA 'KievLive|"Y"';
COL kievlive_n  FOR 999,999,990 HEA 'KievLive|"N"';
--
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
   AND t.num_rows < 25e6
)
--SELECT 'PRO'||CHR(10)||'PRO FROM INDEX '||i.owner||'.'||i.index_name||'('||LISTAGG(c.column_name, ',' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||')'||CHR(10)||'PRO ~~~~~~~~~~'||CHR(10)||
--       'SELECT COUNT(*), '||CASE '&&cs_kiev_version.' WHEN 'NOT_KIEV' THEN NULL ELSE 'SUM(CASE WHEN kievlive = ''Y'' THEN 1 ELSE 0 END) AS kievlive_y, SUM(CASE WHEN kievlive = ''N'' THEN 1 ELSE 0 END) AS kievlive_n,' END||
--       LISTAGG(c.column_name, ',' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||' FROM '||i.table_owner||'.'||i.table_name||' GROUP BY '||
--       LISTAGG(c.column_name, ',' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||' ORDER BY 1 DESC FETCH FIRST 30 ROWS ONLY;'
SELECT 'PRO'||CHR(10)||'PRO FROM TABLE AND INDEX '||i.table_owner||'.'||i.table_name||' '||i.owner||'.'||i.index_name||'('||LISTAGG(c.column_name, ',' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||')'||CHR(10)||'PRO ~~~~~~~~~~~~~~~~~~~~'||CHR(10)||
       CASE '&&cs_kiev_version.' WHEN 'NOT_KIEV' THEN
       'WITH bucket AS (SELECT '||CHR(10)||
       LISTAGG('T.'||c.column_name, ',' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||'  FROM '||i.table_owner||'.'||i.table_name||' T)'       
       ELSE
       'WITH bucket AS (SELECT CAST(K.BEGINTIME AS DATE) AS begin_date, (CAST(K.BEGINTIME AS DATE) - LAG(CAST(K.BEGINTIME AS DATE)) OVER (PARTITION BY '||CHR(10)||
       LISTAGG('T.'||c.column_name, ',' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||' ORDER BY T.KIEVTXNID)) * 24 * 3600 AS lag_secs,T.kievlive,'||CHR(10)||
       LISTAGG('T.'||c.column_name, ',' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||'  FROM '||i.table_owner||'.'||i.table_name||' T, '||i.table_owner||'.KIEVTRANSACTIONS K WHERE K.COMMITTRANSACTIONID(+) = T.KIEVTXNID)'
       END||CHR(10)||
       'SELECT COUNT(*) AS row_count, '||CASE '&&cs_kiev_version.' WHEN 'NOT_KIEV' THEN NULL ELSE 'ROUND(AVG(lag_secs),3) AS avg_version_age_seconds, PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY lag_secs) AS p50_version_age_seconds, MIN(lag_secs) AS min_version_age_seconds, MAX(lag_secs) AS max_version_age_seconds, MIN(begin_date) AS min_date, MAX(begin_date) AS max_date, SUM(CASE WHEN kievlive = ''Y'' THEN 1 ELSE 0 END) AS kievlive_y, SUM(CASE WHEN kievlive = ''N'' THEN 1 ELSE 0 END) AS kievlive_n,' END||
       LISTAGG(c.column_name, ',' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||' FROM bucket GROUP BY '||
       LISTAGG(c.column_name, ',' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY c.column_position)||' ORDER BY 1 DESC FETCH FIRST 30 ROWS ONLY;'
       AS dynamic_sql
  FROM dba_tables_m t,
       dba_indexes i,
       dba_ind_columns c
 WHERE t.table_name NOT LIKE 'KIEV%'
   AND i.table_owner = t.owner
   AND i.table_name = t.table_name
   AND i.index_type = 'NORMAL'
   --AND i.uniqueness = 'UNIQUE'
   AND c.index_owner = i.owner
   AND c.index_name = i.index_name
   AND c.column_name <> 'KIEVTXNID'
   AND c.column_name <> 'KIEVLIVE'
 GROUP BY
       i.table_owner,
       i.table_name,
       i.owner,
       i.index_name
 ORDER BY
       i.table_owner,
       i.table_name,
       i.owner,
       i.index_name
/
--
SPO OFF;
SET HEA ON;
--
SPO &&cs_file_name..txt APP
@/tmp/cs_driver.sql;

