----------------------------------------------------------------------------------------
--
-- File name:   cs_table.sql
--
-- Purpose:     Table Details
--
-- Author:      Carlos Sierra
--
-- Version:     2022/03/01
--
-- Usage:       Execute connected to PDB.
--
--              Enter table owner and table name when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_table.sql
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
DEF cs_script_name = 'cs_table';
--
COL owner NEW_V owner FOR A30 HEA 'TABLE_OWNER';
SELECT DISTINCT t.owner
  FROM dba_tables t,
       dba_users u
 WHERE u.username = t.owner
   AND u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
 ORDER BY 1
/
COL table_owner NEW_V table_owner FOR A30;
PRO
PRO 1. Table Owner:
DEF table_owner = '&1.';
UNDEF 1;
SELECT UPPER(TRIM(NVL('&&table_owner.', '&&owner.'))) table_owner FROM DUAL
/
--
COL name NEW_V name FOR A30 HEA 'TABLE_NAME';
COL num_rows FOR 99,999,999,990;
COL blocks FOR 99,999,999,990;
COL rows_per_block FOR 999,990.0;
COL avg_row_len FOR 999,990;
COL lobs FOR 9990;
SELECT t.table_name name, t.num_rows, t.blocks, ROUND(t.num_rows / NULLIF(t.blocks, 0), 1) AS rows_per_block, t.avg_row_len,
       (SELECT COUNT(*) FROM dba_lobs l WHERE l.owner = t.owner AND l.table_name = t.table_name) AS lobs,
       t.partitioned
  FROM dba_tables t,
       dba_users u
 WHERE t.owner = UPPER(TRIM('&&table_owner.'))
   AND u.username = t.owner
   AND u.oracle_maintained = 'N' 
   AND u.username NOT LIKE 'C##'||CHR(37) 
 ORDER BY 1
/
PRO
PRO 2. Table Name:
DEF table_name = '&2.';
UNDEF 2;
COL table_name NEW_V table_name;
SELECT UPPER(TRIM(NVL('&&table_name.', '&&name.'))) table_name FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name._&&table_owner..&&table_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&table_owner." "&&table_name."
@@cs_internal/cs_spool_id.sql
--
PRO TABLE_OWNER  : &&table_owner.
PRO TABLE_NAME   : &&table_name.
--
DEF specific_table = '&&table_name.';
DEF order_by = 't.pdb_name, t.owner, t.table_name';
DEF fetch_first_N_rows = '1';
PRO
PRO SUMMARY &&table_owner..&&table_name.
PRO ~~~~~~~
@@cs_internal/cs_tables_internal.sql
--
COL owner FOR A30 HEA 'Owner' TRUNC;
COL segment_name FOR A30 TRUNC;
COL partition_name FOR A30 TRUNC;
COL column_name FOR A30 TRUNC;
COL segments FOR 9,999,990;
--
COL mebibytes FOR 999,999,990.000 HEA 'Size MiB';
COL megabytes FOR 999,999,990.000 HEA 'Size MB';
COL tablespace_name FOR A30 HEA 'Tablespace';
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF mebibytes megabytes segments ON REPORT;
--
PRO
PRO SEGMENTS (dba_segments) top 1000 &&table_owner..&&table_name.
PRO ~~~~~~~~
WITH
t AS (
SELECT owner, table_name
  FROM dba_tables
 WHERE owner = '&&table_owner.'
   AND table_name = '&&table_name.'
),
s AS (
SELECT 1 AS oby, s.segment_type, s.owner, s.segment_name, s.partition_name, NULL AS column_name, s.bytes, s.tablespace_name
  FROM t, dba_segments s
 WHERE s.owner = t.owner
   AND s.segment_name = t.table_name
   AND s.segment_type LIKE 'TABLE%'
 UNION ALL
SELECT 2 AS oby, s.segment_type, s.owner, s.segment_name, s.partition_name, NULL AS column_name, s.bytes, s.tablespace_name
  FROM t, dba_indexes i, dba_segments s
 WHERE i.table_owner = t.owner
   AND i.table_name = t.table_name
   AND s.owner = i.owner
   AND s.segment_name = i.index_name
   AND s.segment_type LIKE 'INDEX%'
 UNION ALL
SELECT 3 AS oby, s.segment_type, s.owner, s.segment_name, s.partition_name, l.column_name, s.bytes, s.tablespace_name
  FROM t, dba_lobs l, dba_segments s
 WHERE l.owner = t.owner
   AND l.table_name = t.table_name
   AND s.owner = l.owner
   AND s.segment_name = l.segment_name
   AND s.segment_type LIKE 'LOB%'
)
--SELECT ROUND(bytes/POWER(2,20),3) AS mebibytes, segment_type, owner, column_name, segment_name, partition_name, tablespace_name
SELECT ROUND(bytes/POWER(10,6),3) AS megabytes, segment_type, owner, column_name, segment_name, partition_name, tablespace_name
  FROM s
 ORDER BY bytes DESC, oby, segment_type, owner, column_name, segment_name, partition_name
 FETCH FIRST 1000 ROWS ONLY
