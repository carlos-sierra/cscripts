----------------------------------------------------------------------------------------
--
-- File name:   cs_top_segments_pdb.sql
--
-- Purpose:     PDB Top Segments as per Size
--
-- Author:      Carlos Sierra
--
-- Version:     2020/04/19
--
-- Usage:       Execute connected to PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_segments_pdb.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
DEF top_segments = '30';
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_top_segments_pdb';
--
SELECT tablespace_name 
  FROM dba_tablespaces
 ORDER BY 1
/
PRO
PRO 1. Enter Tablespace Name (opt):
DEF cs2_tablespace_name = '&1.';
UNDEF 1;
--
SELECT '&&cs_file_prefix._&&cs_script_name.'||CASE WHEN '&&cs2_tablespace_name.' IS NOT NULL THEN '_&&cs2_tablespace_name.' END AS cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql &&cs2_tablespace_name.
@@cs_internal/cs_spool_id.sql
--
PRO TABLESPACE   : "&&cs2_tablespace_name."
--
COL rn FOR A5 HEA 'TOP#';
COL owner FOR A30 TRUNC;
COL segment_name FOR A30 TRUNC;
COL partition_name FOR A30 TRUNC;
COL mbs FOR 999,990;
COL gb FOR 99,990.000 HEA 'SEGMENT|GB';
COL table_name FOR A30 TRUNC;
COL column_name FOR A30 TRUNC;
COL tablespace_name FOR A30 TRUNC;
COL securefile FOR A6 HEA 'SECURE|FILE';
COL segment_space_management FOR A10 HEA 'SEGMENT|SPACE|MANAGEMENT';
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF gb ON REPORT;
--
PRO
PRO TOP &&top_segments. SEGMENTS (DBA_SEGMENTS)
PRO ~~~~~~~~~~~~~~~
SELECT LPAD(ROW_NUMBER() OVER (ORDER BY s.bytes DESC, s.owner, s.segment_name, s.partition_name), LENGTH('&&top_segments.'), '0') AS rn,
       s.bytes / POWER(10, 9) AS gb,
       s.owner, s.segment_name, s.partition_name,
       CASE WHEN s.segment_type = 'LOBSEGMENT' THEN 'LOB' ELSE s.segment_type END AS segment_type,
       COALESCE(l.table_name, i.table_name) AS table_name,
       l.column_name,
       l.securefile,
       s.tablespace_name,
       t.segment_space_management
  FROM dba_segments s,
       dba_tablespaces t,
       dba_lobs l,
       dba_indexes i
 WHERE s.tablespace_name = COALESCE('&&cs2_tablespace_name.', s.tablespace_name)
   AND t.tablespace_name = s.tablespace_name
   AND l.owner(+) = s.owner
   AND l.segment_name(+) = s.segment_name
   AND i.owner(+) = s.owner
   AND i.index_name(+) = s.segment_name
 ORDER BY
       s.bytes DESC, s.owner, s.segment_name, s.partition_name
 FETCH FIRST &&top_segments. ROWS ONLY
