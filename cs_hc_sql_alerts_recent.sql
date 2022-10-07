----------------------------------------------------------------------------------------
--
-- File name:   cs_hc_sql_alerts_recent.sql
--
-- Purpose:     Health Check (HC) SQL Alerts - Recent (for one or all PDBs)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/11/18
--
-- Usage:       Execute connected to PDB or CDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_hc_sql_alerts_recent.sql
--
-- Notes:       Developed and tested on 19c
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
--@@cs_internal/cs_cdb_warn.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_hc_sql_alerts_recent';
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/&&cs_set_container_to_cdb_root.
--
PRO
PRO HC SQL - ALERTS RECENT (&&cs_stgtab_owner..alerts_hist)
PRO ~~~~~~~~~~~~~~~~~~~~~~
@@cs_internal/cs_pr_internal "SELECT v.* FROM &&cs_tools_schema..alerts_hist_v v WHERE &&cs_con_id. IN (1, v.con_id) ORDER BY v.con_id, v.sql_id"
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
--
PRO
PRO SQL> @&&cs_script_name..sql
--
@@cs_internal/cs_spool_tail.sql
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--
