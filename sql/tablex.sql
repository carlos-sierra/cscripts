----------------------------------------------------------------------------------------
--
-- File name:   tablex.sql
--
-- Purpose:     Reports CBO Statistics for a given Table
--
-- Author:      Carlos Sierra
--
-- Version:     2015/02/24
--
-- Usage:       This script inputs three parameters. 
--              Parameter 1 is the name of the Table
--              Parameter 2 the Owner
--              Parameter 3 is to select ASH data (requires Diagnostics Pack)
--
-- Example:     @tablex.sql sales sh y
--
--  Notes:      Developed and tested on 11.2.0.3
--             
---------------------------------------------------------------------------------------
--
CL COL;
SET FEED OFF VER OFF HEA ON LIN 2000 PAGES 50 TIMI OFF LONG 40000 LONGC 2000 TRIMS ON AUTOT OFF SERVEROUT ON;
PRO
PRO 1. Enter Table Name (required)
DEF tbl_name = '&1';
PRO
SELECT owner
  FROM dba_tables
 WHERE table_name = UPPER(TRIM('&&tbl_name.'))
 ORDER BY owner;
PRO
PRO 2. Enter Owner (required)
DEF tbl_owner = '&2';
PRO
PRO 3. ASH data (Y | N) requires Diagnostics Pack
DEF ash_data = '&3';
PRO
-- is_pre_11r2
DEF is_pre_11r2 = '';
COL is_pre_11r2 NEW_V is_pre_11r2 NOPRI;
SELECT '--' is_pre_11r2 FROM v$instance WHERE version LIKE '10%' OR version LIKE '11.1%';
-- spool and sql_text
COMP SUM OF leaf_blocks ON REPORT;
COMP SUM OF blocks ON REPORT;
COMP SUM OF num_rows ON REPORT;
COMP SUM OF extents ON REPORT;
BRE ON REPORT;
COL spool_file_name NEW_V spool_file_name;
SELECT REPLACE('tablex_&&tbl_owner._&&tbl_name.', '$') spool_file_name FROM DUAL;
SPO &&spool_file_name..txt;
PRO OWNER: "&&tbl_owner."
PRO TABLE: "&&tbl_name."
PRO ASH: "&&ash_data."
PRO
PRO Table  
PRO ~~~~~
SELECT owner
       ,table_name
       ,tablespace_name
       ,pct_free
       ,pct_used
       ,ini_trans
       ,max_trans
       ,freelists
       ,freelist_groups
       ,partitioned
       ,degree
       ,temporary
       ,blocks
       ,num_rows
       ,avg_row_len
       ,sample_size
       ,TO_CHAR(last_analyzed, 'YYYY-MM-DD HH24:MI:SS') last_analyzed
       ,global_stats
       ,compression
       &&is_pre_11r2.,compress_for
       ,buffer_pool
       ,cache
       &&is_pre_11r2.,flash_cache
       &&is_pre_11r2.,cell_flash_cache
  FROM dba_tables
 WHERE table_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
/
PRO
PRO Indexes 
PRO ~~~~~~~
SELECT i.owner
       ,i.index_name
       ,i.tablespace_name
       ,i.pct_free
       ,i.ini_trans
       ,i.max_trans
       ,i.freelists
       ,i.freelist_groups
       ,i.partitioned
       ,i.degree
       ,i.index_type
       ,i.uniqueness
       ,(SELECT COUNT(*) FROM dba_ind_columns ic WHERE ic.index_owner = i.owner AND ic.index_name = i.index_name) columns
       ,i.status
       &&is_pre_11r2.,i.visibility
       ,i.blevel
       ,i.leaf_blocks
       ,i.distinct_keys
       ,i.clustering_factor
       ,i.num_rows
       ,i.sample_size
       ,TO_CHAR(i.last_analyzed, 'YYYY-MM-DD HH24:MI:SS') last_analyzed
       ,i.global_stats
       ,i.compression
       ,i.prefix_length
       ,i.buffer_pool
       &&is_pre_11r2.,i.flash_cache
       &&is_pre_11r2.,i.cell_flash_cache
  FROM dba_indexes i
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
 ORDER BY
       i.owner,
       i.index_name
