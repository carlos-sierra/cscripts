WITH 
relevant_segments AS (
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       s.con_id,
       s.owner,
       s.segment_name,
       s.partition_name,
       s.segment_type,
       s.tablespace_name,
       s.bytes,
       s.blocks,
       CASE
         WHEN s.segment_type LIKE 'TABLE%' THEN t.num_rows
       END AS num_rows,
       CASE 
         WHEN s.segment_type LIKE 'TABLE%' THEN s.segment_name
         WHEN s.segment_type LIKE 'LOB%' AND s.segment_type <> 'LOBINDEX' THEN l.table_name
         WHEN s.segment_type LIKE 'INDEX%' OR s.segment_type = 'LOBINDEX' THEN i.table_name
       END AS table_name,
       CASE 
         WHEN s.segment_type LIKE 'LOB%' AND s.segment_type <> 'LOBINDEX' THEN l.index_name
         WHEN s.segment_type LIKE 'INDEX%' OR s.segment_type = 'LOBINDEX' THEN i.index_name
       END AS index_name,
       CASE 
         WHEN s.segment_type LIKE 'LOB%' AND s.segment_type <> 'LOBINDEX' THEN l.column_name
       END AS column_name
  FROM cdb_users u,
       cdb_segments s,
       cdb_tables t,
       cdb_lobs l,
       cdb_indexes i 
 WHERE u.oracle_maintained = 'N'
   AND u.common = 'NO'
   AND s.con_id = u.con_id
   AND s.owner = u.username
   AND s.bytes > 0
   AND s.blocks > 0
   AND (s.segment_type LIKE 'TABLE%' OR s.segment_type LIKE 'LOB%' OR s.segment_type LIKE 'INDEX%')
   AND t.con_id(+) = s.con_id
   AND t.owner(+) = s.owner
   AND t.table_name(+) = s.segment_name
   AND l.con_id(+) = s.con_id
   AND l.owner(+) = s.owner
   AND l.segment_name(+) = s.segment_name
   AND i.con_id(+) = s.con_id
   AND i.owner(+) = s.owner
   AND i.index_name(+) = s.segment_name
),
aggregated_segments AS (
SELECT s.con_id,
       s.owner,
       s.segment_name,
       1 AS segments,
       s.partition_name,
       s.segment_type,
       s.tablespace_name,
       s.bytes,
       s.blocks,
       s.num_rows,
       s.table_name,
       s.index_name,
       s.column_name
  FROM relevant_segments s
 WHERE s.bytes >= POWER(10, 7) -- include segments >= 10MB
   AND s.segment_name NOT LIKE 'BIN$%==$0' -- exclude recycle bin segments 
 UNION ALL
SELECT s.con_id,
       s.owner,
       'segments_under_10mb' AS segment_name,
       COUNT(*) AS segments,
       NULL AS partition_name,
       s.segment_type,
       s.tablespace_name,
       SUM(s.bytes) AS bytes,
       SUM(s.blocks) AS blocks,
       TO_NUMBER(NULL) AS num_rows,
       NULL AS table_name,
       NULL AS index_name,
       NULL AS column_name
  FROM relevant_segments s
 WHERE s.bytes < POWER(10, 7) -- include segments < 10MB
   AND s.segment_name NOT LIKE 'BIN$%==$0' -- exclude recycle bin segments 
 GROUP BY
       s.con_id,
       s.owner,
       s.segment_type,
       s.tablespace_name
 UNION ALL
SELECT s.con_id,
       s.owner,
       'recycle_bin_segments' AS segment_name,
       COUNT(*) AS segments,
       NULL AS partition_name,
       s.segment_type,
       s.tablespace_name,
       SUM(s.bytes) AS bytes,
       SUM(s.blocks) AS blocks,
       TO_NUMBER(NULL) AS num_rows,
       NULL AS table_name,
       NULL AS index_name,
       NULL AS column_name
  FROM relevant_segments s
 WHERE s.segment_name LIKE 'BIN$%==$0' -- include recycle bin segments 
 GROUP BY
       s.con_id,
       s.owner,
       s.segment_type,
       s.tablespace_name
)
SELECT s.con_id,
       s.owner,
       s.segment_name,
       s.segments,
       s.partition_name,
       s.segment_type,
       s.tablespace_name,
       s.bytes,
       s.blocks,
       s.num_rows,
       s.table_name,
       s.index_name,
       s.column_name
  FROM aggregated_segments s
/
