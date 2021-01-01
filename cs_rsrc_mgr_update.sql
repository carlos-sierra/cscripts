----------------------------------------------------------------------------------------
--
-- File name:   dbrmu.sql | cs_rsrc_mgr_update.sql
--
-- Purpose:     Database Resource Manager (DBRM) Update
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/16
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_rsrc_mgr_update.sql
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
DEF cs_script_name = 'cs_rsrc_mgr_update';
DEF cs_script_acronym = 'dbrmu.sql | ';
--
DEF cs_parallel_server_limit = '50';
DEF default_utilization_limit = '8';
DEF default_shares = '4';
DEF default_days_to_expire = '7';
DEF min_utilization_limit = '4';
DEF max_utilization_limit = '96';
DEF min_shares = '1';
DEF max_shares = '16';
DEF min_days_to_expire = '0';
DEF max_days_to_expire = '365';
--
COL pdb_name NEW_V pdb_name FOR A30;
ALTER SESSION SET container = CDB$ROOT;
--
@@cs_internal/cs_rsrc_mgr_internal_set.sql
@@cs_internal/cs_rsrc_mgr_internal_configuration.sql
@@cs_internal/cs_rsrc_mgr_internal_directives.sql
--
PRO
PRO 1. Enter Pluggable Database name:
DEF cs_pluggable_database = '&1.';
UNDEF 1;
COL cs_pluggable_database NEW_V cs_pluggable_database NOPRI;
SELECT UPPER(TRIM('&&cs_pluggable_database.')) AS cs_pluggable_database FROM DUAL;
PRO
PRO 2. Enter CPU Utilization Limit: [{&&default_utilization_limit.}|&&min_utilization_limit.-&&max_utilization_limit.]
DEF new_utilization_limit = '&2.';
UNDEF 2;
COL new_utilization_limit NEW_V new_utilization_limit NOPRI;
SELECT TO_CHAR(LEAST(GREATEST(TO_NUMBER(COALESCE('&&new_utilization_limit.','&&default_utilization_limit.')), &&min_utilization_limit.), &&max_utilization_limit.)) AS new_utilization_limit FROM DUAL;
PRO
PRO 3. Enter Shares: [{&&default_shares.}|&&min_shares.-&&max_shares.]
DEF new_shares = '&3.';
UNDEF 3;
COL new_shares NEW_V new_shares NOPRI;
SELECT TO_CHAR(LEAST(GREATEST(TO_NUMBER(COALESCE('&&new_shares.','&&default_shares.')), &&min_shares.), &&max_shares.)) AS new_shares FROM DUAL;
PRO
PRO 4. Enter Days to Expire: [{&&default_days_to_expire.}|&&min_days_to_expire.-&&max_days_to_expire.]
DEF days_to_expire = '&4.';
UNDEF 4;
COL days_to_expire NEW_V days_to_expire NOPRI;
SELECT TO_CHAR(LEAST(GREATEST(TO_NUMBER(COALESCE('&&days_to_expire.','&&default_days_to_expire.')), &&min_days_to_expire.), &&max_days_to_expire.)) days_to_expire FROM DUAL;
--
EXEC c##iod.iod_rsrc_mgr.update_cdb_plan_directive(p_plan => '&&resource_manager_plan.', p_pluggable_database => '&&cs_pluggable_database.', p_shares => TO_NUMBER('&&new_shares.'), p_utilization_limit => TO_NUMBER('&&new_utilization_limit.'), p_parallel_server_limit => '&&cs_parallel_server_limit.', p_comment => '&&cs_reference.');
--
MERGE INTO c##iod.rsrc_mgr_pdb_config t
USING (SELECT '&&resource_manager_plan.' plan, '&&cs_pluggable_database.' pdb_name, TO_NUMBER('&&new_shares.') shares, TO_NUMBER('&&new_utilization_limit.') utilization_limit, TO_NUMBER('&&cs_parallel_server_limit.') parallel_server_limit, SYSDATE + TO_NUMBER('&&days_to_expire.') end_date, '&&cs_reference.' reference FROM DUAL) s
ON (t.plan = s.plan AND t.pdb_name = s.pdb_name)
WHEN MATCHED THEN
UPDATE SET t.shares = s.shares, t.utilization_limit = s.utilization_limit, t.parallel_server_limit = s.parallel_server_limit, t.end_date = s.end_date, t.reference = s.reference
WHEN NOT MATCHED THEN
INSERT (plan, pdb_name, shares, utilization_limit, parallel_server_limit, end_date, reference) 
VALUES  (s.plan, s.pdb_name, s.shares, s.utilization_limit, s.parallel_server_limit, s.end_date, s.reference)
/
COMMIT;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_pluggable_database." "&&new_utilization_limit." "&&new_shares." "&&days_to_expire."
@@cs_internal/cs_spool_id.sql
--
PRO PDB_NAME     : &&cs_pluggable_database.
PRO UTILIZATION  : &&new_utilization_limit.
PRO SHARES       : &&new_shares.
PRO EXPIRE_IN    : &&days_to_expire. day(s)
--
@@cs_internal/cs_rsrc_mgr_internal_history.sql
@@cs_internal/cs_rsrc_mgr_internal_directives.sql
@@cs_internal/cs_rsrc_mgr_internal_configuration.sql
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_pluggable_database." "&&new_utilization_limit." "&&new_shares." "&&days_to_expire."
--
@@cs_internal/cs_spool_tail.sql
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--