/
--
PRO
PRO SEGMENT TYPE (dba_segments) &&table_owner..&&table_name.
PRO ~~~~~~~~~~~~
WITH
t AS (
SELECT owner, table_name
  FROM dba_tables
 WHERE owner = '&&table_owner.'
   AND table_name = '&&table_name.'
),
s AS (
SELECT 1 AS oby, s.segment_type, s.owner, s.segment_name, s.partition_name, NULL AS column_name, s.bytes, s.tablespace_name
  FROM t, dba_segments s
 WHERE s.owner = t.owner
   AND s.segment_name = t.table_name
   AND s.segment_type LIKE 'TABLE%'
 UNION ALL
SELECT 2 AS oby, s.segment_type, s.owner, s.segment_name, s.partition_name, NULL AS column_name, s.bytes, s.tablespace_name
  FROM t, dba_indexes i, dba_segments s
 WHERE i.table_owner = t.owner
   AND i.table_name = t.table_name
   AND s.owner = i.owner
   AND s.segment_name = i.index_name
   AND s.segment_type LIKE 'INDEX%'
 UNION ALL
SELECT 3 AS oby, s.segment_type, s.owner, s.segment_name, s.partition_name, l.column_name, s.bytes, s.tablespace_name
  FROM t, dba_lobs l, dba_segments s
 WHERE l.owner = t.owner
   AND l.table_name = t.table_name
   AND s.owner = l.owner
   AND s.segment_name = l.segment_name
   AND s.segment_type LIKE 'LOB%'
)
--SELECT segment_type, COUNT(*) AS segments, ROUND(SUM(bytes)/POWER(2,20),3) AS mebibytes, tablespace_name
SELECT segment_type, COUNT(*) AS segments, ROUND(SUM(bytes)/POWER(10,6),3) AS megabytes, tablespace_name
  FROM s
 GROUP BY oby, segment_type, tablespace_name
 ORDER BY oby, segment_type, tablespace_name
/
--
CLEAR BREAK COMPUTE;
--
COL partitioned FOR A4 HEA 'Part';
COL degree FOR A10 HEA 'Degree';
COL temporary FOR A4 HEA 'Temp';
COL blocks FOR 999,999,990 HEA 'Blocks';
COL num_rows FOR 999,999,999,990 HEA 'Num Rows';
COL avg_row_len FOR 999,999,990 HEA 'Avg Row Len';
COL size_MiB FOR 999,999,990.000 HEA 'Size MiB';
COL seg_size_MiB FOR 999,999,990.000 HEA 'Seg Size MiB';
COL estimated_MiB FOR 999,999,990.000 HEA 'Estimated MiB';
COL size_MB FOR 999,999,990.000 HEA 'Size MB';
COL seg_size_MB FOR 999,999,990.000 HEA 'Seg Size MB';
COL estimated_MB FOR 999,999,990.000 HEA 'Estimated MB';
COL sample_size FOR 999,999,999,990 HEA 'Sample Size';
COL last_analyzed FOR A19 HEA 'Last Analyzed';
COL compression FOR A12 HEA 'Compression';
COL tablespace_name FOR A30 HEA 'Tablespace';
--
PRO
PRO TABLES (dba_tables) &&table_owner..&&table_name.
PRO ~~~~~~
SELECT CASE t.partitioned WHEN 'YES' THEN (SELECT TRIM(TO_CHAR(COUNT(*))) FROM dba_tab_partitions tp WHERE tp.table_owner = t.owner AND tp.table_name = t.table_name) ELSE t.partitioned END AS partitioned,
       t.degree,
       t.temporary,
       t.blocks,
       --t.blocks * COALESCE(b.block_size, TO_NUMBER(p.value)) / POWER(2,20) AS size_MiB,
       t.blocks * COALESCE(b.block_size, TO_NUMBER(p.value)) / POWER(10,6) AS size_MB,
       --(SELECT SUM(s.bytes) / POWER(2,20) FROM dba_segments s WHERE s.owner = t.owner AND s.segment_name = t.table_name AND s.segment_type LIKE 'TABLE%') AS seg_size_MiB,
       (SELECT SUM(s.bytes) / POWER(10,6) FROM dba_segments s WHERE s.owner = t.owner AND s.segment_name = t.table_name AND s.segment_type LIKE 'TABLE%') AS seg_size_MB,
       t.num_rows,
       t.avg_row_len, 
       --t.num_rows * t.avg_row_len / POWER(2,20) AS estimated_MiB,
       t.num_rows * t.avg_row_len / POWER(10,6) AS estimated_MB,
       t.sample_size,
       TO_CHAR(t.last_analyzed, '&&cs_datetime_full_format.') AS last_analyzed,
       t.compression,
       t.tablespace_name
  FROM dba_tables t,
       dba_tablespaces b,
       v$parameter p
 WHERE t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.' 
   AND b.tablespace_name(+) = t.tablespace_name
   AND p.name = 'db_block_size'
