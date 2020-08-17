----------------------------------------------------------------------------------------
--
-- File name:   cs_top_mem_or_hvc.sql
--
-- Purpose:     Top SQL according to Memory or Versions Count (HVC)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/03/10
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
DEF def_top = '20';
--
PRO 1. Top Memory: [{&&def_top.}|1-100]
DEF top_mem = '&1.';
UNDEF 1;
PRO
PRO 2. Top Versions: [{&&def_top.}|1-100]
DEF top_ver = '&2.';
UNDEF 2;
PRO
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&top_mem." "&&top_ver."
@@cs_internal/cs_spool_id.sql
--
PRO TOP_MEM      : "&&top_mem." [{&&def_top.}|1-100]
PRO TOP_VER      : "&&top_ver." [{&&def_top.}|1-100]
--
COL top_mem FOR 9990 HEA 'MEM#';
COL top_ver FOR 9990 HEA 'VER#';
COL sharable_mem_mbs FOR 999,990 HEA 'SHARABLE|MEM (MBs)';
COL sharable_mem_pct FOR 990.0 HEA 'PCT%';
COL persistent_mem_mbs FOR 999,990 HEA 'PERSIST|MEM (MBs)';
COL persistent_mem_pct FOR 990.0 HEA 'PCT%';
COL runtime_mem_mbs FOR 999,990 HEA 'RUNTIME|MEM (MBs)';
COL runtime_mem_pct FOR 990.0 HEA 'PCT%';
COL version_count FOR 999,990 HEA 'VRSION|COUNT';
COL version_count_pct FOR 990.0 HEA 'PCT%';
COL open_versions FOR 999,990 HEA 'OPEN|VERSIONS';
COL users_opening FOR 999,990 HEA 'USESRS|OPENING';
COL loads FOR 999,990 HEA 'LOADS';
COL invalidations FOR 999,990 HEA 'INVALI-|DATIONS';
COL obsolete FOR 999,990 HEA 'OBSO-|LETE';
COL not_obsl FOR 999,990 HEA 'NOT OB-|SOLETE';
COL valid FOR 999,990 HEA 'VALID';
COL invalid FOR 999,990 HEA 'INVALID';
COL shareable FOR 999,990 HEA 'SHAREABLE|AND VALID';
COL bind_aware FOR 999,990 HEA 'BIND AWARE|AND VALID';
COL pdb_count FOR 999,990 HEA 'PDBs';
COL plans FOR 9,990 HEA 'PLANs';
COL sql_id FOR A13 HEA 'SQL_ID';
COL sql_text FOR A100 HEA 'SQL_TEXT' TRUNC;
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF sharable_mem_mbs sharable_mem_pct persistent_mem_mbs persistent_mem_pct runtime_mem_mbs runtime_mem_pct version_count version_count_pct /*loaded_versions loaded_versions_pct*/ open_versions users_opening loads invalidations obsolete not_obsl valid invalid shareable bind_aware ON REPORT;
PRO
PRO Top SQL according to Memory or Versions Count (HVC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH
top_sql AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id,
       sql_text,
       ROUND(SUM(CASE WHEN is_obsolete = 'N' THEN sharable_mem ELSE 0 END) / POWER(2,20)) sharable_mem_mbs,
       100 * SUM(CASE WHEN is_obsolete = 'N' THEN sharable_mem ELSE 0 END) / SUM(SUM(CASE WHEN is_obsolete = 'N' THEN sharable_mem ELSE 0 END)) OVER () sharable_mem_pct,
       ROUND(SUM(CASE WHEN is_obsolete = 'N' THEN persistent_mem ELSE 0 END) / POWER(2,20)) persistent_mem_mbs,
       100 * SUM(CASE WHEN is_obsolete = 'N' THEN persistent_mem ELSE 0 END) / SUM(SUM(CASE WHEN is_obsolete = 'N' THEN persistent_mem ELSE 0 END)) OVER () persistent_mem_pct,
       ROUND(SUM(CASE WHEN is_obsolete = 'N' THEN runtime_mem ELSE 0 END) / POWER(2,20)) runtime_mem_mbs,
       100 * SUM(CASE WHEN is_obsolete = 'N' THEN runtime_mem ELSE 0 END) / SUM(SUM(CASE WHEN is_obsolete = 'N' THEN runtime_mem ELSE 0 END)) OVER () runtime_mem_pct,
       COUNT(*) version_count,
       100 * COUNT(*) / SUM(COUNT(*)) OVER () version_count_pct,
       SUM(open_versions) open_versions,
       SUM(users_opening) users_opening,
       SUM(loads) loads,
       SUM(invalidations) invalidations,
       SUM(CASE WHEN is_obsolete = 'Y' THEN 1 ELSE 0 END) obsolete,
       SUM(CASE WHEN is_obsolete = 'N' THEN 1 ELSE 0 END) not_obsl,
       SUM(CASE WHEN object_status LIKE 'VALID%' THEN 1 ELSE 0 END) valid,
       SUM(CASE WHEN object_status LIKE 'INVALID%' THEN 1 ELSE 0 END) invalid,
       SUM(CASE WHEN is_obsolete = 'N' AND object_status LIKE 'VALID%' AND is_shareable = 'Y' THEN 1 ELSE 0 END) shareable,
       SUM(CASE WHEN is_obsolete = 'N' AND object_status LIKE 'VALID%' AND is_shareable = 'Y' AND is_bind_aware = 'Y' THEN 1 ELSE 0 END) bind_aware,
       COUNT(DISTINCT con_id) pdb_count,
       COUNT(DISTINCT plan_hash_value) plans,
       ROW_NUMBER () OVER (ORDER BY (SUM(sharable_mem) + SUM(persistent_mem) + SUM(runtime_mem)) DESC NULLS LAST) top_mem,
       ROW_NUMBER () OVER (ORDER BY COUNT(*) DESC NULLS LAST) top_ver
  FROM v$sql
 WHERE sql_text NOT LIKE '%/*+ dynamic_sampling%'
 GROUP BY
       sql_id,
       sql_text
)
SELECT top_mem,
       top_ver,
       sharable_mem_mbs,
       sharable_mem_pct,
       persistent_mem_mbs,
       persistent_mem_pct,
       runtime_mem_mbs,
       runtime_mem_pct,
       version_count,
       version_count_pct,
       open_versions,
       users_opening,
       loads,
       invalidations,
       obsolete,
       not_obsl,
       valid,
       invalid,
       shareable,
       bind_aware,
       pdb_count,
       plans,
       sql_id,
       sql_text
  FROM top_sql
 WHERE top_mem <= TO_NUMBER(NVL('&&top_mem.', '&&def_top.'))
    OR top_ver <= TO_NUMBER(NVL('&&top_ver.', '&&def_top.'))
 ORDER BY
       CASE WHEN top_mem <= TO_NUMBER(NVL('&&top_mem.', '&&def_top.')) THEN top_mem ELSE TO_NUMBER(NVL('&&top_mem.', '&&def_top.')) + top_ver END
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql "&&top_mem." "&&top_ver."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--