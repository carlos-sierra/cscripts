-- IOD_REPEATING_RSRC_MGR_RESET
-- CDB Resource Manager - Setup 
-- set p_report_only to N to update plan
--
DEF report_only = 'N';
DEF switch_plan = 'Y';
DEF plan = 'IOD_CDB_PLAN';
--
WHENEVER SQLERROR EXIT SUCCESS;
PRO Error "ORA-01476: divisor is equal to zero" just means v$database.open_mode is not "READ WRITE"
SELECT CASE open_mode WHEN 'READ WRITE' THEN open_mode ELSE TO_CHAR(1/0) END open_mode FROM v$database;
WHENEVER SQLERROR EXIT FAILURE;
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT ON SIZE UNLIMITED;
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_rsrc_mgr_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, 'dd"T"hh24') output_file_name FROM DUAL;
--
SPO &&output_file_name..txt;
--
COL plan_id FOR 9999999;
COL plan FOR A30;
COL comments FOR A60;
COL status FOR A20;
COL mandatory FOR A9;
COL pluggable_database FOR A30;
COL shares FOR 999990;
COL utilization_limit FOR 99990 HEA 'UTIL|LIMIT'
COL parallel_server_limit FOR 99999999 HEA 'PARALLEL|SERVER';
COL directive_type FOR A20;
--
SELECT plan_id,
       plan,
       mandatory,
       status,
       comments
  FROM dba_cdb_rsrc_plans
 ORDER BY
       plan_id
/
--
SELECT mandatory,
       directive_type,
       utilization_limit,
       shares, 
       parallel_server_limit,
       pluggable_database, 
       status,
       comments
  FROM dba_cdb_rsrc_plan_directives
 WHERE plan = UPPER(TRIM('&plan.'))
 ORDER BY 
       mandatory DESC,
       directive_type,
       utilization_limit DESC,
       shares DESC,
       parallel_server_limit DESC,
       pluggable_database
/
--
EXEC c##iod.iod_rsrc_mgr.reset(p_report_only => '&&report_only.', p_plan => '&&plan.', p_switch_plan => '&&switch_plan.');
--
SELECT plan_id,
       plan,
       mandatory,
       status,
       comments
  FROM dba_cdb_rsrc_plans
 ORDER BY
       plan_id
/
--
SELECT mandatory,
       directive_type,
       utilization_limit,
       shares, 
       parallel_server_limit,
       pluggable_database, 
       status,
       comments
  FROM dba_cdb_rsrc_plan_directives
 WHERE plan = UPPER(TRIM('&plan.'))
 ORDER BY 
       mandatory DESC,
       directive_type,
       utilization_limit DESC,
       shares DESC,
       parallel_server_limit DESC,
       pluggable_database
/
--
SPO OFF;
HOS zip -mj &&zip_file_name..zip &&output_file_name..txt
HOS unzip -l &&zip_file_name..zip