/
--
COL analyzetime FOR A19 HEA 'Analyze Time';
COL rowcnt FOR 999,999,999,990 HEA 'Row Count';
COL blkcnt FOR 999,999,990 HEA 'Block Count';
COL avgrln FOR 999,999,990 HEA 'Avg Row Len';
COL samplesize FOR 999,999,999,990 HEA 'Sample Size';
COL rows_inc FOR 999,999,999,990 HEA 'Rows Increase';
COL days_gap FOR 999,990.0 HEA 'Days Gap';
COL monthly_growth_perc FOR 999,990.000 HEA 'Monthly Growth Perc%';
--
PRO
PRO CBO STAT TABLE HISTORY (wri$_optstat_tab_history and dba_tables) &&table_owner..&&table_name.
PRO ~~~~~~~~~~~~~~~~~~~~~~
WITH
cbo_hist AS (
SELECT h.analyzetime,
       h.rowcnt,
       h.blkcnt,
       h.avgrln,
       h.samplesize
  FROM dba_objects o,
       wri$_optstat_tab_history h
 WHERE o.owner = '&&table_owner.'
   AND o.object_name = '&&table_name.' 
   AND o.object_type = 'TABLE'
   AND h.obj# = o.object_id
   AND h.analyzetime IS NOT NULL
 UNION
SELECT t.last_analyzed AS analyzetime,
       t.num_rows AS rowcnt,
       t.blocks AS blkcnt,
       t.avg_row_len AS avgrln,
       t.sample_size AS samplesize
  FROM dba_tables t
 WHERE t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.' 
),
cbo_hist_extended AS (
SELECT h.analyzetime,
       h.rowcnt,
       h.blkcnt,
       h.avgrln,
       h.samplesize,
       h.rowcnt - LAG(h.rowcnt) OVER (ORDER BY h.analyzetime) AS rows_inc,
       h.analyzetime - LAG(h.analyzetime) OVER (ORDER BY h.analyzetime) AS days_gap,
       100 * (365.25 / 12) * (h.rowcnt - LAG(h.rowcnt) OVER (ORDER BY h.analyzetime)) / (h.analyzetime - LAG(h.analyzetime) OVER (ORDER BY h.analyzetime)) / NULLIF(h.rowcnt, 0) AS monthly_growth_perc
  FROM cbo_hist h
)
SELECT TO_CHAR(h.analyzetime, '&&cs_datetime_full_format.') AS analyzetime,
       h.blkcnt,
       h.rowcnt,
       h.rows_inc, 
       h.days_gap,
       h.monthly_growth_perc,
       h.avgrln,
       h.samplesize
  FROM cbo_hist_extended h
 ORDER BY
       1
/
PRO
PRO GROWTH (wri$_optstat_tab_history and dba_tables) &&table_owner..&&table_name.
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
oldest AS (
SELECT h.analyzetime,
       h.rowcnt
  FROM dba_objects o,
       wri$_optstat_tab_history h
 WHERE o.owner = '&&table_owner.'
   AND o.object_name = '&&table_name.' 
   AND o.object_type = 'TABLE'
   AND h.obj# = o.object_id
   AND h.analyzetime IS NOT NULL
   AND h.rowcnt > 0
 ORDER BY
       h.analyzetime
 FETCH FIRST 1 ROW ONLY
),
newest AS (
SELECT t.last_analyzed AS analyzetime,
       t.num_rows AS rowcnt
  FROM dba_tables t
 WHERE t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.' 
   AND t.num_rows > 0
   AND ROWNUM = 1
)
SELECT 100 * (365 / 12) * (n.rowcnt - o.rowcnt) / (n.analyzetime - o.analyzetime) / o.rowcnt AS monthly_growth_perc
  FROM oldest o, newest n
 WHERE n.analyzetime > o.analyzetime
/
--
COL object_type HEA 'Object Type';
COL object_id FOR 999999999 HEA 'Object ID';
COL object_name FOR A30 HEA 'Object Name' TRUNC;
COL created FOR A19 HEA 'Created';
COL last_ddl_time FOR A19 HEA 'Last DDL Time';
--
PRO
PRO TABLE OBJECTS (dba_objects) up to 1000 &&table_owner..&&table_name.
PRO ~~~~~~~~~~~~~
SELECT o.object_type,
       o.object_id,
       TO_CHAR(o.created, '&&cs_datetime_full_format.') AS created,
       TO_CHAR(o.last_ddl_time, '&&cs_datetime_full_format.') AS last_ddl_time
  FROM dba_objects o
 WHERE o.owner = '&&table_owner.'
   AND o.object_name = '&&table_name.' 
   AND o.object_type LIKE 'TABLE%'
 ORDER BY
       o.object_type,
       o.object_id