/
--
COL unformatted_gb FOR 99,990.000 HEA 'UNFORMATTED|GB';
COL formatted_gb FOR 99,990.000 HEA 'FORMATTED|GB';
COL fs1_gb FOR 99,990.000 HEA '0-25% FREE|GB (FS1)';
COL fs2_gb FOR 99,990.000 HEA '25-50% FREE|GB (FS2)';
COL fs3_gb FOR 99,990.000 HEA '50-75% FREE|GB (FS3)';
COL fs4_gb FOR 99,990.000 HEA '75-100% FREE|GB (FS4)';
COL full_gb FOR 99,990.000 HEA 'FULL|GB';
COL free_gb FOR 99,990.000 HEA 'FREE GB|(ESTIMATED)';
--
COMPUTE SUM LABEL 'TOTAL' OF gb unformatted_gb formatted_gb fs1_gb fs2_gb fs3_gb fs4_gb full_gb free_gb ON REPORT;
--
PRO
PRO TOP &&top_segments. SEGMENTS (DBMS_SPACE.space_usage i.e. below HWM) ASSM Tablespaces, excluding SECUREFILE LOBs
PRO ~~~~~~~~~~~~~~~
WITH
FUNCTION space_usage (p_segment_owner IN VARCHAR2, p_segment_name IN VARCHAR2, p_segment_type IN VARCHAR2, p_bytes_type IN VARCHAR2, p_partition_name IN VARCHAR2 DEFAULT NULL)
RETURN NUMBER
IS
  l_unformatted_blocks NUMBER;
  l_unformatted_bytes  NUMBER;
  l_fs1_blocks         NUMBER;
  l_fs1_bytes          NUMBER;
  l_fs2_blocks         NUMBER;
  l_fs2_bytes          NUMBER;
  l_fs3_blocks         NUMBER;
  l_fs3_bytes          NUMBER;
  l_fs4_blocks         NUMBER;
  l_fs4_bytes          NUMBER;
  l_full_blocks        NUMBER;
  l_full_bytes         NUMBER;
BEGIN
  DBMS_SPACE.space_usage(
    segment_owner      => p_segment_owner     ,
    segment_name       => p_segment_name      ,
    segment_type       => p_segment_type      ,
    unformatted_blocks => l_unformatted_blocks,
    unformatted_bytes  => l_unformatted_bytes ,
    fs1_blocks         => l_fs1_blocks        ,
    fs1_bytes          => l_fs1_bytes         ,
    fs2_blocks         => l_fs2_blocks        ,
    fs2_bytes          => l_fs2_bytes         ,
    fs3_blocks         => l_fs3_blocks        ,
    fs3_bytes          => l_fs3_bytes         ,
    fs4_blocks         => l_fs4_blocks        ,
    fs4_bytes          => l_fs4_bytes         ,
    full_blocks        => l_full_blocks       ,
    full_bytes         => l_full_bytes        ,
    partition_name     => p_partition_name
  );
  IF p_bytes_type = 'UNFORMATTED' THEN RETURN l_unformatted_bytes; END IF;
  IF p_bytes_type = 'FS1'         THEN RETURN l_fs1_bytes;         END IF;
  IF p_bytes_type = 'FS2'         THEN RETURN l_fs2_bytes;         END IF;
  IF p_bytes_type = 'FS3'         THEN RETURN l_fs3_bytes;         END IF;
  IF p_bytes_type = 'FS4'         THEN RETURN l_fs4_bytes;         END IF;
  IF p_bytes_type = 'FULL'        THEN RETURN l_full_bytes;        END IF;
  RETURN NULL;
