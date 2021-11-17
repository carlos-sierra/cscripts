SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0;
--
DEF cs2_owner = '';
DEF cs2_table_name = '';
COL cs2_owner NEW_V cs2_owner NOPRI;
COL cs2_table_name NEW_V cs2_table_name NOPRI;
SELECT owner AS cs2_owner, table_name AS cs2_table_name FROM dba_tables WHERE table_name LIKE 'KIEVGCEVENTS_PART%' ORDER BY last_analyzed DESC NULLS LAST FETCH FIRST 1 ROW ONLY
/ 
--
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_is_primary VARCHAR2(5);
BEGIN
  IF '&&cs2_owner.' IS NULL THEN raise_application_error(-20000, 'Not KIEV'); END IF;
  SELECT CASE WHEN open_mode = 'READ WRITE' AND database_role = 'PRIMARY' THEN 'TRUE' ELSE 'FALSE' END AS is_primary INTO l_is_primary FROM v$database;
  IF l_is_primary = 'FALSE' THEN raise_application_error(-20000, 'Not PRIMARY'); END IF;
END;
/
-- cs_kiev_gc_status.sql -- begin
WITH 
kiev_buckets AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       name AS bucketname
  FROM &&cs2_owner..kievbuckets
),
kiev_events AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       eventtime, bucketname, TO_NUMBER(DBMS_LOB.substr(message, DBMS_LOB.instr(message, ' rows were deleted') - 1)) AS rows_deleted,
       ROW_NUMBER() OVER (PARTITION BY bucketname ORDER BY eventtime DESC NULLS LAST) AS rn
  FROM &&cs2_owner..&&cs2_table_name. 
 WHERE gctype = 'BUCKET'
   AND DBMS_LOB.instr(message, ' rows were deleted') > 0
),
tables AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       table_name, num_rows, avg_row_len, blocks, last_analyzed
  FROM dba_tables
 WHERE owner = '&&cs2_owner.'
   AND table_name IN (SELECT UPPER(bucketname) FROM kiev_buckets WHERE partitioned = 'NO')
),
modifications AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       table_name, timestamp, inserts, deletes
  FROM dba_tab_modifications
 WHERE table_owner = '&&cs2_owner.'
   AND table_name IN (SELECT UPPER(bucketname) FROM kiev_buckets WHERE partition_name IS NULL)
),
histogram AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       table_name,
       SUBSTR(UTL_RAW.CAST_TO_VARCHAR2(SUBSTR(LPAD(TO_CHAR(endpoint_value,'fmxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'),30,'0'),1,12)), 1, 1) kievlive,
       endpoint_number,
       endpoint_number - LAG(endpoint_number, 1, 0) OVER (PARTITION BY table_name ORDER BY endpoint_value) value_count,
       MAX(endpoint_number) OVER (PARTITION BY table_name) max_endpoint_number
  FROM dba_tab_histograms
 WHERE owner = '&&cs2_owner.'
   AND table_name IN (SELECT UPPER(bucketname) FROM kiev_buckets)
   AND column_name = 'KIEVLIVE'
),
summary AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       b.bucketname, 
       MAX(t.last_analyzed) AS last_analyzed,
       MAX(t.num_rows) AS num_rows,
       MAX(t.avg_row_len) AS avg_row_len,
       MAX(t.blocks) AS blocks,
       MAX(m.timestamp) AS last_modified,
       MAX(m.inserts) AS inserts,
       MAX(m.deletes) AS deletes,
       MAX(100 * ky.value_count / ky.max_endpoint_number) AS ky_perc,
       MAX(100 * kn.value_count / kn.max_endpoint_number) AS kn_perc,
       MIN(e.eventtime) AS min_eventtime, 
       MAX(e.eventtime) AS max_eventtime, 
       ROUND(CAST(MAX(e.eventtime) AS DATE) - CAST(MIN(e.eventtime) AS DATE), 1) AS days,
       SUM(rows_deleted) AS rows_deleted_tot, 
       SUM(CASE WHEN rows_deleted > 0 THEN 1 ELSE 0 END) AS executions, 
       ROUND(SUM(e.rows_deleted) / COUNT(*)) AS del_per_exec,
       MAX(e.rows_deleted) AS max_delete,
       SUM(CASE WHEN e.rn = 1 THEN e.rows_deleted ELSE 0 END) AS rows_deleted_last,
       24 * (SYSDATE - CAST(MAX(e.eventtime) AS DATE)) * 60 AS gc_minutes
  FROM kiev_buckets b,
       tables t,
       modifications m,
       histogram ky,
       histogram kn,
       kiev_events e
 WHERE t.table_name = UPPER(b.bucketname)
   AND m.table_name(+) = t.table_name
   AND ky.table_name(+) = t.table_name
   AND ky.kievlive(+) = 'Y'
   AND kn.table_name(+) = t.table_name
   AND kn.kievlive(+) = 'N'
   AND e.bucketname(+) = b.bucketname
 GROUP BY
       b.bucketname
),
extended AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       bucketname, 
       last_analyzed,
       num_rows,
       avg_row_len,
       blocks,
       last_modified,
       inserts,
       deletes,
       ky_perc,
       kn_perc,
       min_eventtime, 
       max_eventtime, 
       days,
       rows_deleted_tot, 
       ROUND(num_rows * days * 24 / rows_deleted_tot, 1) AS turn_around_hours,
       executions, 
       del_per_exec,
       max_delete,
       rows_deleted_last,
       gc_minutes,
       CASE
       WHEN gc_minutes < 6 * 60 THEN 'ACTIVE'
       WHEN last_analyzed < SYSDATE - 30 AND (last_modified IS NULL OR last_modified < SYSDATE - 30) AND days IS NULL THEN 'UNCHANGED'
       WHEN num_rows < 1000 THEN 'SMALL'
       WHEN ky_perc = 100 THEN 'NO TOMBSTONE'
       WHEN gc_minutes > 12 * 60 THEN 'NO GC'
       ELSE 'UNKNOWN'
       END AS gc_status
  FROM summary
)
-- cs_kiev_gc_status.sql -- end
, tab_summary AS (
SELECT gc_status,
       COUNT(*) AS tables,
       SUM(num_rows) AS num_rows,
       SUM(blocks) AS blocks
  FROM extended
 GROUP BY
       gc_status
), tab_summary2 AS (
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD') AS version,
       p.value AS db_domain,
       d.name AS db_name,
       c.name AS pdb_name,
       i.host_name,
       s.gc_status,
       s.tables,
       s.num_rows,
       s.blocks
  FROM tab_summary s, v$containers c, v$instance i, v$database d, v$parameter p
 WHERE p.name = 'db_domain'
   AND num_rows > 0
   AND blocks > 0
)
SELECT 'EXEC c##iod.merge_gc_status('||
        ''''||s.version||''','||
        ''''||s.db_domain||''','||
        ''''||s.db_name||''','||
        ''''||s.pdb_name||''','||
        ''''||s.host_name||''','||
        ''''||s.gc_status||''','||
        ''''||s.tables||''','||
        ''''||s.num_rows||''','||
        ''''||s.blocks||''');' AS line
  FROM tab_summary2 s
 ORDER BY
       s.gc_status
/
--