/
-- compute low and high values for each table column
DELETE plan_table WHERE statement_id = 'low_high'
/
DECLARE
  l_low VARCHAR2(256);
  l_high VARCHAR2(256);
  FUNCTION compute_low_high (p_data_type IN VARCHAR2, p_raw_value IN RAW)
  RETURN VARCHAR2 AS
    l_number NUMBER;
    l_varchar2 VARCHAR2(256);
    l_date DATE;
  BEGIN
    IF p_data_type = 'NUMBER' THEN
      DBMS_STATS.convert_raw_value(p_raw_value, l_number);
      RETURN TO_CHAR(l_number);
    ELSIF p_data_type IN ('VARCHAR2', 'CHAR', 'NVARCHAR2', 'CHAR2') THEN
      DBMS_STATS.convert_raw_value(p_raw_value, l_varchar2);
      RETURN l_varchar2;
    ELSIF SUBSTR(p_data_type, 1, 4) IN ('DATE', 'TIME') THEN
      DBMS_STATS.convert_raw_value(p_raw_value, l_date);
      RETURN TO_CHAR(l_date, 'YYYY-MM-DD HH24:MI:SS');
    ELSE
      RETURN RAWTOHEX(p_raw_value);
    END IF;
  END compute_low_high;
BEGIN
  FOR i IN (SELECT owner, table_name, column_name, data_type, low_value, high_value
              FROM dba_tab_cols
             WHERE table_name = UPPER(TRIM('&&tbl_name.'))
               AND owner = UPPER(TRIM('&&tbl_owner.')))
  LOOP
    l_low := compute_low_high(i.data_type, i.low_value);
    l_high := compute_low_high(i.data_type, i.high_value);
    INSERT INTO plan_table (statement_id, object_owner, object_name, other_tag, partition_start, partition_stop)
    VALUES ('low_high', i.owner, i.table_name, i.column_name, l_low, l_high);
  END LOOP;
END;
/
PRO
PRO Columns 
PRO ~~~~~~~
SET LONG 4000 LONGC 40;
COL data_type FOR A20;
COL data_default FOR A20;
COL low_value FOR A32;
COL high_value FOR A32;
SELECT c.column_id
       ,c.column_name
       ,c.data_type
       ,c.data_length
       ,c.nullable
       ,c.data_default
       ,c.num_distinct
       ,NVL(p.partition_start, c.low_value) low_value
       ,NVL(p.partition_stop, c.high_value) high_value
       ,c.density
       ,c.num_nulls
       ,c.num_buckets
       ,c.histogram
       ,c.sample_size
       ,TO_CHAR(c.last_analyzed, 'YYYY-MM-DD HH24:MI:SS') last_analyzed
       ,c.global_stats
       ,c.avg_col_len
  FROM dba_tab_cols c,
       plan_table p
 WHERE c.table_name = UPPER(TRIM('&&tbl_name.'))
   AND c.owner = UPPER(TRIM('&&tbl_owner.'))
   AND p.statement_id(+) = 'low_high'
   AND p.object_owner(+) = c.owner
   AND p.object_name(+) = c.table_name
   AND p.other_tag(+) = c.column_name
 ORDER BY
       c.column_id,
       c.column_name
/
PRO
PRO Index Columns 
PRO ~~~~~~~~~~~~~
COL index_and_column_name FOR A70;
SELECT i.index_owner||'.'||i.index_name||' '||c.column_name index_and_column_name
       ,c.data_type
       ,c.data_length
       ,c.nullable
       ,c.data_default
       ,c.num_distinct
       ,NVL(p.partition_start, c.low_value) low_value
       ,NVL(p.partition_stop, c.high_value) high_value
       ,c.density
       ,c.num_nulls
       ,c.num_buckets
       ,c.histogram
       ,c.sample_size
       ,TO_CHAR(c.last_analyzed, 'YYYY-MM-DD HH24:MI:SS') last_analyzed
       ,c.global_stats
       ,c.avg_col_len
  FROM dba_ind_columns i,
       dba_tab_cols c,
       plan_table p
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND c.owner = i.table_owner
   AND c.table_name = i.table_name
   AND c.column_name = i.column_name
   AND p.statement_id(+) = 'low_high'
   AND p.object_owner(+) = c.owner
   AND p.object_name(+) = c.table_name
   AND p.other_tag(+) = c.column_name
 ORDER BY
       i.index_owner,
       i.index_name,
       i.column_position
