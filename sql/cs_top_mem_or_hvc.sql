----------------------------------------------------------------------------------------
--
-- File name:   cs_top_mem_or_hvc.sql
--
-- Purpose:     Top SQL according to Memory or Versions Count (HVC)
--
-- Author:      Carlos Sierra
--
-- Version:     2018/12/20
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_top_mem_or_hvc.sql
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
DEF cs_script_name = 'cs_top_mem_or_hvc';
DEF def_top = '10';
--
PRO 1. Top Memory: [{&&def_top.}|1-100]
DEF top_mem = '&1.';
PRO
PRO 2. Top Versions: [{&&def_top.}|1-100]
DEF top_ver = '&2.';
PRO
--
SELECT '&&cs_file_prefix._&&cs_file_date_time._&&cs_reference_sanitized._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&top_mem." "&&top_ver."
@@cs_internal/cs_spool_id.sql
--
PRO TOP_MEM      : "&&top_mem." [{&&def_top.}|1-100]
PRO TOP_VER      : "&&top_ver." [{&&def_top.}|1-100]
--
COL top_mem FOR 990 HEA 'MEM#';
COL top_ver FOR 990 HEA 'VER#';
COL sharable_mem_mbs FOR 999,990 HEA 'SHAR_MEM_MBS';
COL persistent_mem_mbs FOR 999,990 HEA 'PERS_MEM_MBS';
COL runtime_mem_mbs FOR 999,990 HEA 'RUN_MEM_MBS';
COL version_count FOR 999,990 HEA 'VRS_CNT';
COL loaded_versions FOR 999,990 HEA 'LOA_VRS';
COL open_versions FOR 999,990 HEA 'OPN_VRS';
COL users_opening FOR 999,990 HEA 'USR_OPN';
COL loads FOR 999,990 HEA 'LOADS';
COL invalidations FOR 999,990 HEA 'INVALS';
COL obsolete FOR 999,990 HEA 'OBSOL';
COL not_obsl FOR 999,990 HEA 'NOT_OBS';
COL valid FOR 999,990 HEA 'VAL';
COL invalid FOR 999,990 HEA 'INVAL';
COL pdb_count FOR 999,990 HEA 'PDBs';
COL sql_id FOR A13 HEA 'SQL_ID';
COL sql_text FOR A100 HEA 'SQL_TEXT' TRUNC;
--
PRO
PRO Top SQL according to Memory or Versions Count (HVC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
top_sql AS (
SELECT /*+ NO_MERGE */
       sql_id,
       sql_text,
       ROUND(SUM(sharable_mem)/POWER(2,20)) sharable_mem_mbs,
       ROUND(SUM(persistent_mem)/POWER(2,20)) persistent_mem_mbs,
       ROUND(SUM(runtime_mem)/POWER(2,20)) runtime_mem_mbs,
       SUM(DISTINCT version_count) version_count,
       SUM(loaded_versions) loaded_versions,
       SUM(open_versions) open_versions,
       SUM(users_opening) users_opening,
       SUM(loads) loads,
       SUM(invalidations) invalidations,
       SUM(CASE WHEN is_obsolete = 'Y' THEN 1 ELSE 0 END) obsolete,
       SUM(CASE WHEN is_obsolete = 'N' THEN 1 ELSE 0 END) not_obsl,
       SUM(CASE WHEN object_status LIKE 'VALID%' THEN 1 ELSE 0 END) valid,
       SUM(CASE WHEN object_status LIKE 'INVALID%' THEN 1 ELSE 0 END) invalid,
       COUNT(*) pdb_count,
       ROW_NUMBER () OVER (ORDER BY (SUM(sharable_mem) + SUM(persistent_mem) + SUM(runtime_mem)) DESC NULLS LAST) top_mem,
       ROW_NUMBER () OVER (ORDER BY (SUM(DISTINCT version_count) + SUM(loaded_versions)) DESC NULLS LAST) top_ver
  FROM v$sqlarea
 GROUP BY
       sql_id,
       sql_text
)
SELECT top_mem,
       top_ver,
       sharable_mem_mbs,
       persistent_mem_mbs,
       runtime_mem_mbs,
       version_count,
       loaded_versions,
       open_versions,
       users_opening,
       loads,
       invalidations,
       obsolete,
       not_obsl,
       valid,
       invalid,
       pdb_count,
       sql_id,
       sql_text
  FROM top_sql
 WHERE top_mem <= TO_NUMBER(NVL('&&top_mem.', '&&def_top.'))
    OR top_ver <= TO_NUMBER(NVL('&&top_ver.', '&&def_top.'))
 ORDER BY
       CASE WHEN top_mem <= TO_NUMBER(NVL('&&top_mem.', '&&def_top.')) THEN top_mem ELSE TO_NUMBER(NVL('&&top_mem.', '&&def_top.')) + top_ver END
/
--
PRO
PRO SQL> @&&cs_script_name..sql "&&top_mem." "&&top_ver."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--