SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

CLEAR BREAK COMPUTE;

ALTER SESSION SET CONTAINER = CDB$ROOT;

PRO
PRO Containers
PRO ~~~~~~~~~~
SELECT COUNT(*) FROM v$containers WHERE con_id <> 2;

PRO
PRO CDB APPL Totals
PRO ~~~~~~~~~~~~~~~
WITH
t AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       SUM(NVL(bytes, 0)) bytes
  FROM cdb_data_files
 GROUP BY 
       con_id,
       tablespace_name
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       SUM(NVL(bytes, 0)) bytes
  FROM cdb_temp_files
 GROUP BY 
       con_id,
       tablespace_name
),
u AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       SUM(bytes) bytes
  FROM cdb_free_space
 GROUP BY 
        con_id,
        tablespace_name
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       NVL(SUM(bytes_used), 0) bytes
  FROM gv$temp_extent_pool
 GROUP BY 
       con_id,
       tablespace_name
),
un AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ts.con_id,
       ts.tablespace_name,
       NVL(um.used_space * ts.block_size, 0) bytes
  FROM cdb_tablespaces              ts,
       cdb_tablespace_usage_metrics um
 WHERE ts.contents           = 'UNDO'
   AND um.tablespace_name(+) = ts.tablespace_name
   AND um.con_id(+)          = ts.con_id
),
oem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ts.con_id,
       pdb.name pdb_name,
       ts.tablespace_name,
       ts.contents,
       ts.block_size,
       NVL(t.bytes / POWER(2,20), 0) allocated_space, -- MBs
       NVL(
       CASE ts.contents
       WHEN 'UNDO'         THEN un.bytes
       WHEN 'PERMANENT'    THEN t.bytes - NVL(u.bytes, 0)
       WHEN 'TEMPORARY'    THEN
         CASE ts.extent_management
         WHEN 'LOCAL'      THEN u.bytes
         WHEN 'DICTIONARY' THEN t.bytes - NVL(u.bytes, 0)
         END
       END 
       / POWER(2,20), 0) used_space -- MBs
  FROM cdb_tablespaces ts,
       v$containers    pdb,
       t,
       u,
       un
 WHERE 1 = 1
   AND ts.contents           = 'PERMANENT'
   AND ts.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND pdb.con_id            = ts.con_id
   AND t.tablespace_name(+)  = ts.tablespace_name
   AND t.con_id(+)           = ts.con_id
   AND u.tablespace_name(+)  = ts.tablespace_name
   AND u.con_id(+)           = ts.con_id
   AND un.tablespace_name(+) = ts.tablespace_name
   AND un.con_id(+)          = ts.con_id
)
SELECT --o.con_id,
       --o.pdb_name,
       --o.tablespace_name,
       --o.contents,
       --o.block_size,
       COUNT(*) tablespaces,
       ROUND(SUM(o.allocated_space) / POWER(2, 20), 3) oem_allocated_space_tbs,
       ROUND(SUM(o.used_space) / POWER(2, 20), 3) oem_used_space_tbs,
       --ROUND(100 * SUM(o.used_space) / SUM(o.allocated_space), 3) oem_used_percent, -- as per allocated space
       ROUND(SUM(m.tablespace_size * o.block_size) / POWER(2, 40), 3) met_max_size_tbs
       --ROUND(SUM(m.used_space * o.block_size) / POWER(2, 40), 3) met_used_space_tbs
  FROM oem                          o,
       cdb_tablespace_usage_metrics m
 WHERE m.tablespace_name(+) = o.tablespace_name
   AND m.con_id(+)          = o.con_id
/

PRO
PRO CDB Totals
PRO ~~~~~~~~~~
WITH
t AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       SUM(NVL(bytes, 0)) bytes
  FROM cdb_data_files
 GROUP BY 
       con_id,
       tablespace_name
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       SUM(NVL(bytes, 0)) bytes
  FROM cdb_temp_files
 GROUP BY 
       con_id,
       tablespace_name
),
u AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       SUM(bytes) bytes
  FROM cdb_free_space
 GROUP BY 
        con_id,
        tablespace_name
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id,
       tablespace_name,
       NVL(SUM(bytes_used), 0) bytes
  FROM gv$temp_extent_pool
 GROUP BY 
       con_id,
       tablespace_name
),
un AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ts.con_id,
       ts.tablespace_name,
       NVL(um.used_space * ts.block_size, 0) bytes
  FROM cdb_tablespaces              ts,
       cdb_tablespace_usage_metrics um
 WHERE ts.contents           = 'UNDO'
   AND um.tablespace_name(+) = ts.tablespace_name
   AND um.con_id(+)          = ts.con_id
),
oem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ts.con_id,
       pdb.name pdb_name,
       ts.tablespace_name,
       ts.contents,
       ts.block_size,
       NVL(t.bytes / POWER(2,20), 0) allocated_space, -- MBs
       NVL(
       CASE ts.contents
       WHEN 'UNDO'         THEN un.bytes
       WHEN 'PERMANENT'    THEN t.bytes - NVL(u.bytes, 0)
       WHEN 'TEMPORARY'    THEN
         CASE ts.extent_management
         WHEN 'LOCAL'      THEN u.bytes
         WHEN 'DICTIONARY' THEN t.bytes - NVL(u.bytes, 0)
         END
       END 
       / POWER(2,20), 0) used_space -- MBs
  FROM cdb_tablespaces ts,
       v$containers    pdb,
       t,
       u,
       un
 WHERE 1 = 1
   AND pdb.con_id            = ts.con_id
   AND t.tablespace_name(+)  = ts.tablespace_name
   AND t.con_id(+)           = ts.con_id
   AND u.tablespace_name(+)  = ts.tablespace_name
   AND u.con_id(+)           = ts.con_id
   AND un.tablespace_name(+) = ts.tablespace_name
   AND un.con_id(+)          = ts.con_id
)
SELECT --o.con_id,
       --o.pdb_name,
       --o.tablespace_name,
       --o.contents,
       --o.block_size,
       COUNT(*) tablespaces,
       ROUND(SUM(o.allocated_space) / POWER(2, 20), 3) oem_allocated_space_tbs,
       ROUND(SUM(o.used_space) / POWER(2, 20), 3) oem_used_space_tbs,
       --ROUND(100 * SUM(o.used_space) / SUM(o.allocated_space), 3) oem_used_percent, -- as per allocated space
       ROUND(SUM(m.tablespace_size * o.block_size) / POWER(2, 40), 3) met_max_size_tbs
       --ROUND(SUM(m.used_space * o.block_size) / POWER(2, 40), 3) met_used_space_tbs
  FROM oem                          o,
       cdb_tablespace_usage_metrics m
 WHERE m.tablespace_name(+) = o.tablespace_name
   AND m.con_id(+)          = o.con_id
/

PRO
PRO KIEVTRANSACTIONS_AK2
PRO ~~~~~~~~~~~~~~~~~~~~
SELECT ROUND(SUM(blocks) * 8 / POWER(2, 30), 3) size_tbs
  FROM cdb_segments
 WHERE segment_name = 'KIEVTRANSACTIONS_AK2'
/

@clean.sql
HOS rm *.sql
QUIT