/
PRO
PRO Table Partitions
PRO ~~~~~~~~~~~~~~~~
SELECT partition_name
       ,tablespace_name
       ,pct_free
       ,pct_used
       ,ini_trans
       ,max_trans
       ,freelists
       ,freelist_groups
       ,composite
       ,subpartition_count
       ,high_value
       ,blocks
       ,num_rows
       ,avg_row_len
       ,sample_size
       ,TO_CHAR(last_analyzed, 'YYYY-MM-DD HH24:MI:SS') last_analyzed
       ,global_stats
       ,compression
       &&is_pre_11r2.,compress_for
       ,buffer_pool
       &&is_pre_11r2.,flash_cache
       &&is_pre_11r2.,cell_flash_cache
  FROM dba_tab_partitions
 WHERE table_name = UPPER(TRIM('&&tbl_name.'))
   AND table_owner = UPPER(TRIM('&&tbl_owner.'))
 ORDER BY
       partition_name
/
PRO
PRO Index Partitions
PRO ~~~~~~~~~~~~~~~~
SELECT i.owner
       ,i.index_name
       ,p.partition_name
       ,p.tablespace_name
       ,p.pct_free
       ,p.ini_trans
       ,p.max_trans
       ,p.freelists
       ,p.freelist_groups
       ,p.composite
       ,p.subpartition_count
       ,p.status
       ,p.blevel
       ,p.leaf_blocks
       ,p.distinct_keys
       ,p.clustering_factor
       ,p.num_rows
       ,p.sample_size
       ,TO_CHAR(p.last_analyzed, 'YYYY-MM-DD HH24:MI:SS') last_analyzed
       ,p.global_stats
       ,p.buffer_pool
       &&is_pre_11r2.,p.flash_cache
       &&is_pre_11r2.,p.cell_flash_cache
  FROM dba_indexes i,
       dba_ind_partitions p
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND p.index_owner = i.owner
   AND p.index_name = i.index_name
 ORDER BY
       i.owner,
       i.index_name,
       p.partition_name
/
PRO
PRO Table Segments
PRO ~~~~~~~~~~~~~~
SELECT partition_name
       ,segment_type
       ,tablespace_name
       ,bytes
       ,blocks
       ,extents
       ,buffer_pool
       &&is_pre_11r2.,flash_cache
       &&is_pre_11r2.,cell_flash_cache
  FROM dba_segments
 WHERE segment_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
   AND segment_type LIKE 'TABLE%'
 ORDER BY
       partition_name
/
PRO
PRO Index Segments
PRO ~~~~~~~~~~~~~~
SELECT i.owner
       ,i.index_name
       ,s.partition_name
       ,s.tablespace_name
       ,s.bytes
       ,s.blocks
       ,s.extents
       ,s.buffer_pool
       &&is_pre_11r2.,s.flash_cache
       &&is_pre_11r2.,s.cell_flash_cache
  FROM dba_indexes i,
       dba_segments s
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND s.owner = i.owner
   AND s.segment_name = i.index_name
 ORDER BY
       i.owner,
       i.index_name,
       s.partition_name
/
COL plan_operation FOR A40;
COL state_wait_class_and_event FOR A50;
COL object_name FOR A40;
COL sql_text FOR A80;
PRO
PRO Active Session History (by sql_id)
PRO ~~~~~~~~~~~~~~~~~~~~~~
WITH
objs AS (
SELECT object_id,
       owner,
       object_name
  FROM dba_objects
 WHERE object_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
   AND object_type LIKE 'TABLE%'
   AND UPPER('&&ash_data.') = 'Y'
 UNION
SELECT o.object_id,
       o.owner,
       o.object_name
  FROM dba_indexes i,
       dba_objects o
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND o.object_name = i.index_name
   AND o.owner = i.owner
   AND o.object_type LIKE 'INDEX%'
   AND UPPER('&&ash_data.') = 'Y'
)
SELECT COUNT(*) samples,
       h.sql_id,
       (SELECT REPLACE(SUBSTR(sql_text, 1, 80), CHR(10), ' ') sql_text
          FROM gv$sql s
         WHERE s.sql_id = h.sql_id AND ROWNUM = 1) sql_text
  FROM gv$active_session_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
   AND UPPER('&&ash_data.') = 'Y'
 GROUP BY
       h.sql_id
 ORDER BY
       samples DESC