END space_usage;
top_segments AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       LPAD(ROW_NUMBER() OVER (ORDER BY s.bytes DESC, s.owner, s.segment_name, s.partition_name), LENGTH('&&top_segments.'), '0') AS rn,
       s.bytes / POWER(10, 9) AS gb,
       s.owner, s.segment_name, s.partition_name,
       CASE WHEN s.segment_type = 'LOBSEGMENT' THEN 'LOB' ELSE s.segment_type END AS segment_type,
       COALESCE(l.table_name, i.table_name) AS table_name,
       l.column_name,
       l.securefile,
       s.tablespace_name,
       t.segment_space_management
  FROM dba_segments s,
       dba_tablespaces t,
       dba_lobs l,
       dba_indexes i
 WHERE s.tablespace_name = COALESCE('&&cs2_tablespace_name.', s.tablespace_name)
   AND t.tablespace_name = s.tablespace_name
   AND l.owner(+) = s.owner
   AND l.segment_name(+) = s.segment_name
   AND i.owner(+) = s.owner
   AND i.index_name(+) = s.segment_name
 ORDER BY
       s.bytes DESC, s.owner, s.segment_name, s.partition_name
 FETCH FIRST &&top_segments. ROWS ONLY
),
top_segments_extended AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       rn,
       gb, 
       space_usage(owner, segment_name, segment_type, 'UNFORMATTED', partition_name) AS unformatted_bytes,
       space_usage(owner, segment_name, segment_type, 'FS1', partition_name) AS fs1_bytes,
       space_usage(owner, segment_name, segment_type, 'FS2', partition_name) AS fs2_bytes,
       space_usage(owner, segment_name, segment_type, 'FS3', partition_name) AS fs3_bytes,
       space_usage(owner, segment_name, segment_type, 'FS4', partition_name) AS fs4_bytes,
       space_usage(owner, segment_name, segment_type, 'FULL', partition_name) AS full_bytes,
       owner, segment_name, partition_name, segment_type, table_name, column_name, securefile, tablespace_name, segment_space_management
  FROM top_segments
 WHERE segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION', 'INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION', 'CLUSTER', 'LOB', 'LOB PARTITION', 'LOB SUBPARTITION')
   AND segment_space_management = 'AUTO'
   AND (securefile IS NULL OR securefile = 'NO')
)
SELECT rn,
       gb, 
       unformatted_bytes / POWER(10, 9) AS unformatted_gb,
       (fs1_bytes + fs2_bytes + fs3_bytes + fs4_bytes + full_bytes) / POWER(10, 9) AS formatted_gb,
       fs1_bytes / POWER(10, 9) AS fs1_gb,
       fs2_bytes / POWER(10, 9) AS fs2_gb,
       fs3_bytes / POWER(10, 9) AS fs3_gb,
       fs4_bytes / POWER(10, 9) AS fs4_gb,
       full_bytes / POWER(10, 9) AS full_gb,
       (unformatted_bytes + (fs1_bytes * 0.125) + (fs2_bytes * 0.375) + (fs3_bytes * 0.625) + (fs4_bytes * 0.875)) / POWER(10, 9) AS free_gb,
       owner, segment_name, partition_name, segment_type, table_name, column_name, securefile, tablespace_name, segment_space_management
  FROM top_segments_extended
/
--
COL segment_size_gb FOR 99,990.000 HEA 'SIZE|GB';
COL used_gb FOR 99,990.000 HEA 'USED|GB';
COL expired_gb FOR 99,990.000 HEA 'FREE GB|EXPIRED';
COL unexpired_gb FOR 99,990.000 HEA 'FREE GB|UNEXPIRED';
COL free_gb FOR 99,990.000 HEA 'FREE GB';
COL used_plus_free_gb FOR 99,990.000 HEA 'USED+FREE|GB';
--
COMPUTE SUM LABEL 'TOTAL' OF gb segment_size_gb used_gb expired_gb unexpired_gb free_gb used_plus_free_gb ON REPORT;
--
PRO
PRO TOP &&top_segments. SEGMENTS (DBMS_SPACE.space_usage i.e. below HWM) SECUREFILE LOBs on ASSM Tablespaces
PRO ~~~~~~~~~~~~~~~
WITH
FUNCTION space_usage (p_segment_owner IN VARCHAR2, p_segment_name IN VARCHAR2, p_segment_type IN VARCHAR2, p_bytes_type IN VARCHAR2, p_partition_name IN VARCHAR2 DEFAULT NULL)
RETURN NUMBER
IS
  l_segment_size_blocks NUMBER;
  l_segment_size_bytes  NUMBER;
  l_used_blocks         NUMBER;
  l_used_bytes          NUMBER;
  l_expired_blocks      NUMBER;
  l_expired_bytes       NUMBER;
  l_unexpired_blocks    NUMBER;
  l_unexpired_bytes     NUMBER;
