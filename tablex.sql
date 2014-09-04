----------------------------------------------------------------------------------------
--
-- File name:   table.sql
--
-- Purpose:     Reports CBO Statistics for a given Table
--
-- Author:      Carlos Sierra
--
-- Version:     2014/01/24
--
-- Usage:       This script inputs two parameters. Parameter 1 is the name of the Table
--              and parameter 2 the owner.
--
-- Example:     @tablex.sql sales sh
--
--  Notes:      Developed and tested on 11.2.0.3
--             
---------------------------------------------------------------------------------------
--
CL COL;
SET FEED OFF VER OFF HEA ON LIN 2000 PAGES 50 TIMI OFF LONG 40000 LONGC 200 TRIMS ON AUTOT OFF;
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
-- spool and sql_text
SPO tablex_&&tbl_owner._&&tbl_name..txt;
PRO Tables Accessed 
PRO ~~~~~~~~~~~~~~~
COL table_name FOR A50;
SELECT owner||'.'||table_name table_name,
       partitioned,
       degree,
       temporary,
       blocks,
       num_rows,
       sample_size,
       TO_CHAR(last_analyzed, 'YYYY-MM-DD HH24:MI:SS') last_analyzed,
       global_stats,
       compression
  FROM dba_tables
 WHERE table_name = UPPER(TRIM('&&tbl_name.'))
   AND owner = UPPER(TRIM('&&tbl_owner.'))
 ORDER BY
       owner,
       table_name;
PRO
PRO Indexes 
PRO ~~~~~~~
COL table_and_index_name FOR A70;
COL degree FOR A6;
SELECT i.table_owner||'.'||i.table_name||' '||i.owner||'.'||i.index_name table_and_index_name,
       i.partitioned,
       i.degree,
       i.index_type,
       i.uniqueness,
       (SELECT COUNT(*) FROM dba_ind_columns ic WHERE ic.index_owner = i.owner AND ic.index_name = i.index_name) columns,
       i.status,
       i.visibility,
       i.blevel,
       i.leaf_blocks,
       i.distinct_keys,
       i.clustering_factor,
       i.num_rows,
       i.sample_size,
       TO_CHAR(i.last_analyzed, 'YYYY-MM-DD HH24:MI:SS') last_analyzed,
       i.global_stats
  FROM dba_indexes i
 WHERE i.table_name = UPPER(TRIM('&&tbl_name.'))
   AND i.table_owner = UPPER(TRIM('&&tbl_owner.'))
 ORDER BY
       i.table_owner,
       i.table_name,
       i.owner,
       i.index_name;
-- compute low and high values for each table column
DELETE plan_table WHERE statement_id = 'low_high';
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
    INSERT INTO plan_table (statement_id, object_owner, object_name, object_alias, partition_start, partition_stop)
    VALUES ('low_high', i.owner, i.table_name, i.column_name, l_low, l_high);
  END LOOP;
END;
/
PRO
PRO Table Columns 
PRO ~~~~~~~~~~~~~
SET LONG 200 LONGC 20;
COL table_and_column_name FOR A70;
COL data_type FOR A20;
COL data_default FOR A20;
COL low_value FOR A32;
COL high_value FOR A32;
SELECT c.owner||'.'||c.table_name||' '||c.column_name table_and_column_name,
       c.data_type,
       c.nullable,
       c.data_default,
       c.num_distinct,
       NVL(p.partition_start, c.low_value) low_value,
       NVL(p.partition_stop, c.high_value) high_value,
       c.density,
       c.num_nulls,
       c.num_buckets,
       c.histogram,
       c.sample_size,
       TO_CHAR(c.last_analyzed, 'YYYY-MM-DD HH24:MI:SS') last_analyzed,
       c.global_stats,
       c.avg_col_len
  FROM dba_tab_cols c,
       plan_table p
 WHERE c.table_name = UPPER(TRIM('&&tbl_name.'))
   AND c.owner = UPPER(TRIM('&&tbl_owner.'))
   AND p.statement_id(+) = 'low_high'
   AND p.object_owner(+) = c.owner
   AND p.object_name(+) = c.table_name
   AND p.object_alias(+) = c.column_name
 ORDER BY
       c.owner,
       c.table_name,
       c.column_name;