FETCH FIRST 1000 ROWS ONLY       
/
--
COL index_name FOR A30 HEA 'Index Name';
COL partitioned FOR A4 HEA 'Part';
COL orphaned_entries FOR A8 HEA 'Orphaned|Entries';
COL degree FOR A10 HEA 'Degree';
COL index_type FOR A27 HEA 'Index Type';
COL uniqueness FOR A10 HEA 'Uniqueness';
COL columns FOR 999,999 HEA 'Columns';
COL status FOR A8 HEA 'Status';
COL visibility FOR A10 HEA 'Visibility';
COL blevel FOR 99,990 HEA 'BLevel';
COL leaf_blocks FOR 999,999,990 HEA 'Leaf Blocks';
COL size_MiB FOR 999,999,990.000 HEA 'Size MiB';
COL seg_size_MiB FOR 999,999,990.000 HEA 'Seg Size MiB';
COL size_MB FOR 999,999,990.000 HEA 'Size MB';
COL seg_size_MB FOR 999,999,990.000 HEA 'Seg Size MB';
COL distinct_keys FOR 999,999,999,990 HEA 'Dist Keys';
COL clustering_factor FOR 999,999,999,990 HEA 'Clust Fact';
COL num_rows FOR 999,999,999,990 HEA 'Num Rows';
COL sample_size FOR 999,999,999,990 HEA 'Sample Size';
COL last_analyzed FOR A19 HEA 'Last Analyzed';
COL compression FOR A13 HEA 'Compression';
COL tablespace_name FOR A30 HEA 'Tablespace';
--
PRO
PRO INDEXES (dba_indexes) &&table_owner..&&table_name.
PRO ~~~~~~~
SELECT i.index_name,
       CASE i.partitioned WHEN 'YES' THEN (SELECT TRIM(TO_CHAR(COUNT(*))) FROM dba_ind_partitions ip WHERE ip.index_owner = i.owner AND ip.index_name = i.index_name) ELSE i.partitioned END AS partitioned,
       i.orphaned_entries,
       i.degree,
       i.index_type,
       i.uniqueness,
       (SELECT COUNT(*) FROM dba_ind_columns ic WHERE ic.index_owner = i.owner AND ic.index_name = i.index_name) AS columns,
       i.status,
       i.visibility,
       i.blevel,
       i.leaf_blocks,
       --i.leaf_blocks * COALESCE(b.block_size, TO_NUMBER(p.value)) / POWER(2,20) AS size_MiB,
       i.leaf_blocks * COALESCE(b.block_size, TO_NUMBER(p.value)) / POWER(10,6) AS size_MB,
       --(SELECT SUM(s.bytes) / POWER(2,20) FROM dba_segments s WHERE s.owner = i.owner AND s.segment_name = i.index_name AND s.segment_type LIKE 'INDEX%') AS seg_size_MiB,
       (SELECT SUM(s.bytes) / POWER(10,6) FROM dba_segments s WHERE s.owner = i.owner AND s.segment_name = i.index_name AND s.segment_type LIKE 'INDEX%') AS seg_size_MB,
       i.distinct_keys,
       i.clustering_factor,
       i.num_rows,
       i.sample_size,
       TO_CHAR(i.last_analyzed, '&&cs_datetime_full_format.') AS last_analyzed,
       i.compression,
       i.tablespace_name
  FROM dba_indexes i,
       dba_tablespaces b,
       v$parameter p
 WHERE i.table_owner = '&&table_owner.'
   AND i.table_name = '&&table_name.'
   AND b.tablespace_name(+) = i.tablespace_name
   AND p.name = 'db_block_size'
 ORDER BY
       i.index_name
/
--
PRO
PRO INDEX OBJECTS (dba_objects) up to 1000 &&table_owner..&&table_name.
PRO ~~~~~~~~~~~~~
SELECT o.object_type,
       o.object_name,
       o.object_id,
       TO_CHAR(o.created, '&&cs_datetime_full_format.') AS created,
       TO_CHAR(o.last_ddl_time, '&&cs_datetime_full_format.') AS last_ddl_time
  FROM dba_indexes i,
       dba_objects o
 WHERE i.table_owner = '&&table_owner.'
   AND i.table_name = '&&table_name.'
   AND o.owner = i.owner
   AND o.object_name = i.index_name
   AND o.object_type LIKE 'INDEX%'
 ORDER BY
       o.object_type,
       o.object_name
FETCH FIRST 1000 ROWS ONLY       
/
--
COL part_sub FOR A12 HEA 'LEVEL';
COL object_type FOR A5 HEA 'TYPE';
COL owner FOR A30 HEA 'Owner' TRUNC;
COL name FOR A30 HEA 'Name' TRUNC;
COL column_position FOR 999 HEA 'POS';
COL column_name FOR A30 TRUNC;
--
PRO
PRO PARTITION KEYS (dba_part_key_columns and dba_subpart_key_columns) &&table_owner..&&table_name.
PRO ~~~~~~~~~~~~~~
--
WITH /* PART_KEY_COLUMNS */
dba_tables_m AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(dba_tables) */ 
       t.owner, 
       t.table_name
  FROM dba_tables t
 WHERE t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.'
),
dba_indexes_m AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(dba_indexes) */ 
       i.owner,
       i.index_name
  FROM dba_tables_m t,
       dba_indexes i
 WHERE i.table_owner = t.owner
   AND i.table_name = t.table_name
),
objects_m AS (
SELECT owner, table_name AS name, 'TABLE' AS object_type
  FROM dba_tables_m
 UNION
SELECT owner, index_name AS name, 'INDEX' AS object_type
  FROM dba_indexes_m
)
SELECT 'PARTITION' AS part_sub,
       p.object_type,
       p.owner,
       p.name,
       p.column_position,
       p.column_name
  FROM dba_part_key_columns p,
       objects_m o
 WHERE o.owner = p.owner
   AND o.name = p.name
   AND o.object_type = p.object_type
 UNION ALL
