----------------------------------------------------------------------------------------
--
-- File name:   cs_sqlarea_per_pdb.sql
--
-- Purpose:     SQL Area per PDB
--
-- Author:      Carlos Sierra
--
-- Version:     2021/10/30
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_sqlarea_per_pdb.sql
--
-- Notes:       Developed and tested on 19c.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_sqlarea_per_pdb';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql 
@@cs_internal/cs_spool_id.sql
--
ALTER SESSION SET container = CDB$ROOT;
--
COL pdb_name FOR A30;
COL sharable_mem FOR 999,999,999,990;
COL persistent_mem FOR 999,999,999,990;
COL runtime_mem FOR 999,999,999,990;
COL statements FOR 999,999,999,990;
COL version_count FOR 999,999,999,990;
COL loaded_versions FOR 999,999,999,990;
COL open_versions FOR 999,999,999,990;
COL users_opening FOR 999,999,999,990;
COL loads FOR 999,999,999,990;
COL invalidations FOR 999,999,999,990;
COL executions FOR 999,999,999,990;
COL parse_calls FOR 999,999,999,990;
--
BREAK ON REPORT;
COMPUTE SUM OF statements sharable_mem persistent_mem runtime_mem version_count loaded_versions open_versions users_opening users_executing loads invalidations executions parse_calls ON REPORT;
--
PRO
PRO SQL Area per PDB
PRO ~~~~~~~~~~~~~~~~
 SELECT c.name AS pdb_name,
        COUNT(*) AS statements,
        SUM(a.sharable_mem) AS sharable_mem,
        SUM(a.persistent_mem) AS persistent_mem,
        SUM(a.runtime_mem) AS runtime_mem,
        SUM(a.version_count) AS version_count,
        SUM(a.loaded_versions) AS loaded_versions,
        SUM(a.open_versions) AS open_versions,
        SUM(a.users_opening) AS users_opening,
        SUM(a.users_executing) AS users_executing,
        SUM(a.loads) AS loads,
        SUM(a.invalidations) AS invalidations,
        SUM(a.executions) AS executions,
        SUM(a.parse_calls) AS parse_calls
   FROM v$sqlarea a, v$containers c
  WHERE a.con_id > 2
    AND c.con_id = a.con_id
  GROUP BY
        c.name
 ORDER BY
        c.name
/
--
CLEAR BREAK COMPUTE;
--
PRO
PRO SQL> @&&cs_script_name..sql 
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--