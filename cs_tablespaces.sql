----------------------------------------------------------------------------------------
--
-- File name:   cs_tablespaces.sql
--
-- Purpose:     Tablespace Utilization (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/09
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Specify if internal tablespaces would be included in report
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_tablespaces.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
DEF permanent = 'Y';
DEF undo = 'Y';
DEF temporary = 'Y';
-- order_by: [{pdb_name, tablespace_name}|max_size_gb DESC|allocated_gb DESC|used_gb DESC|free_gb DESC]
DEF order_by = 'pdb_name, tablespace_name';
DEF rows = '999';
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_tablespaces';
--
PRO 1. Include internal (i.e. SYSTEM, SYSAUX, TEMPORARY, UNDO, ETC.): [{N}|Y] 
DEF include_internal = '&1.';
UNDEF 1;
COL include_internal NEW_V include_internal NOPRI;
SELECT NVL(UPPER(SUBSTR(TRIM('&&include_internal.'),1)),'N') include_internal FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&include_internal."
@@cs_internal/cs_spool_id.sql
--
PRO INTERNAL TBS : &&include_internal.
--
CLEAR BREAK COMPUTE;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF allocated_gb used_gb free_gb max_size_gb ON REPORT; 
--
COL pdb_name FOR A30;
COL tablespace_name FOR A30;
COL allocated_gb FOR 999,990.000 HEA 'ALLOCATED|SPACE (GB)';
COL used_gb FOR 999,990.000 HEA 'USED|SPACE (GB)';
COL used_percent FOR 990.0 HEA 'USED|PERC';
COL free_gb FOR 999,990.000 HEA 'FREE|SPACE (GB)';
COL free_percent FOR 990.0 HEA 'FREE|PERC';
COL max_size_gb FOR 999,990.000 HEA 'MAX|SIZE (GB)';
COL met_used_space_GB FOR 999,990.000 HEA 'METRICS|USED|SPACE (GB)';
COL met_used_percent FOR 990.0 HEA 'METRICS|USED|PERC';
--
PRO
PRO CDB
PRO ~~~
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
       ts.bigfile,
       ts.block_size,
       NVL(t.bytes, 0) allocated_space_bytes,
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
       , 0) used_space_bytes
  FROM cdb_tablespaces ts,
       v$containers    pdb,
       t,
       u,
       un
 WHERE 1 = 1
   AND CASE 
         WHEN '&&include_internal.' = 'Y' THEN 1
         WHEN '&&include_internal.' = 'N' AND ts.contents = 'PERMANENT' AND ts.tablespace_name NOT IN ('SYSTEM', 'SYSAUX') THEN 1
         ELSE 0
       END = 1
   AND CASE
         WHEN ts.contents = 'PERMANENT' AND '&&permanent.' = 'Y' THEN 1
         WHEN ts.contents = 'UNDO' AND '&&undo.' = 'Y' THEN 1
         WHEN ts.contents = 'TEMPORARY' AND '&&temporary.' = 'Y' THEN 1
         ELSE 0
       END = 1         
   AND pdb.con_id            = ts.con_id
   AND t.tablespace_name(+)  = ts.tablespace_name
   AND t.con_id(+)           = ts.con_id
   AND u.tablespace_name(+)  = ts.tablespace_name
   AND u.con_id(+)           = ts.con_id
   AND un.tablespace_name(+) = ts.tablespace_name
   AND un.con_id(+)          = ts.con_id
),
tablespaces AS (
SELECT o.pdb_name,
       o.tablespace_name,
       o.contents,
       o.bigfile,
       ROUND(m.tablespace_size * o.block_size / POWER(10, 9), 3) AS max_size_gb,
       ROUND(o.allocated_space_bytes / POWER(10, 9), 3) AS allocated_gb,
       ROUND(o.used_space_bytes / POWER(10, 9), 3) AS used_gb,
       ROUND((o.allocated_space_bytes - o.used_space_bytes) / POWER(10, 9), 3) AS free_gb,
       ROUND(100 * o.used_space_bytes / o.allocated_space_bytes, 3) AS used_percent, -- as per allocated space
       ROUND(100 * (o.allocated_space_bytes - o.used_space_bytes) / o.allocated_space_bytes, 3) AS free_percent -- as per allocated space
  FROM oem                          o,
       cdb_tablespace_usage_metrics m
 WHERE m.tablespace_name(+) = o.tablespace_name
   AND m.con_id(+)          = o.con_id
)
SELECT pdb_name,
       tablespace_name,
       contents,
       bigfile,
       '|' AS "|",
       max_size_gb,
       allocated_gb,
       used_gb,
       free_gb,
       used_percent,
       free_percent 
  FROM tablespaces
 ORDER BY
       &&order_by.