/
PRO
PRO Active Session History (by plan_operation)
PRO ~~~~~~~~~~~~~~~~~~~~~~
WITH
objs AS (
SELECT object_id,
       owner,
       object_name
  FROM dba_objects
 WHERE object_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
   AND object_type LIKE 'TABLE%'
   AND UPPER('&&ash_data.') = 'Y'
 UNION
SELECT o.object_id,
       o.owner,
       o.object_name
  FROM dba_indexes i,
       dba_objects o
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND o.object_name = i.index_name
   AND o.owner = i.owner
   AND o.object_type LIKE 'INDEX%'
   AND UPPER('&&ash_data.') = 'Y'
)
SELECT COUNT(*) samples,
       h.sql_plan_operation||' '||h.sql_plan_options plan_operation
  FROM gv$active_session_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
   AND UPPER('&&ash_data.') = 'Y'
 GROUP BY
       h.sql_plan_operation,
       h.sql_plan_options
 ORDER BY
       samples DESC
/
PRO
PRO Active Session History (by state, wait_class and event)
PRO ~~~~~~~~~~~~~~~~~~~~~~
WITH
objs AS (
SELECT object_id,
       owner,
       object_name
  FROM dba_objects
 WHERE object_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
   AND object_type LIKE 'TABLE%'
   AND UPPER('&&ash_data.') = 'Y'
 UNION
SELECT o.object_id,
       o.owner,
       o.object_name
  FROM dba_indexes i,
       dba_objects o
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND o.object_name = i.index_name
   AND o.owner = i.owner
   AND o.object_type LIKE 'INDEX%'
   AND UPPER('&&ash_data.') = 'Y'
)
SELECT COUNT(*) samples,
       h.session_state||' '||h.wait_class||' '||h.event state_wait_class_and_event
  FROM gv$active_session_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
   AND UPPER('&&ash_data.') = 'Y'
 GROUP BY
       h.session_state,
       h.wait_class,
       h.event
 ORDER BY
       samples DESC
/
PRO
PRO Active Session History (by object_name)
PRO ~~~~~~~~~~~~~~~~~~~~~~
WITH
objs AS (
SELECT object_id,
       owner,
       object_name
  FROM dba_objects
 WHERE object_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
   AND object_type LIKE 'TABLE%'
   AND UPPER('&&ash_data.') = 'Y'
 UNION
SELECT o.object_id,
       o.owner,
       o.object_name
  FROM dba_indexes i,
       dba_objects o
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND o.object_name = i.index_name
   AND o.owner = i.owner
   AND o.object_type LIKE 'INDEX%'
   AND UPPER('&&ash_data.') = 'Y'
)
SELECT COUNT(*) samples,
       o.owner||'.'||o.object_name object_name
  FROM gv$active_session_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
   AND UPPER('&&ash_data.') = 'Y'
 GROUP BY
       o.owner,
       o.object_name
 ORDER BY
       samples DESC
/
PRO
PRO Active Session History (detail)
PRO ~~~~~~~~~~~~~~~~~~~~~~
WITH
objs AS (
SELECT object_id,
       owner,
       object_name
  FROM dba_objects
 WHERE object_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
   AND object_type LIKE 'TABLE%'
   AND UPPER('&&ash_data.') = 'Y'
 UNION
SELECT o.object_id,
       o.owner,
       o.object_name
  FROM dba_indexes i,
       dba_objects o
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND o.object_name = i.index_name
   AND o.owner = i.owner
   AND o.object_type LIKE 'INDEX%'
   AND UPPER('&&ash_data.') = 'Y'
)
SELECT COUNT(*) samples,
       h.sql_id,
       h.sql_plan_hash_value,
       h.sql_plan_operation||' '||h.sql_plan_options plan_operation,
       h.session_state||' '||h.wait_class||' '||h.event state_wait_class_and_event,
       o.owner||'.'||o.object_name object_name
  FROM gv$active_session_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
   AND UPPER('&&ash_data.') = 'Y'
 GROUP BY
       h.sql_id,
       h.sql_plan_hash_value,
       h.sql_plan_operation,
       h.sql_plan_options,
       h.session_state,
       h.wait_class,
       h.event,
       o.owner,
       o.object_name
 ORDER BY
       h.sql_id,
       h.sql_plan_hash_value,
       h.sql_plan_operation,
       h.sql_plan_options,
       h.session_state,
       h.wait_class,
       h.event,
       o.owner,
       o.object_name