SELECT 'SUBPARTITION' AS part_sub,
       p.object_type,
       p.owner,
       p.name,
       p.column_position,
       p.column_name
  FROM dba_subpart_key_columns p,
       objects_m o
 WHERE o.owner = p.owner
   AND o.name = p.name
   AND o.object_type = p.object_type
 ORDER BY
       1 ASC, 2 DESC, 3, 4, 5
/
--
COL index_name FOR A30 HEA 'Index Name';
COL visibility FOR A10 HEA 'Visibility';
COL partitioned FOR A4 HEA 'Part';
COL column_position FOR 999 HEA 'Pos';
COL column_name FOR A30 HEA 'Column Name';
COL data_type FOR A33 HEA 'Data Type';
COL nullable FOR A8 HEA 'Nullable';
COL data_default FOR A30 HEA 'Data Default';
COL num_distinct FOR 999,999,999,990 HEA 'Num Distinct';
COL low_value_translated FOR A64 HEA 'Low Value Translated';
COL high_value_translated FOR A64 HEA 'High Value Translated';
COL density FOR 0.000000000 HEA 'Density';
COL num_nulls FOR 999,999,999,990 HEA 'Num Nulls';
COL num_buckets FOR 999,990 HEA 'Buckets';
COL histogram FOR A15 HEA 'Histogram';
COL sample_size FOR 999,999,999,990 HEA 'Sample Size';
COL last_analyzed FOR A19 HEA 'Last Analyzed';
COL avg_col_len FOR 999,999,990 HEA 'Avg Col Len';
COL data_length FOR 999,999,990 HEA 'Data Length';
COL char_length FOR 999,999,990 HEA 'Char Length';
--
BRE ON index_name SKIP 1 ON visibility ON partitioned;
--
PRO
PRO INDEX COLUMNS (dba_ind_columns) &&table_owner..&&table_name.
PRO ~~~~~~~~~~~~~
SELECT i.index_name,
       x.visibility,
       x.partitioned,
       i.column_position,
       c.column_name,
       c.data_type,
       c.nullable,
       c.data_default data_default,
       c.num_distinct,
       CASE WHEN c.data_type = 'NUMBER' THEN to_char(utl_raw.cast_to_number(c.low_value))
        WHEN c.data_type IN ('VARCHAR2', 'CHAR') THEN SUBSTR(to_char(utl_raw.cast_to_varchar2(c.low_value)),1,64)
        WHEN c.data_type IN ('NVARCHAR2','NCHAR') THEN SUBSTR(to_char(utl_raw.cast_to_nvarchar2(c.low_value)),1,64)
        WHEN c.data_type = 'BINARY_DOUBLE' THEN to_char(utl_raw.cast_to_binary_double(c.low_value))
        WHEN c.data_type = 'BINARY_FLOAT' THEN to_char(utl_raw.cast_to_binary_float(c.low_value))
        WHEN c.data_type = 'DATE' THEN rtrim(
                    ltrim(to_char(100*(to_number(substr(c.low_value,1,2) ,'XX')-100) + (to_number(substr(c.low_value,3,2) ,'XX')-100),'0000'))||'-'||
                    ltrim(to_char(     to_number(substr(c.low_value,5,2) ,'XX')  ,'00'))||'-'||
                    ltrim(to_char(     to_number(substr(c.low_value,7,2) ,'XX')  ,'00'))||'T'||
                    ltrim(to_char(     to_number(substr(c.low_value,9,2) ,'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.low_value,11,2),'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.low_value,13,2),'XX')-1,'00')))
        WHEN c.data_type LIKE 'TIMESTAMP%' THEN rtrim(
                    ltrim(to_char(100*(to_number(substr(c.low_value,1,2) ,'XX')-100) + (to_number(substr(c.low_value,3,2) ,'XX')-100),'0000'))||'-'||
                    ltrim(to_char(     to_number(substr(c.low_value,5,2) ,'XX')  ,'00'))||'-'||
                    ltrim(to_char(     to_number(substr(c.low_value,7,2) ,'XX')  ,'00'))||'T'||
                    ltrim(to_char(     to_number(substr(c.low_value,9,2) ,'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.low_value,11,2),'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.low_value,13,2),'XX')-1,'00'))||'.'||
                    to_number(substr(c.low_value,15,8),'XXXXXXXX'))
       END low_value_translated,
       CASE WHEN c.data_type = 'NUMBER' THEN to_char(utl_raw.cast_to_number(c.high_value))
        WHEN c.data_type IN ('VARCHAR2', 'CHAR') THEN SUBSTR(to_char(utl_raw.cast_to_varchar2(c.high_value)),1,64)
        WHEN c.data_type IN ('NVARCHAR2','NCHAR') THEN SUBSTR(to_char(utl_raw.cast_to_nvarchar2(c.high_value)),1,64)
        WHEN c.data_type = 'BINARY_DOUBLE' THEN to_char(utl_raw.cast_to_binary_double(c.high_value))
        WHEN c.data_type = 'BINARY_FLOAT' THEN to_char(utl_raw.cast_to_binary_float(c.high_value))
        WHEN c.data_type = 'DATE' THEN rtrim(
                    ltrim(to_char(100*(to_number(substr(c.high_value,1,2) ,'XX')-100) + (to_number(substr(c.high_value,3,2) ,'XX')-100),'0000'))||'-'||
                    ltrim(to_char(     to_number(substr(c.high_value,5,2) ,'XX')  ,'00'))||'-'||
                    ltrim(to_char(     to_number(substr(c.high_value,7,2) ,'XX')  ,'00'))||'T'||
                    ltrim(to_char(     to_number(substr(c.high_value,9,2) ,'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.high_value,11,2),'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.high_value,13,2),'XX')-1,'00')))
        WHEN c.data_type LIKE 'TIMESTAMP%' THEN rtrim(
                    ltrim(to_char(100*(to_number(substr(c.high_value,1,2) ,'XX')-100) + (to_number(substr(c.high_value,3,2) ,'XX')-100),'0000'))||'-'||
                    ltrim(to_char(     to_number(substr(c.high_value,5,2) ,'XX')  ,'00'))||'-'||
                    ltrim(to_char(     to_number(substr(c.high_value,7,2) ,'XX')  ,'00'))||'T'||
                    ltrim(to_char(     to_number(substr(c.high_value,9,2) ,'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.high_value,11,2),'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.high_value,13,2),'XX')-1,'00'))||'.'||
                    to_number(substr(c.high_value,15,8),'XXXXXXXX'))
        END high_value_translated,
       c.density,
       c.num_nulls,
       c.num_buckets,
       c.histogram,
       c.sample_size,
       TO_CHAR(c.last_analyzed, '&&cs_datetime_full_format.') last_analyzed,
       c.avg_col_len,
       c.data_length, 
       c.char_length
  FROM dba_ind_columns i,
       dba_tab_cols c,
       dba_indexes x
 WHERE i.table_owner = '&&table_owner.'
   AND i.table_name = '&&table_name.'
   AND c.owner = i.table_owner
   AND c.table_name = i.table_name
   AND c.column_name = i.column_name
   AND x.table_owner = i.table_owner
   AND x.table_name = i.table_name
   AND x.index_name = i.index_name
 ORDER BY
       i.index_name,
       i.column_position
