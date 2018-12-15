----------------------------------------------------------------------------------------
--
-- File name:   cs_top_segments.sql
--
-- Purpose:     Top Segments as per size
--
-- Author:      Carlos Sierra
--
-- Version:     2018/11/02
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_segments.sql
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
DEF cs_script_name = 'cs_top_segments';
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql
@@cs_internal/cs_spool_id.sql
--
COL owner FOR A30;
COL segment_name FOR A30;
COL mbs FOR 999,990;
COL gbs FOR 9,990.000 HEA 'GBs';
COL table_name FOR A30;
COL column_name FOR A30;
COL pdb_name FOR A35;
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF gbs ON REPORT;
--
PRO
PRO TOP SEGMENTS (as per size)
PRO ~~~~~~~~~~~~
SELECT DISTINCT
       s.bytes/POWER(2,30) gbs,
       s.owner, s.segment_name,
       s.segment_type,
       NVL(l.table_name, i.table_name) table_name,
       l.column_name,
       c.name||'('||s.con_id||')' pdb_name
  FROM cdb_segments s,
       cdb_lobs l,
       cdb_indexes i,
       v$containers c
 WHERE l.con_id(+) = s.con_id
   AND l.owner(+) = s.owner
   AND l.segment_name(+) = s.segment_name
   AND i.con_id(+) = s.con_id
   AND i.owner(+) = s.owner
   AND i.index_name(+) = s.segment_name
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
 ORDER BY
       s.bytes DESC NULLS LAST
 FETCH FIRST 20 ROWS ONLY
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--