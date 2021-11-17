----------------------------------------------------------------------------------------
--
-- File name:   cs_kiev_pdb_gc_status.sql
--
-- Purpose:     KIEV PDB Garbage Collection (GC) status
--
-- Author:      Carlos Sierra
--
-- Version:     2021/09/30
--
-- Usage:       Execute connected to PDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kiev_pdb_gc_status.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_kiev_pdb_gc_status';
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
COL cs2_owner NEW_V cs2_owner NOPRI;
COL cs2_table_name NEW_V cs2_table_name NOPRI;
SELECT owner AS cs2_owner, table_name AS cs2_table_name FROM dba_tables WHERE table_name LIKE 'KIEVGCEVENTS_PART%' ORDER BY last_analyzed DESC NULLS LAST FETCH FIRST 1 ROW ONLY
/ 
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql
@@cs_internal/cs_spool_id.sql
--
COL bucketname FOR A30 HEA 'Table Name' TRUNC;
COL blocks FOR 999,999,990 HEA 'Blocks';
COL avg_row_len FOR 9,990 HEA 'Avg|Row|Len';
COL num_rows FOR 999,999,999,990 HEA 'Rows in Table';
COL last_analyzed FOR A19 HEA 'Last Analyzed' TRUNC;
COL last_modified FOR A19 HEA 'Last Modified' TRUNC;
COL inserts FOR 999,999,999,990 HEA 'Approx Rows Inserted|between Last Analyzed|and Last Modified';
COL deletes FOR 999,999,999,990 HEA 'Approx Rows Deleted|between Last Analyzed|and Last Modified';
COL ky_perc FOR 999,990.0 HEA 'KIEV Live|Value "Y"|Percent %';
COL kn_perc FOR 999,990.0 HEA 'KIEV Live|Value "N"|Percent %';
COL min_eventtime FOR A19 HEA 'Begin Time|GC Event|History' TRUNC;
COL max_eventtime FOR A19 HEA 'End Time|GC Event|History' TRUNC;
COL days FOR 90.0 HEA 'GC Events|Hist Days|Available';
COL rows_deleted_tot FOR 999,999,999,990 HEA 'Rows Deleted|during GC Events|Hist Days';
COL turn_around_hours FOR 999,990.0 HEA 'Turnaround|Hours';
COL executions FOR 999,990 HEA 'GC Executions|during Events|Hist Days';
COL del_per_exec FOR 999,999,990 HEA 'Avg Deletes|per GC Exec';
COL max_delete FOR 999,999,990 HEA 'Max Deletes|by one GC Exec';
COL gc_minutes FOR 999,990.0 HEA 'Last GC|Age in|Minutes';
COL rows_deleted_last FOR 999,999,990 HEA 'Deleted|on last|GC Event';
COL gc_status_p FOR A20 HEA 'GC Status';
--
BREAK ON gc_status_p SKIP PAGE DUPL;
COMPUTE SUM OF blocks num_rows inserts deletes rows_deleted_tot executions rows_deleted_last ON gc_status_p;
--
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
       WHEN num_rows < 1000 THEN '6. SMALL TABLE'
       WHEN last_analyzed < SYSDATE - 30 AND (last_modified IS NULL OR last_modified < SYSDATE - 30) AND days IS NULL THEN '3. STATIC TABLE'
       WHEN ky_perc = 100 AND deletes > 0 THEN '2. NO TOMBSTONE(**)' -- only outdated versions older than gc horizon are purged
       WHEN ky_perc = 100 AND NVL(deletes, 0) = 0 THEN '1. NO TOMBSTONE(*)' -- no customer logical deletes and no purging of outdated versions older than gc horizon
       WHEN gc_minutes < 6 * 60 THEN '5. ACTIVE KIEV GC'
       WHEN gc_minutes >= 12 * 60 THEN '4. INACTIVE KIEV GC'
       ELSE '7. UNKNOWN GC STATUS'
       END AS gc_status
  FROM summary
)
SELECT SUBSTR(gc_status, 4) AS gc_status_p,
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
       turn_around_hours,
       executions, 
       del_per_exec,
       max_delete,
       rows_deleted_last,
       gc_minutes
  FROM extended
 ORDER BY
       gc_status,
       blocks DESC NULLS LAST,
       bucketname
/
PRO
PRO Notes: (*) no customer logical deletes and no purging of outdated versions older than gc horizon. (**) only outdated versions older than gc horizon are purged.
--
CLEAR BREAK COMPUTE;
--
COL last_gc_execution FOR A19 HEA 'Last GC Execution' TRUNC;
COL gc_age FOR 999,990.0 HEA 'GC Age Minutes';
--
SELECT MAX(eventtime) AS last_gc_execution, 24 * (SYSDATE - CAST(MAX(eventtime) AS DATE)) * 60 AS gc_age
  FROM &&cs2_owner..&&cs2_table_name. 
 WHERE gctype = 'BUCKET'
   AND DBMS_LOB.instr(message, ' rows were deleted') > 0
/
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--