PRO
PRO Index Columns 
PRO ~~~~~~~~~~~~~
COL index_and_column_name FOR A70;
SELECT i.index_owner||'.'||i.index_name||' '||c.column_name index_and_column_name,
       c.data_type,
       c.nullable,
       c.data_default,
       c.num_distinct,
       NVL(p.partition_start, c.low_value) low_value,
       NVL(p.partition_stop, c.high_value) high_value,
       c.density,
       c.num_nulls,
       c.num_buckets,
       c.histogram,
       c.sample_size,
       TO_CHAR(c.last_analyzed, 'YYYY-MM-DD HH24:MI:SS') last_analyzed,
       c.global_stats,
       c.avg_col_len
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
   AND p.object_alias(+) = c.column_name
 ORDER BY
       i.index_owner,
       i.index_name,
       i.column_position;
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
)
SELECT COUNT(*) samples,
       h.sql_id,
       (SELECT REPLACE(SUBSTR(sql_text, 1, 80), CHR(10), ' ') sql_text
          FROM gv$sql s
         WHERE s.sql_id = h.sql_id AND ROWNUM = 1) sql_text
  FROM gv$active_session_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
 GROUP BY
       h.sql_id
 ORDER BY
       samples DESC;
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
)
SELECT COUNT(*) samples,
       h.sql_plan_operation||' '||h.sql_plan_options plan_operation
  FROM gv$active_session_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
 GROUP BY
       h.sql_plan_operation,
       h.sql_plan_options
 ORDER BY
       samples DESC;
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
)
SELECT COUNT(*) samples,
       h.session_state||' '||h.wait_class||' '||h.event state_wait_class_and_event
  FROM gv$active_session_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
 GROUP BY
       h.session_state,
       h.wait_class,
       h.event
 ORDER BY
       samples DESC;
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
)
SELECT COUNT(*) samples,
       o.owner||'.'||o.object_name object_name
  FROM gv$active_session_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
 GROUP BY
       o.owner,
       o.object_name
 ORDER BY
       samples DESC;
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
       o.object_name;
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
)
SELECT COUNT(*) samples,
       h.sql_id,
       (SELECT REPLACE(DBMS_LOB.substr(sql_text, 80 , 1), CHR(10), ' ') sql_text
          FROM dba_hist_sqltext s
         WHERE s.sql_id = h.sql_id AND ROWNUM = 1) sql_text
  FROM dba_hist_active_sess_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
 GROUP BY
       h.sql_id
 ORDER BY
       samples DESC;
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
)
SELECT COUNT(*) samples,
       h.sql_plan_operation||' '||h.sql_plan_options plan_operation
  FROM dba_hist_active_sess_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
 GROUP BY
       h.sql_plan_operation,
       h.sql_plan_options
 ORDER BY
       samples DESC;
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
)
SELECT COUNT(*) samples,
       h.session_state||' '||h.wait_class||' '||h.event state_wait_class_and_event
  FROM dba_hist_active_sess_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
 GROUP BY
       h.session_state,
       h.wait_class,
       h.event
 ORDER BY
       samples DESC;
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
)
SELECT COUNT(*) samples,
       o.owner||'.'||o.object_name object_name
  FROM dba_hist_active_sess_history h, 
       objs o
 WHERE o.object_id = h.current_obj#
 GROUP BY
       o.owner,
       o.object_name
 ORDER BY
       samples DESC;
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
       o.object_name;       
  
 
-- spool off and cleanup
PRO
PRO tablex_&&tbl_owner._&&tbl_name..txt was generated
SET FEED ON VER ON LIN 80 PAGES 14 LONG 80 LONGC 80 TRIMS OFF;
SPO OFF;
UNDEF 1 2
-- end