BEGIN
  DBMS_SPACE.space_usage(
    segment_owner       => p_segment_owner      ,
    segment_name        => p_segment_name       ,
    segment_type        => p_segment_type       ,
    segment_size_blocks => l_segment_size_blocks,
    segment_size_bytes  => l_segment_size_bytes ,
    used_blocks         => l_used_blocks        ,
    used_bytes          => l_used_bytes         ,
    expired_blocks      => l_expired_blocks     ,
    expired_bytes       => l_expired_bytes      ,
    unexpired_blocks    => l_unexpired_blocks   ,
    unexpired_bytes     => l_unexpired_bytes    ,
    partition_name      => p_partition_name
  );
  IF p_bytes_type = 'SEGMENT_SIZE' THEN RETURN l_segment_size_bytes; END IF;
  IF p_bytes_type = 'USED'         THEN RETURN l_used_bytes;         END IF;
  IF p_bytes_type = 'EXPIRED'      THEN RETURN l_expired_bytes;      END IF;
  IF p_bytes_type = 'UNEXPIRED'    THEN RETURN l_unexpired_bytes;    END IF;
  RETURN NULL;
END space_usage;
top_segments AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       LPAD(ROW_NUMBER() OVER (ORDER BY s.bytes DESC, s.owner, s.segment_name, s.partition_name), LENGTH('&&top_segments.'), '0') AS rn,
       s.bytes / POWER(10, 9) AS gb,
       s.owner, s.segment_name, s.partition_name,
       CASE WHEN s.segment_type = 'LOBSEGMENT' THEN 'LOB' ELSE s.segment_type END AS segment_type,
       COALESCE(l.table_name, i.table_name) AS table_name,
       l.column_name,
       l.securefile,
       s.tablespace_name,
       t.segment_space_management
  FROM dba_segments s,
       dba_tablespaces t,
       dba_lobs l,
       dba_indexes i
 WHERE s.tablespace_name = COALESCE('&&cs2_tablespace_name.', s.tablespace_name)
   AND t.tablespace_name = s.tablespace_name
   AND l.owner(+) = s.owner
   AND l.segment_name(+) = s.segment_name
   AND i.owner(+) = s.owner
   AND i.index_name(+) = s.segment_name
 ORDER BY
       s.bytes DESC, s.owner, s.segment_name, s.partition_name
 FETCH FIRST &&top_segments. ROWS ONLY
),
top_segments_extended AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       rn,
       gb, 
       space_usage(owner, segment_name, segment_type, 'SEGMENT_SIZE', partition_name) AS segment_size_bytes,
       space_usage(owner, segment_name, segment_type, 'USED', partition_name) AS used_bytes,
       space_usage(owner, segment_name, segment_type, 'EXPIRED', partition_name) AS expired_bytes,
       space_usage(owner, segment_name, segment_type, 'UNEXPIRED', partition_name) AS unexpired_bytes,
       owner, segment_name, partition_name, segment_type, table_name, column_name, securefile, tablespace_name, segment_space_management
  FROM top_segments
 WHERE segment_type IN ('LOB', 'LOB PARTITION', 'LOB SUBPARTITION')
   AND segment_space_management = 'AUTO'
   AND securefile = 'YES'
)
SELECT rn,
       gb, 
       segment_size_bytes / POWER(10, 9) AS segment_size_gb,
       used_bytes / POWER(10, 9) AS used_gb,
       expired_bytes / POWER(10, 9) AS expired_gb,
       unexpired_bytes / POWER(10, 9) AS unexpired_gb,
       (expired_bytes + unexpired_bytes) / POWER(10, 9) AS free_gb,
       (used_bytes + expired_bytes + unexpired_bytes) / POWER(10, 9) AS used_plus_free_gb,
       owner, segment_name, partition_name, segment_type, table_name, column_name, securefile, tablespace_name, segment_space_management
  FROM top_segments_extended
