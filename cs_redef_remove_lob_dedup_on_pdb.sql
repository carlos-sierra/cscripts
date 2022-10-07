----------------------------------------------------------------------------------------
--
-- File name:   cs_redef_remove_lob_dedup_on_pdb.sql
--
-- Purpose:     Remove LOB Deduplication on PDB
--
-- Author:      Carlos Sierra
--
-- Version:     2022/05/06
--
-- Usage:       Execute connected to PDB
--
--              Enter PX degree when requested
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_redef_remove_lob_dedup_on_pdb.sql
--
-- Notes:       This operation requires a blackout.
--              Developed and tested on 19c.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_blackout.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_redef_remove_lob_dedup_on_pdb';
--
PRO
PRO 1. Degree of Parallelism: [{1}|2|4|8]
DEF pxdegree = '&1.';
UNDEF 1;
COL p_pxdegree NEW_V p_pxdegree NOPRI;
SELECT CASE WHEN '&&pxdegree.' IN ('1','2','4','8') THEN '&&pxdegree.' ELSE '1' END AS p_pxdegree FROM DUAL
/
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&p_pxdegree."
@@cs_internal/cs_spool_id.sql
--
PRO PX_DEGREE    : &&p_pxdegree. [{1}|2|4|8]
--
COMMIT;
@@cs_internal/&&cs_set_container_to_cdb_root.
--
PRO
PRO DEDUP REMOVAL
PRO ~~~~~~~~~~~~~
SET SERVEROUT ON
ALTER SESSION SET DDL_LOCK_TIMEOUT = 10;
BEGIN
  &&cs_tools_schema..IOD_SPACE.removededup (
      p_pdb_name      => '&&cs_con_name.'
    , p_pxdegree      =>  &&p_pxdegree.
  );
END;
/
SET SERVEROUT OFF;
--
COMMIT;
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO SQL> @&&cs_script_name..sql "&&p_pxdegree."
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--