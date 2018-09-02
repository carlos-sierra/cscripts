-- iod_rsrc_mgr_pdb.sql
-- CDB Resource Manager - Setup for one PDB
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
COL pdb_name NEW_V pdb_name FOR A30;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') pdb_name FROM DUAL;
--
ALTER SESSION SET container = CDB$ROOT;
--
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD"T"HH24:MI:SS';
--
DEF plan = 'IOD_CDB_PLAN';
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT ON SIZE UNLIMITED;
CL COL BRE
--
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_rsrc_mgr_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, 'dd"T"hh24') output_file_name FROM DUAL;
--
COL comments FOR A60;
COL status FOR A20;
COL mandatory FOR A9;
COL pluggable_database FOR A30;
COL shares FOR 999990;
COL utilization_limit FOR 99990 HEA 'UTIL|LIMIT'
COL parallel_server_limit FOR 99999999 HEA 'PARALLEL|SERVER';
COL directive_type FOR A20;
--
CLEAR BREAK COMPUTE;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF utilization_limit ON REPORT;
PRO
PRO PDBs Directives (BEFORE)
PRO ~~~~~~~~~~~~~~~
SELECT pluggable_database, 
       utilization_limit,
       shares, 
       parallel_server_limit,
       comments,
       mandatory,
       directive_type
  FROM dba_cdb_rsrc_plan_directives
 WHERE plan = UPPER(TRIM('&&plan.'))
 ORDER BY 
       pluggable_database
/
CLEAR BREAK COMPUTE;
PRO
PRO PDBs Configuration (BEFORE)
PRO ~~~~~~~~~~~~~~~~~~
SELECT pdb_name pluggable_database,
       utilization_limit,
       shares,
       parallel_server_limit,
       end_date
  FROM c##iod.rsrc_mgr_pdb_config
 WHERE plan = UPPER(TRIM('&&plan.'))
 ORDER BY
       pdb_name
/
--
PRO
PRO 1. Enter PDB_NAME:
DEF pluggable_database = '&1.';
PRO
DEF default_utilization_limit = 12;
PRO 2. Enter CPU Utilization Limit: [{&&default_utilization_limit.}|6-36]
DEF new_utilization_limit = '&2.';
PRO
DEF default_shares = 3;
PRO 3. Enter Shares: [{&&default_shares.}1-10]
DEF new_shares = '&3.';
PRO
DEF default_days_to_expire = '7';
PRO 4. Enter Days to Expire: [{&&default_days_to_expire.}|1-30]
DEF days_to_expire = '&4.';
--
SPO &&output_file_name..txt;
--
EXEC c##iod.iod_rsrc_mgr.update_cdb_plan_directive(p_plan => '&&plan.', p_pluggable_database => '&&pluggable_database.', p_shares => TO_NUMBER(NVL('&&new_shares.','&&default_shares.')), p_utilization_limit => TO_NUMBER(NVL('&&new_utilization_limit.','&&default_utilization_limit.')));
--
MERGE INTO c##iod.rsrc_mgr_pdb_config t
USING (SELECT UPPER(TRIM('&&plan.')) plan, UPPER(TRIM('&&pluggable_database.')) pdb_name, TO_NUMBER(NVL('&&new_shares.','&&default_shares.')) shares, TO_NUMBER(NVL('&&new_utilization_limit.','&&default_utilization_limit.')) utilization_limit, TO_NUMBER(NULL) parallel_server_limit, SYSDATE + TO_NUMBER(NVL('&&days_to_expire.','&&default_days_to_expire.')) end_date FROM DUAL) s
ON (t.plan = s.plan AND t.pdb_name = s.pdb_name)
WHEN MATCHED THEN
UPDATE SET t.shares = s.shares, t.utilization_limit = s.utilization_limit, t.parallel_server_limit = s.parallel_server_limit, t.end_date = s.end_date
WHEN NOT MATCHED THEN
INSERT (plan, pdb_name, shares, utilization_limit, parallel_server_limit, end_date) 
VALUES  (s.plan, s.pdb_name, s.shares, s.utilization_limit, s.parallel_server_limit, s.end_date)
/
COMMIT;
--
CLEAR BREAK COMPUTE;
BREAK ON REPORT;
COMPUTE SUM LABEL 'TOTAL' OF utilization_limit ON REPORT;
PRO
PRO PDBs Directives (AFTER)
PRO ~~~~~~~~~~~~~~~
SELECT pluggable_database, 
       utilization_limit,
       shares, 
       parallel_server_limit,
       comments,
       mandatory,
       directive_type
  FROM dba_cdb_rsrc_plan_directives
 WHERE plan = UPPER(TRIM('&&plan.'))
 ORDER BY 
       pluggable_database
/
CLEAR BREAK COMPUTE;
PRO
PRO PDBs Configuration (AFTER)
PRO ~~~~~~~~~~~~~~~~~~
SELECT pdb_name pluggable_database,
       utilization_limit,
       shares,
       parallel_server_limit,
       end_date
  FROM c##iod.rsrc_mgr_pdb_config
 WHERE plan = UPPER(TRIM('&&plan.'))
 ORDER BY
       pdb_name
/
CLEAR BREAK COMPUTE;
BREAK ON pluggable_database SKIP 1;
PRO
PRO PDBs Directives History
PRO ~~~~~~~~~~~~~~~~~~~~~~~
SELECT pdb_name pluggable_database,
       snap_time,
       utilization_limit,
       shares,
       parallel_server_limit,
       aas_p99,
       aas_p95
  FROM c##iod.rsrc_mgr_pdb_hist
 WHERE plan = UPPER(TRIM('&&plan.'))
 ORDER BY
       pdb_name,
       snap_time
/
--
SPO OFF;
HOS zip -mj &&zip_file_name..zip &&output_file_name..txt
HOS unzip -l &&zip_file_name..zip
UNDEF 1 2 3 4
WHENEVER SQLERROR CONTINUE;
ALTER SESSION SET container = &&pdb_name.;
