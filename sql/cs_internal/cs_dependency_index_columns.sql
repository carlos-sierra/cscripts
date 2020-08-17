COL table_owner FOR A30 HEA 'Table Owner';
COL table_name FOR A30 HEA 'Table Name';
COL index_name FOR A30 HEA 'Index Name';
COL column_position FOR 999 HEA 'Pos';
COL column_name FOR A30 HEA 'Column Name';
COL data_type FOR A33 HEA 'Data Type';
COL data_length FOR 999,999,990 HEA 'Data Length';
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
--
BRE ON table_owner ON table_name ON index_name SKIP 1;
--
PRO
PRO INDEX COLUMNS (dba_ind_columns) 
PRO ~~~~~~~~~~~~~
WITH /* INDEXES */
v_sqlarea_m AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(sqlarea) */ 
       DISTINCT 
       hash_value, address
  FROM v$sqlarea 
 WHERE sql_id = '&&cs_sql_id.'
),
v_object_dependency_m AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(obj_dependency) */ 
       DISTINCT 
       o.to_owner, o.to_name
      --  o.to_hash, o.to_address 
  FROM v$object_dependency o,
       v_sqlarea_m s
 WHERE o.from_hash = s.hash_value 
   AND o.from_address = s.address
   AND o.to_type = 2 -- table
),
-- v_db_object_cache_m AS (
-- SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(obj_cache) */ 
--        DISTINCT 
--        SUBSTR(c.owner,1,30) AS object_owner, 
--        SUBSTR(c.name,1,30) AS object_name 
--   FROM v$db_object_cache c,
--        v_object_dependency_m d
--  WHERE c.type IN ('TABLE','VIEW') 
--    AND c.hash_value = d.to_hash
--    AND c.addr = d.to_address 
-- ),
dba_tables_m AS (
SELECT /*+ MATERIALIZE NO_MERGE QB_NAME(dba_tables) */ 
       t.owner, 
       t.table_name
  FROM dba_tables t,
       v_object_dependency_m o
      --  v_db_object_cache_m c
--  WHERE t.owner = c.object_owner
--    AND t.table_name = c.object_name 
 WHERE t.owner = o.to_owner
   AND t.table_name = o.to_name 
)
SELECT /*+ QB_NAME(get_stats) */
       i.table_owner,
       i.table_name,
       i.index_name,
       i.column_position,
       c.column_name,
       c.data_type,
       c.data_length,
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
       c.avg_col_len
  FROM dba_tables_m t,
       dba_ind_columns i,
       dba_tab_cols c
 WHERE i.table_owner = t.owner
   AND i.table_name = t.table_name
   AND c.owner = i.table_owner
   AND c.table_name = i.table_name
   AND c.column_name = i.column_name
 ORDER BY
       i.table_owner,
       i.table_name,
       i.index_name,
       i.column_position
/
--
CL BRE;
--