FETCH FIRST &&rows. ROWS ONLY
/
--
DEF order_by = 'tablespace_name';
PRO
PRO DBA
PRO ~~~
WITH
t AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       tablespace_name,
       SUM(NVL(bytes, 0)) bytes
  FROM dba_data_files
 GROUP BY 
       tablespace_name
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       tablespace_name,
       SUM(NVL(bytes, 0)) bytes
  FROM dba_temp_files
 GROUP BY 
       tablespace_name
),
u AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       tablespace_name,
       SUM(bytes) bytes
  FROM dba_free_space
 GROUP BY 
        tablespace_name
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       tablespace_name,
       NVL(SUM(bytes_used), 0) bytes
  FROM gv$temp_extent_pool
 GROUP BY 
       tablespace_name
),
un AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ts.tablespace_name,
       NVL(um.used_space * ts.block_size, 0) bytes
  FROM dba_tablespaces              ts,
       dba_tablespace_usage_metrics um
 WHERE ts.contents           = 'UNDO'
   AND um.tablespace_name(+) = ts.tablespace_name
),
oem AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       ts.tablespace_name,
       ts.contents,
       ts.bigfile,
       ts.block_size,
       NVL(t.bytes, 0) allocated_space_bytes,
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
       , 0) used_space_bytes
  FROM dba_tablespaces ts,
       t,
       u,
       un
 WHERE 1 = 1
   AND CASE 
         WHEN '&&include_internal.' = 'Y' THEN 1
         WHEN '&&include_internal.' = 'N' AND ts.contents = 'PERMANENT' AND ts.tablespace_name NOT IN ('SYSTEM', 'SYSAUX') THEN 1
         ELSE 0
       END = 1
   AND CASE
         WHEN ts.contents = 'PERMANENT' AND '&&permanent.' = 'Y' THEN 1
         WHEN ts.contents = 'UNDO' AND '&&undo.' = 'Y' THEN 1
         WHEN ts.contents = 'TEMPORARY' AND '&&temporary.' = 'Y' THEN 1
         ELSE 0
       END = 1         
   AND t.tablespace_name(+)  = ts.tablespace_name
   AND u.tablespace_name(+)  = ts.tablespace_name
   AND un.tablespace_name(+) = ts.tablespace_name
),
tablespaces AS (
SELECT o.tablespace_name,
       o.contents,
       o.bigfile,
       ROUND(m.tablespace_size * o.block_size / POWER(10, 9), 3) AS max_size_gb,
       ROUND(o.allocated_space_bytes / POWER(10, 9), 3) AS allocated_gb,
       ROUND(o.used_space_bytes / POWER(10, 9), 3) AS used_gb,
       ROUND((o.allocated_space_bytes - o.used_space_bytes) / POWER(10, 9), 3) AS free_gb,
       ROUND(100 * o.used_space_bytes / o.allocated_space_bytes, 3) AS used_percent, -- as per allocated space
       ROUND(100 * (o.allocated_space_bytes - o.used_space_bytes) / o.allocated_space_bytes, 3) AS free_percent -- as per allocated space
  FROM oem                          o,
       dba_tablespace_usage_metrics m
 WHERE m.tablespace_name(+) = o.tablespace_name
)
SELECT tablespace_name,
       contents,
       bigfile,
       '|' AS "|",
       max_size_gb,
       allocated_gb,
       used_gb,
       free_gb,
       used_percent,
       free_percent 
  FROM tablespaces
 ORDER BY
       &&order_by.
FETCH FIRST &&rows. ROWS ONLY
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&include_internal."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--