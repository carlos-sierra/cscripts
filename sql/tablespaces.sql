WITH
files AS (
SELECT tablespace_name,
       SUM(DECODE(autoextensible, 'YES', maxbytes, bytes)) / POWER(10,9) Max_size_gb,
       SUM( bytes) / POWER(10,9) Size_gb
  FROM dba_data_files
 GROUP BY
       tablespace_name
),
segments AS (
SELECT tablespace_name,
       SUM(bytes) / POWER(10,9) used_gb
  FROM dba_segments
 GROUP BY
       tablespace_name
),
tablespaces AS (
SELECT files.tablespace_name,
       ROUND(files.size_gb, 1) size_gb,
       ROUND(segments.used_gb, 1) used_gb,
       ROUND(100 * segments.used_gb / files.size_gb, 1) pct_used,
       ROUND(files.max_size_gb, 1) max_size_gb
  FROM files,
       segments
 WHERE files.size_gb > 0
   AND files.tablespace_name = segments.tablespace_name(+)
 ORDER BY
       files.tablespace_name
),
total AS (
SELECT 'Total' tablespace_name,
       SUM(size_gb) size_gb,
       SUM(used_gb) used_gb,
       ROUND(100 * SUM(used_gb) / SUM(size_gb), 1) pct_used,
       sum(max_size_gb) max_size_gb
  FROM tablespaces
)
SELECT tablespace_name,
       size_gb,
       used_gb,
       pct_used,
       max_size_gb
  FROM tablespaces
 UNION ALL
SELECT tablespace_name,
       size_gb,
       used_gb,
       pct_used,
       max_size_gb
  FROM total
/