/
PRO
PRO AWR Active Session History (by sql_id)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
objs AS (
SELECT object_id,
       owner,
       object_name
  FROM dba_objects
 WHERE object_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
   AND object_type LIKE 'TABLE%'
   AND UPPER('&&ash_data.') = 'Y'
 UNION
SELECT o.object_id,
       o.owner,
       o.object_name
  FROM dba_indexes i,
       dba_objects o
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND o.object_name = i.index_name
   AND o.owner = i.owner
   AND o.object_type LIKE 'INDEX%'
   AND UPPER('&&ash_data.') = 'Y'
)
SELECT COUNT(*) samples,
       h.sql_id,
       (SELECT REPLACE(DBMS_LOB.substr(sql_text, 80 , 1), CHR(10), ' ') sql_text
          FROM dba_hist_sqltext s
         WHERE s.sql_id = h.sql_id AND ROWNUM = 1) sql_text
  FROM dba_hist_active_sess_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
   AND UPPER('&&ash_data.') = 'Y'
 GROUP BY
       h.sql_id
 ORDER BY
       samples DESC
/
PRO
PRO AWR Active Session History (by plan_operation)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
objs AS (
SELECT object_id,
       owner,
       object_name
  FROM dba_objects
 WHERE object_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
   AND object_type LIKE 'TABLE%'
   AND UPPER('&&ash_data.') = 'Y'
 UNION
SELECT o.object_id,
       o.owner,
       o.object_name
  FROM dba_indexes i,
       dba_objects o
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND o.object_name = i.index_name
   AND o.owner = i.owner
   AND o.object_type LIKE 'INDEX%'
   AND UPPER('&&ash_data.') = 'Y'
)
SELECT COUNT(*) samples,
       h.sql_plan_operation||' '||h.sql_plan_options plan_operation
  FROM dba_hist_active_sess_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
   AND UPPER('&&ash_data.') = 'Y'
 GROUP BY
       h.sql_plan_operation,
       h.sql_plan_options
 ORDER BY
       samples DESC
/
PRO
PRO AWR Active Session History (by state, wait_class and event)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
objs AS (
SELECT object_id,
       owner,
       object_name
  FROM dba_objects
 WHERE object_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
   AND object_type LIKE 'TABLE%'
   AND UPPER('&&ash_data.') = 'Y'
 UNION
SELECT o.object_id,
       o.owner,
       o.object_name
  FROM dba_indexes i,
       dba_objects o
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND o.object_name = i.index_name
   AND o.owner = i.owner
   AND o.object_type LIKE 'INDEX%'
   AND UPPER('&&ash_data.') = 'Y'
)
SELECT COUNT(*) samples,
       h.session_state||' '||h.wait_class||' '||h.event state_wait_class_and_event
  FROM dba_hist_active_sess_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
   AND UPPER('&&ash_data.') = 'Y'
 GROUP BY
       h.session_state,
       h.wait_class,
       h.event
 ORDER BY
       samples DESC
/
PRO
PRO AWR Active Session History (by object_name)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
objs AS (
SELECT object_id,
       owner,
       object_name
  FROM dba_objects
 WHERE object_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
   AND object_type LIKE 'TABLE%'
   AND UPPER('&&ash_data.') = 'Y'
 UNION
SELECT o.object_id,
       o.owner,
       o.object_name
  FROM dba_indexes i,
       dba_objects o
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND o.object_name = i.index_name
   AND o.owner = i.owner
   AND o.object_type LIKE 'INDEX%'
   AND UPPER('&&ash_data.') = 'Y'
)
SELECT COUNT(*) samples,
       o.owner||'.'||o.object_name object_name
  FROM dba_hist_active_sess_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
   AND UPPER('&&ash_data.') = 'Y'
 GROUP BY
       o.owner,
       o.object_name
 ORDER BY
       samples DESC
/
PRO
PRO AWR Active Session History (detail)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
objs AS (
SELECT object_id,
       owner,
       object_name
  FROM dba_objects
 WHERE object_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
   AND object_type LIKE 'TABLE%'
   AND UPPER('&&ash_data.') = 'Y'
 UNION
SELECT o.object_id,
       o.owner,
       o.object_name
  FROM dba_indexes i,
       dba_objects o
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
   AND o.object_name = i.index_name
   AND o.owner = i.owner
   AND o.object_type LIKE 'INDEX%'
   AND UPPER('&&ash_data.') = 'Y'
)
SELECT COUNT(*) samples,
       h.sql_id,
       h.sql_plan_hash_value,
       h.sql_plan_operation||' '||h.sql_plan_options plan_operation,
       h.session_state||' '||h.wait_class||' '||h.event state_wait_class_and_event,
       o.owner||'.'||o.object_name object_name
  FROM dba_hist_active_sess_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
   AND UPPER('&&ash_data.') = 'Y'
 GROUP BY
       h.sql_id,
       h.sql_plan_hash_value,
       h.sql_plan_operation,
       h.sql_plan_options,
       h.session_state,
       h.wait_class,
       h.event,
       o.owner,
       o.object_name
 ORDER BY
       h.sql_id,
       h.sql_plan_hash_value,
       h.sql_plan_operation,
       h.sql_plan_options,
       h.session_state,
       h.wait_class,
       h.event,
       o.owner,
       o.object_name
