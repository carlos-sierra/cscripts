----------------------------------------------------------------------------------------
--
-- File name:   cs_tablespaces.sql
--
-- Purpose:     List Tablespaces 
--
-- Author:      Carlos Sierra
--
-- Version:     2018/08/29
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
COL include_internal NEW_V include_internal NOPRI;
SELECT NVL(UPPER(SUBSTR(TRIM('&&include_internal.'),1)),'N') include_internal FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&include_internal."
@@cs_internal/cs_spool_id.sql
--
PRO INTERNAL TBS : &&include_internal.
--
CLEAR BREAK COMPUTE;
BREAK ON REPORT;
COMPUTE COUNT LABEL 'COUNT' OF tablespace_name ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF oem_allocated_space_gbs oem_used_space_gbs met_max_size_gbs met_used_space_gbs ON REPORT; 
--
COL pdb_name FOR A30;
COL tablespace_name FOR A30;
COL oem_allocated_space_gbs FOR 999,990.000 HEA 'OEM|ALLOCATED|SPACE (GBs)';
COL oem_used_space_gbs FOR 999,990.000 HEA 'OEM|USED|SPACE (GBs)';
COL oem_used_percent FOR 990.0 HEA 'OEM|USED|PERC';
COL met_max_size_gbs FOR 999,990.000 HEA 'METRICS|MAX|SIZE (GBs)';
COL met_used_space_gbs FOR 999,990.000 HEA 'METRICS|USED|SPACE (GBs)';
COL met_used_percent FOR 990.0 HEA 'METRICS|USED|PERC';
--
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
       NVL(t.bytes / POWER(2,30), 0) allocated_space, -- GBs
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
       / POWER(2,30), 0) used_space -- GBs
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
   AND pdb.con_id            = ts.con_id
   AND t.tablespace_name(+)  = ts.tablespace_name
   AND t.con_id(+)           = ts.con_id
   AND u.tablespace_name(+)  = ts.tablespace_name
   AND u.con_id(+)           = ts.con_id
   AND un.tablespace_name(+) = ts.tablespace_name
   AND un.con_id(+)          = ts.con_id
)
SELECT o.pdb_name,
       --o.con_id,
       o.tablespace_name,
       o.contents,
       o.bigfile,
       --o.block_size,
       ROUND(o.allocated_space, 3) oem_allocated_space_gbs,
       ROUND(o.used_space, 3) oem_used_space_gbs,
       ROUND(100 * o.used_space / o.allocated_space, 3) oem_used_percent, -- as per allocated space
       ROUND(m.tablespace_size * o.block_size / POWER(2, 30), 3) met_max_size_gbs,
       ROUND(m.used_space * o.block_size / POWER(2, 30), 3) met_used_space_gbs,
       ROUND(m.used_percent, 3) met_used_percent -- as per maximum size (considering auto extend)
  FROM oem                          o,
       cdb_tablespace_usage_metrics m
 WHERE m.tablespace_name(+) = o.tablespace_name
   AND m.con_id(+)          = o.con_id
 ORDER BY
       o.pdb_name,
       o.tablespace_name
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