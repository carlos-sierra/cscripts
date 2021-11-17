----------------------------------------------------------------------------------------
--
-- File name:   cs_hc_pdb_manifest.sql
--
-- Purpose:     Health Check (HC) PDB Manifest
--
-- Author:      Carlos Sierra
--
-- Version:     2021/10/04
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_hc_pdb_manifest.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
--@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_hc_pdb_manifest';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql
@@cs_internal/cs_spool_id.sql
--
ALTER SESSION SET CONTAINER = CDB$ROOT;
--
PRO
PRO hc_pdb_manifest_v2 (from CDB$ROOT)
PRO ~~~~~~~~~~~~~~~~~~
@@cs_internal/cs_pr_internal "SELECT v.* FROM &&cs_tools_schema..hc_pdb_manifest_v2 v WHERE &&cs_con_id. IN (1, v.con_id) ORDER BY v.con_id, v.ez_connect_string"
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--