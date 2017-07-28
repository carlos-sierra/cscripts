WITH 
tables AS (
SELECT 'TABLE' seg_type, owner, table_name name
  FROM dba_tables
 WHERE table_name LIKE '%'||UPPER(TRIM('&&table_name.'))||'%'
),
indexes AS (
SELECT 'INDEX' seg_type, i.owner, i.index_name name
  FROM dba_indexes i, tables t
 WHERE i.table_owner = t.owner
   AND i.table_name = t.name
),
objects AS (
SELECT * FROM tables
UNION ALL
SELECT * FROM indexes
)
SELECT s.owner||'.'||s.segment_name||' '||s.partition_name||'('||s.segment_type||') '||ROUND(s.bytes/POWER(2,20),3)||'MB' schema_object
  FROM dba_segments s, objects o
 WHERE s.owner = o.owner
   AND s.segment_name = o.name
   AND s.segment_type LIKE '%'||o.seg_type||'%'
/


WITH 
block AS (
SELECT TO_NUMBER(value) bsize FROM v$parameter WHERE name = 'db_block_size'
),
tables AS (
SELECT owner, table_name
  FROM dba_tables
 WHERE table_name LIKE '%'||UPPER(TRIM('&&table_name.'))||'%'
)
SELECT s.owner||'.'||s.table_name||'.'||s.partition_name||'.'||s.subpartition_name||'('||s.object_type||') '||ROUND(s.blocks*block.bsize/POWER(2,20),3)||'MB' size_per_stats
  FROM dba_tab_statistics s, tables t, block
 WHERE s.owner = t.owner
   AND s.table_name = t.table_name
 UNION ALL
SELECT s.owner||'.'||s.index_name||'.'||s.partition_name||'.'||s.subpartition_name||'('||s.object_type||') '||ROUND(s.leaf_blocks*block.bsize/POWER(2,20),3)||'MB' size_per_stats
  FROM dba_ind_statistics s, tables t, block
 WHERE s.owner = t.owner
   AND s.table_name = t.table_name
/

