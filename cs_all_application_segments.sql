WITH relevant_segments AS (
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
)
-- SELECT s.con_id,
--        s.owner,
--        s.segment_name,
--        s.partition_name,
--        s.segment_type,
--        s.tablespace_name,
--        s.bytes,
--        s.blocks,
--        s.num_rows,
--        s.table_name,
--        s.index_name,
--        s.column_name
--   FROM relevant_segments s
--  WHERE s.con_id = 3
--    AND s.table_name = 'ROUTE_TABLES_AD'
SELECT COUNT(*) AS cnt, SUM(bytes) AS bytes, 
       PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY bytes) AS pctl_50, 
       PERCENTILE_DISC(0.70) WITHIN GROUP (ORDER BY bytes) AS pctl_70, 
       PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY bytes) AS pctl_75, 
       PERCENTILE_DISC(0.80) WITHIN GROUP (ORDER BY bytes) AS pctl_80, 
       PERCENTILE_DISC(0.85) WITHIN GROUP (ORDER BY bytes) AS pctl_85, 
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY bytes) AS pctl_90, 
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY bytes) AS pctl_95, 
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY bytes) AS pctl_99,
       MAX(bytes) AS pctl_100
  FROM relevant_segments
/