/       
PRO
PRO DBMS_SPACE.CREATE_TABLE_COST
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
DECLARE
  l_used_bytes NUMBER;
  l_alloc_bytes NUMBER;
  l_dba_tables dba_tables%ROWTYPE;
BEGIN
  SELECT * INTO l_dba_tables FROM dba_tables WHERE table_name = UPPER(TRIM('&&tbl_name.')) AND owner = UPPER(TRIM('&&tbl_owner.'));
  IF l_dba_tables.tablespace_name IS NULL THEN
    SELECT tablespace_name INTO l_dba_tables.tablespace_name FROM dba_segments WHERE segment_name = UPPER(TRIM('&&tbl_name.')) AND owner = UPPER(TRIM('&&tbl_owner.')) AND segment_type LIKE 'TABLE%' AND ROWNUM = 1;
  END IF;
  DBMS_SPACE.CREATE_TABLE_COST (
    tablespace_name => l_dba_tables.tablespace_name,
    avg_row_size    => l_dba_tables.avg_row_len,
    row_count       => l_dba_tables.num_rows,
    pct_free        => l_dba_tables.pct_free,
    used_bytes      => l_used_bytes,
    alloc_bytes     => l_alloc_bytes
  ); 
  DBMS_OUTPUT.PUT_LINE('TABLE estimated_used_bytes:'||l_used_bytes||', estimated_alloc_bytes:'||l_alloc_bytes);
END;
/
PRO
PRO DBMS_SPACE.CREATE_INDEX_COST
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
DECLARE
  l_used_bytes NUMBER;
  l_alloc_bytes NUMBER;
  t_used_bytes NUMBER := 0;
  t_alloc_bytes NUMBER := 0;
BEGIN
  FOR i IN (SELECT owner, index_name, DBMS_METADATA.GET_DDL('INDEX', index_name, owner) index_metadata FROM dba_indexes WHERE table_name = UPPER(TRIM('&&tbl_name.')) AND table_owner = UPPER(TRIM('&&tbl_owner.')) ORDER BY owner, index_name)
  LOOP
    DBMS_SPACE.CREATE_INDEX_COST (
      ddl         => i.index_metadata,
      used_bytes  => l_used_bytes,
      alloc_bytes => l_alloc_bytes
    ); 
    t_used_bytes := t_used_bytes + l_used_bytes;
    t_alloc_bytes := t_alloc_bytes + l_alloc_bytes;
    DBMS_OUTPUT.PUT_LINE(i.owner||'.'||i.index_name||' estimated_used_bytes:'||l_used_bytes||', estimated_alloc_bytes:'||l_alloc_bytes);
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('TOTAL INDEXES estimated_used_bytes:'||t_used_bytes||', estimated_alloc_bytes:'||t_alloc_bytes);
END;
/
PRO
PRO Table Metadata
PRO ~~~~~~~~~~~~~~
SET HEA OFF LONG 400000 LONGC 20000;
SELECT DBMS_METADATA.GET_DDL('TABLE', UPPER(TRIM('&&tbl_name.')), UPPER(TRIM('&&tbl_owner.'))) table_metadata
  FROM DUAL
/
PRO
PRO Index Metadata
PRO ~~~~~~~~~~~~~~
SELECT DBMS_METADATA.GET_DDL('INDEX', index_name, owner) index_metadata
  FROM dba_indexes
 WHERE table_name = UPPER(TRIM('&&tbl_name.'))
   AND table_owner = UPPER(TRIM('&&tbl_owner.'))
 ORDER BY
       owner,
       index_name
/
PRO
PRO Tablespaces
PRO ~~~~~~~~~~~
SET HEA ON;
SELECT *
  FROM dba_tablespaces
 ORDER BY
       tablespace_name
/
-- spool off and cleanup
PRO
PRO &&spool_file_name..txt was generated
SET FEED ON VER ON HEA ON LIN 80 PAGES 14 LONG 80 LONGC 80 TRIMS OFF SERVEROUT OFF;
SPO OFF;
UNDEF 1 2 3
-- end

