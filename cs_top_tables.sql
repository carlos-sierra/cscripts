----------------------------------------------------------------------------------------
--
-- File name:   cs_top_tables.sql
--
-- Purpose:     Top Tables according to Segment(s) size (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/10/20
--
-- Usage:       Execute connected to CDB or PDB.
--
--              Enter if Oracle Maintained tables are included
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_tables.sql
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
DEF cs_script_name = 'cs_top_tables';
--
PRO 1. ORACLE_MAINT: [{N}|Y]
DEF cs_oracle_maint = '&1.';
UNDEF 1;
COL cs_oracle_maint NEW_V cs_oracle_maint NOPRI;
SELECT COALESCE('&&cs_oracle_maint.', 'N') AS cs_oracle_maint FROM DUAL;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_oracle_maint."
@@cs_internal/cs_spool_id.sql
--
PRO ORACLE MAINT : "&&cs_oracle_maint." [{N}|Y]
--
COL gb FOR 999,990.000 HEA 'GB';
COL owner FOR A30 TRUNC PRI;
COL segment_name FOR A30 TRUNC;
COL tablespace_name FOR A30 TRUNC;
COL pdb_name FOR A30 TRUNC;
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF gb ON REPORT;
--
PRO
PRO TOP TABLES
PRO ~~~~~~~~~~
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       SUM(s.bytes)/1e9 AS gb,
       s.owner,
       s.segment_name,
       s.segment_type,
       s.tablespace_name,
       c.name AS pdb_name
  FROM cdb_segments s,
       v$containers c
 WHERE s.segment_type LIKE 'TABLE%'
   AND (s.con_id, s.owner) IN (SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') MATERIALIZE NO_MERGE */ DISTINCT con_id, username FROM cdb_users WHERE '&&cs_oracle_maint.' = 'Y' OR oracle_maintained = 'N')
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
 GROUP BY
       s.owner,
       s.segment_name,
       s.segment_type,
       s.tablespace_name,
       c.name
HAVING SUM(s.bytes)/1e9 > 0.001
 ORDER BY
       1 DESC
 FETCH FIRST 30 ROWS ONLY
/
--
CLEAR BREAK COMPUTE COLUMNS;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_oracle_maint."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--