/
--
CL BRE;
--
COL column_id FOR 999 HEA 'ID';
COL column_name FOR A30 HEA 'Column Name';
COL data_type FOR A33 HEA 'Data Type';
COL nullable FOR A8 HEA 'Nullable';
COL data_default FOR A30 HEA 'Data Default';
COL num_distinct FOR 999,999,999,990 HEA 'Num Distinct';
COL low_value_translated FOR A64 HEA 'Low Value Translated';
COL high_value_translated FOR A64 HEA 'High Value Translated';
COL density FOR 0.000000000 HEA 'Density';
COL num_nulls FOR 999,999,999,990 HEA 'Num Nulls';
COL num_buckets FOR 999,990 HEA 'Buckets';
COL histogram FOR A15 HEA 'Histogram';
COL sample_size FOR 999,999,999,990 HEA 'Sample Size';
COL last_analyzed FOR A19 HEA 'Last Analyzed';
COL avg_col_len FOR 999,999,990 HEA 'Avg Col Len';
COL data_length FOR 999,999,990 HEA 'Data Length';
COL char_length FOR 999,999,990 HEA 'Char Length';
--
BRE ON owner ON table_name SKIP 1;
--
PRO
PRO TABLE COLUMNS (dba_tab_cols) &&table_owner..&&table_name.
PRO ~~~~~~~~~~~~~
SELECT c.column_id,
       c.column_name,
       c.data_type,
       c.nullable,
       c.data_default data_default,
       c.num_distinct,
       CASE WHEN c.data_type = 'NUMBER' THEN to_char(utl_raw.cast_to_number(c.low_value))
        WHEN c.data_type IN ('VARCHAR2', 'CHAR') THEN SUBSTR(to_char(utl_raw.cast_to_varchar2(c.low_value)),1,64)
        WHEN c.data_type IN ('NVARCHAR2','NCHAR') THEN SUBSTR(to_char(utl_raw.cast_to_nvarchar2(c.low_value)),1,64)
        WHEN c.data_type = 'BINARY_DOUBLE' THEN to_char(utl_raw.cast_to_binary_double(c.low_value))
        WHEN c.data_type = 'BINARY_FLOAT' THEN to_char(utl_raw.cast_to_binary_float(c.low_value))
        WHEN c.data_type = 'DATE' THEN rtrim(
                    ltrim(to_char(100*(to_number(substr(c.low_value,1,2) ,'XX')-100) + (to_number(substr(c.low_value,3,2) ,'XX')-100),'0000'))||'-'||
                    ltrim(to_char(     to_number(substr(c.low_value,5,2) ,'XX')  ,'00'))||'-'||
                    ltrim(to_char(     to_number(substr(c.low_value,7,2) ,'XX')  ,'00'))||'T'||
                    ltrim(to_char(     to_number(substr(c.low_value,9,2) ,'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.low_value,11,2),'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.low_value,13,2),'XX')-1,'00')))
        WHEN c.data_type LIKE 'TIMESTAMP%' THEN rtrim(
                    ltrim(to_char(100*(to_number(substr(c.low_value,1,2) ,'XX')-100) + (to_number(substr(c.low_value,3,2) ,'XX')-100),'0000'))||'-'||
                    ltrim(to_char(     to_number(substr(c.low_value,5,2) ,'XX')  ,'00'))||'-'||
                    ltrim(to_char(     to_number(substr(c.low_value,7,2) ,'XX')  ,'00'))||'T'||
                    ltrim(to_char(     to_number(substr(c.low_value,9,2) ,'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.low_value,11,2),'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.low_value,13,2),'XX')-1,'00'))||'.'||
                    to_number(substr(c.low_value,15,8),'XXXXXXXX'))
       END low_value_translated,
       CASE WHEN c.data_type = 'NUMBER' THEN to_char(utl_raw.cast_to_number(c.high_value))
        WHEN c.data_type IN ('VARCHAR2', 'CHAR') THEN SUBSTR(to_char(utl_raw.cast_to_varchar2(c.high_value)),1,64)
        WHEN c.data_type IN ('NVARCHAR2','NCHAR') THEN SUBSTR(to_char(utl_raw.cast_to_nvarchar2(c.high_value)),1,64)
        WHEN c.data_type = 'BINARY_DOUBLE' THEN to_char(utl_raw.cast_to_binary_double(c.high_value))
        WHEN c.data_type = 'BINARY_FLOAT' THEN to_char(utl_raw.cast_to_binary_float(c.high_value))
        WHEN c.data_type = 'DATE' THEN rtrim(
                    ltrim(to_char(100*(to_number(substr(c.high_value,1,2) ,'XX')-100) + (to_number(substr(c.high_value,3,2) ,'XX')-100),'0000'))||'-'||
                    ltrim(to_char(     to_number(substr(c.high_value,5,2) ,'XX')  ,'00'))||'-'||
                    ltrim(to_char(     to_number(substr(c.high_value,7,2) ,'XX')  ,'00'))||'T'||
                    ltrim(to_char(     to_number(substr(c.high_value,9,2) ,'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.high_value,11,2),'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.high_value,13,2),'XX')-1,'00')))
        WHEN c.data_type LIKE 'TIMESTAMP%' THEN rtrim(
                    ltrim(to_char(100*(to_number(substr(c.high_value,1,2) ,'XX')-100) + (to_number(substr(c.high_value,3,2) ,'XX')-100),'0000'))||'-'||
                    ltrim(to_char(     to_number(substr(c.high_value,5,2) ,'XX')  ,'00'))||'-'||
                    ltrim(to_char(     to_number(substr(c.high_value,7,2) ,'XX')  ,'00'))||'T'||
                    ltrim(to_char(     to_number(substr(c.high_value,9,2) ,'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.high_value,11,2),'XX')-1,'00'))||':'||
                    ltrim(to_char(     to_number(substr(c.high_value,13,2),'XX')-1,'00'))||'.'||
                    to_number(substr(c.high_value,15,8),'XXXXXXXX'))
        END high_value_translated,
       c.density,
       c.num_nulls,
       c.num_buckets,
       c.histogram,
       c.sample_size,
       TO_CHAR(c.last_analyzed, '&&cs_datetime_full_format.') last_analyzed,
       c.avg_col_len,
       c.data_length, 
       c.char_length
  FROM dba_tab_cols c
 WHERE c.owner = '&&table_owner.'
   AND c.table_name = '&&table_name.'
 ORDER BY
       c.column_id
/
--
CL BRE;
--
COL column_name FOR A30 HEA 'Column Name';
COL index_name FOR A30 HEA 'Index Name';
COL segment_name FOR A30 HEA 'Segment Name';
COL bytes FOR 999,999,999,990 HEA 'Bytes';
COL blocks FOR 999,999,990 HEA 'Blocks';
COL size_MiB FOR 999,999,990.000 HEA 'Size MiB';
COL size_MB FOR 999,999,990.000 HEA 'Size MB';
COL deduplication FOR A13 HEA 'Deduplication';
COL compression FOR A11 HEA 'Compression';
COL encrypt FOR A7 HEA 'Encrypt';
COL cache FOR A5 HEA 'Cache';
COL securefile FOR A10 HEA 'SecureFile';
COL in_row FOR A6 HEA 'In Row';
COL tablespace_name FOR A30 HEA 'Tablespace';
--
BRE ON owner ON table_name SKIP 1;
--
SET HEA OFF;
PRO
PRO COLUMN USAGE REPORT (dbms_stats.report_col_usage) &&table_owner..&&table_name.
PRO ~~~~~~~~~~~~~~~~~~~
SELECT DBMS_STATS.report_col_usage('&&table_owner.', '&&table_name.')
  FROM DUAL
/
SET HEA ON;
--
PRO
PRO LOBS (dba_lobs) 
PRO ~~~~
SELECT l.column_name,
       l.index_name,
       l.segment_name,
       SUM(s.bytes) AS bytes,
       SUM(s.blocks) AS blocks,
       --SUM(s.blocks) * COALESCE(b.block_size, TO_NUMBER(p.value)) / POWER(2,20) AS size_MiB,
       SUM(s.blocks) * COALESCE(b.block_size, TO_NUMBER(p.value)) / POWER(10,6) AS size_MB,
       l.deduplication,
       l.compression,
       l.encrypt,
       l.cache,
       l.securefile,
       l.in_row,
       l.tablespace_name
  FROM dba_lobs l,
       dba_segments s,
       dba_tablespaces b,
       v$parameter p
 WHERE l.owner = '&&table_owner.'
   AND l.table_name = '&&table_name.'
   AND s.owner = l.owner
   AND s.segment_name = l.segment_name
   AND s.segment_type IN ('LOBSEGMENT', 'LOB PARTITION')
   AND b.tablespace_name(+) = l.tablespace_name
   AND p.name = 'db_block_size'
 GROUP BY
       l.column_name,
       l.index_name,
       l.segment_name,
       l.deduplication,
       l.compression,
       l.encrypt,
       l.cache,
       l.securefile,
       l.in_row,
       l.tablespace_name,
       b.block_size,
       p.value
 ORDER BY
       l.column_name
/
--
CL BRE;
--
COL owner FOR A30 HEA 'Owner' TRUNC;
COL table_name FOR A30 HEA 'Table Name' TRUNC;
COL index_name FOR A30 HEA 'Index Name' TRUNC;
COL metadata FOR A200 HEA 'Metadata';
--
PRO
PRO TABLE METADATA (DBMS_METADATA.get_ddl) &&table_owner..&&table_name.
PRO ~~~~~~~~~~~~~~
SELECT t.owner, t.table_name, DBMS_METADATA.get_ddl('TABLE', t.table_name, t.owner) AS metadata
  FROM dba_tables t
 WHERE t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.' 
 ORDER BY
       t.owner, t.table_name
/
--
PRO
PRO INDEX METADATA (DBMS_METADATA.get_ddl) &&table_owner..&&table_name.
PRO ~~~~~~~~~~~~~~
SELECT i.owner, i.table_name, i.index_name, DBMS_METADATA.get_ddl('INDEX', i.index_name, i.owner) AS metadata
  FROM dba_tables t,
       dba_indexes i
 WHERE t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.' 
   AND i.table_owner = t.owner
   AND i.table_name = t.table_name
 ORDER BY
       i.owner,
       i.table_name,
       i.index_name
/
--
COL num_rows FOR 999,999,999,990 HEA 'Num Rows';
COL kievlive FOR A8 HEA 'KievLive';
--
PRO
PRO KIEV LIVE (dba_tab_histograms) &&table_owner..&&table_name.
PRO ~~~~~~~~~
SELECT SUBSTR(UTL_RAW.CAST_TO_VARCHAR2(SUBSTR(LPAD(TO_CHAR(h.endpoint_value,'fmxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'),30,'0'),1,12)), 1, 8) kievlive,
       h.endpoint_number - LAG(h.endpoint_number, 1, 0) OVER (ORDER BY h.endpoint_value) num_rows
  FROM dba_tab_histograms h
 WHERE h.owner = '&&table_owner.'
   AND h.table_name = '&&table_name.'
   AND h.column_name = 'KIEVLIVE'
 ORDER BY
       1
/
--
PRO
PRO If you want to preserve script output, execute corresponding scp command below, from a TERM session running on your Mac/PC:
PRO scp &&cs_host_name.:&&cs_file_prefix._&&cs_script_name.*.txt &&cs_local_dir.
PRO scp &&cs_host_name.:&&cs_file_dir.&&cs_reference_sanitized._*.* &&cs_local_dir.
--
PRO
PRO TOP_KEYS (if dba_tables.num_rows < 25MM) &&table_owner..&&table_name.
PRO ~~~~~~~~
--
SET HEA OFF;
CLEAR COL;
SPO /tmp/cs_driver.sql;
--
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
  FROM dba_tables t,
       dba_indexes i,
       dba_ind_columns c
 WHERE t.table_name NOT LIKE 'KIEV%'
   AND t.owner = '&&table_owner.'
   AND t.table_name = '&&table_name.'
   AND t.num_rows < 25e6
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
--
PRO
PRO SQL> @&&cs_script_name..sql "&&table_owner." "&&table_name."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--