/
--
COL total_gb FOR 99,990.000 HEA 'TOTAL|GB';
COL unused_gb FOR 99,990.000 HEA 'UNUSED|GB';
--
COMPUTE SUM LABEL 'TOTAL' OF gb total_gb unused_gb ON REPORT;
--
PRO
PRO TOP &&top_segments. SEGMENTS (DBMS_SPACE.unused_space i.e. above HWM)
PRO ~~~~~~~~~~~~~~~
WITH
FUNCTION unused_space (p_segment_owner IN VARCHAR2, p_segment_name IN VARCHAR2, p_segment_type IN VARCHAR2, p_bytes_type IN VARCHAR2, p_partition_name IN VARCHAR2 DEFAULT NULL)
RETURN NUMBER
IS
  l_total_blocks              NUMBER;
  l_total_bytes               NUMBER;
  l_unused_blocks             NUMBER;
  l_unused_bytes              NUMBER;
  l_last_used_extent_file_id  NUMBER;
  l_last_used_extent_block_id NUMBER;
  l_last_used_block           NUMBER;
BEGIN
  DBMS_SPACE.unused_space(
    segment_owner             => p_segment_owner            ,
    segment_name              => p_segment_name             ,
    segment_type              => p_segment_type             ,
    total_blocks              => l_total_blocks             ,
    total_bytes               => l_total_bytes              ,
    unused_blocks             => l_unused_blocks            ,
    unused_bytes              => l_unused_bytes             ,
    last_used_extent_file_id  => l_last_used_extent_file_id ,
    last_used_extent_block_id => l_last_used_extent_block_id,
    last_used_block           => l_last_used_block          ,
    partition_name            => p_partition_name
  );
  IF p_bytes_type = 'TOTAL'  THEN RETURN l_total_bytes;  END IF;
  IF p_bytes_type = 'UNUSED' THEN RETURN l_unused_bytes; END IF;
  RETURN NULL;
END unused_space;
top_segments AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       LPAD(ROW_NUMBER() OVER (ORDER BY s.bytes DESC, s.owner, s.segment_name, s.partition_name), LENGTH('&&top_segments.'), '0') AS rn,
       s.bytes / POWER(10, 9) AS gb,
       s.owner, s.segment_name, s.partition_name,
       CASE WHEN s.segment_type = 'LOBSEGMENT' THEN 'LOB' ELSE s.segment_type END AS segment_type,
       COALESCE(l.table_name, i.table_name) AS table_name,
       l.column_name,
       l.securefile,
       s.tablespace_name,
       t.segment_space_management
  FROM dba_segments s,
       dba_tablespaces t,
       dba_lobs l,
       dba_indexes i
 WHERE s.tablespace_name = COALESCE('&&cs2_tablespace_name.', s.tablespace_name)
   AND t.tablespace_name = s.tablespace_name
   AND l.owner(+) = s.owner
   AND l.segment_name(+) = s.segment_name
   AND i.owner(+) = s.owner
   AND i.index_name(+) = s.segment_name
 ORDER BY
       s.bytes DESC, s.owner, s.segment_name, s.partition_name
 FETCH FIRST &&top_segments. ROWS ONLY
),
top_segments_extended AS (
SELECT /*+ MATERIALIZE NO_MERGE */ 
       rn,
       gb, 
       unused_space(owner, segment_name, segment_type, 'TOTAL', partition_name) AS total_bytes,
       unused_space(owner, segment_name, segment_type, 'UNUSED', partition_name) AS unused_bytes,
       owner, segment_name, partition_name, segment_type, table_name, column_name, securefile, tablespace_name, segment_space_management
  FROM top_segments
 WHERE segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION', 'INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION', 'CLUSTER', 'LOB', 'LOB PARTITION', 'LOB SUBPARTITION')
)
SELECT rn,
       gb, 
       total_bytes / POWER(10, 9) AS total_gb,
       unused_bytes / POWER(10, 9) AS unused_gb,
       owner, segment_name, partition_name, segment_type, table_name, column_name, securefile, tablespace_name, segment_space_management
  FROM top_segments_extended
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql &&cs2_tablespace_name.
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--