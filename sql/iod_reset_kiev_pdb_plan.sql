----------------------------------------------------------------------------------------
--
-- File name:   iod_reset_kiev_pdb_plan.sql
--
-- Purpose:     Resets the CDB Resource Plan KIEV_PDB_PLAN. It does:
--              1. Creates CDB Resource Plan KIEV_PDB_PLAN if it does not exist.
--              2. Resets values for default and autotask directives
--              3. Drops PDB directives since all are treated equal (thus use default)
--              4. Enables instance caging and sets the KIEV_PDB_PLAN.
--              
--
-- Author:      Carlos Sierra
--
-- Version:     2017/08/08
--
-- Usage:       Execute on CDB$ROOT
--
-- Example:     @iod_reset_kiev_pdb_plan.sql
--
-- Notes:       Based on prior scripts created by Pop Ceschim
--
---------------------------------------------------------------------------------------
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
WHENEVER SQLERROR EXIT FAILURE;
SET SERVEROUT ON ECHO OFF FEED OFF VER OFF TAB OFF LINES 300;

COL report_date NEW_V report_date;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24-MI-SS') report_date FROM DUAL;
SPO /tmp/iod_reset_kiev_pdb_plan_&&report_date..txt;

COL plan FOR A30;
COL comments FOR A40;
COL status FOR A10;
COL pluggable_database FOR A30;
COL directive_type FOR A20;
PRO
SELECT   plan
       , comments
       --, plan_id
       --, status
       --, mandatory
  FROM dba_cdb_rsrc_plans
 ORDER BY
         plan
/
PRO
SELECT   plan
       , pluggable_database
       , shares
       , utilization_limit
       , parallel_server_limit
       , directive_type
       , comments
       --, status
       --, mandatory
  FROM dba_cdb_rsrc_plan_directives
 ORDER BY
         plan
       , directive_type
       , pluggable_database
/
PRO

SHOW PARAMETER resource_manager_plan;
SELECT value resource_manager_plan FROM v$parameter WHERE name = 'resource_manager_plan'; 
SHOW PARAMETER cpu_count;
-- if query below returns no rows then instance caging is not enabled
SELECT value cpu_count FROM v$parameter WHERE name = 'cpu_count' AND (isdefault = 'FALSE' OR ismodified != 'FALSE'); 

DECLARE
  -- ok to adjust
  l_default_cpu_limit NUMBER := 100;
  l_autotask_cpu_limit NUMBER := 50;
  l_default_parallel_limit NUMBER := 100;
  l_autotask_parallel_limit NUMBER := 100;
  l_default_shares NUMBER := 2;
  l_autotask_shares NUMBER := 1;
  l_kiev_plan VARCHAR2(128) := 'KIEV_PDB_PLAN';
  l_comments VARCHAR2(2000) := 'CDB Plan for KIEV PDBs';
  l_cpu_limit NUMBER := 72; -- 72 is consistent with v$osstat num_cpus. 65 would be 90% of num_cpus = 0.9 * 72
  -- do not adjust
  l_rm_default_shares NUMBER := 1;
  l_rm_default_cpu NUMBER := 100;
  l_rm_default_parallel NUMBER := 100;
  -- variables
  l_max_plan_id NUMBER;
  l_max_comments VARCHAR2(2000);
  l_cpu_count NUMBER;
  l_resource_manager_plan VARCHAR2(128);
  l_def_dir_rec dba_cdb_rsrc_plan_directives%ROWTYPE;
  l_aut_dir_rec dba_cdb_rsrc_plan_directives%ROWTYPE;
BEGIN
  SELECT MAX(plan_id), MAX(comments) INTO l_max_plan_id, l_max_comments FROM dba_cdb_rsrc_plans WHERE plan = l_kiev_plan;
  IF l_max_plan_id IS NULL THEN -- new plan
    DBMS_RESOURCE_MANAGER.CLEAR_PENDING_AREA;
    DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA;
    DBMS_RESOURCE_MANAGER.CREATE_CDB_PLAN(plan=>l_kiev_plan, comment=>l_comments);
    DBMS_RESOURCE_MANAGER.UPDATE_CDB_DEFAULT_DIRECTIVE(plan=>l_kiev_plan, new_comment=>'Default Directive', new_shares=>l_default_shares, new_utilization_limit=>l_default_cpu_limit, new_parallel_server_limit=>l_default_parallel_limit);
    DBMS_RESOURCE_MANAGER.UPDATE_CDB_AUTOTASK_DIRECTIVE(plan=>l_kiev_plan, new_comment=>'Autotask Directive', new_shares=>l_autotask_shares, new_utilization_limit=>l_autotask_cpu_limit, new_parallel_server_limit=>l_autotask_parallel_limit);
    DBMS_RESOURCE_MANAGER.VALIDATE_PENDING_AREA;
    DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA;
  ELSE -- plan exists
    SELECT * INTO l_def_dir_rec FROM dba_cdb_rsrc_plan_directives WHERE plan = l_kiev_plan AND directive_type = 'DEFAULT_DIRECTIVE' AND mandatory = 'YES';
    SELECT * INTO l_aut_dir_rec FROM dba_cdb_rsrc_plan_directives WHERE plan = l_kiev_plan AND directive_type = 'AUTOTASK' AND mandatory = 'YES';
    IF l_max_comments <> l_comments 
    OR NVL(l_def_dir_rec.shares, l_rm_default_shares) <> l_default_shares OR NVL(l_def_dir_rec.utilization_limit, l_rm_default_cpu) <> l_default_cpu_limit OR NVL(l_def_dir_rec.parallel_server_limit, l_rm_default_parallel) <> l_default_parallel_limit OR NVL(l_def_dir_rec.comments, 'NULL') <> 'Default Directive'
    OR NVL(l_aut_dir_rec.shares, l_rm_default_shares) <> l_autotask_shares OR NVL(l_aut_dir_rec.utilization_limit, l_rm_default_cpu) <> l_autotask_cpu_limit OR NVL(l_aut_dir_rec.parallel_server_limit, l_rm_default_parallel) <> l_autotask_parallel_limit OR NVL(l_aut_dir_rec.comments, 'NULL') <> 'Autotask Directive'
    THEN -- update
      DBMS_RESOURCE_MANAGER.CLEAR_PENDING_AREA;
      DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA;
      IF l_max_comments <> l_comments THEN
        DBMS_RESOURCE_MANAGER.UPDATE_CDB_PLAN(plan=>l_kiev_plan,new_comment=>l_comments);
      END IF;
      -- reset default directive
      IF NVL(l_def_dir_rec.shares, l_rm_default_shares) <> l_default_shares OR NVL(l_def_dir_rec.utilization_limit, l_rm_default_cpu) <> l_default_cpu_limit OR NVL(l_def_dir_rec.parallel_server_limit, l_rm_default_parallel) <> l_default_parallel_limit OR NVL(l_def_dir_rec.comments, 'NULL') <> 'Default Directive' THEN
        DBMS_RESOURCE_MANAGER.UPDATE_CDB_DEFAULT_DIRECTIVE(plan=>l_kiev_plan, new_comment=>'Default Directive', new_shares=>l_default_shares, new_utilization_limit=>l_default_cpu_limit, new_parallel_server_limit=>l_default_parallel_limit);
      END IF;
      -- reset autotask directive
      IF NVL(l_aut_dir_rec.shares, l_rm_default_shares) <> l_autotask_shares OR NVL(l_aut_dir_rec.utilization_limit, l_rm_default_cpu) <> l_autotask_cpu_limit OR NVL(l_aut_dir_rec.parallel_server_limit, l_rm_default_parallel) <> l_autotask_parallel_limit OR NVL(l_aut_dir_rec.comments, 'NULL') <> 'Autotask Directive' THEN
        DBMS_RESOURCE_MANAGER.UPDATE_CDB_AUTOTASK_DIRECTIVE(plan=>l_kiev_plan, new_comment=>'Autotask Directive', new_shares=>l_autotask_shares, new_utilization_limit=>l_autotask_cpu_limit, new_parallel_server_limit=>l_autotask_parallel_limit);
      END IF;
      DBMS_RESOURCE_MANAGER.VALIDATE_PENDING_AREA;
      DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA;
      --
      -- delete PDB directives if any
      FOR i IN (SELECT pluggable_database FROM dba_cdb_rsrc_plan_directives WHERE plan = l_kiev_plan AND directive_type = 'PDB' AND mandatory = 'NO' ORDER BY pluggable_database)
      LOOP
        DBMS_RESOURCE_MANAGER.CLEAR_PENDING_AREA;
        DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA;
        DBMS_RESOURCE_MANAGER.DELETE_CDB_PLAN_DIRECTIVE(plan=>l_kiev_plan, pluggable_database=>i.pluggable_database);
        DBMS_RESOURCE_MANAGER.VALIDATE_PENDING_AREA;
        DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA;
      END LOOP;
    END IF;
  END IF;
  --
  SELECT MAX(TO_NUMBER(value)) INTO l_cpu_count FROM v$parameter WHERE name = 'cpu_count' AND (isdefault = 'FALSE' OR ismodified != 'FALSE'); 
  IF NVL(l_cpu_count, 0) <> l_cpu_limit THEN
    -- enable instance caging
    EXECUTE IMMEDIATE 'ALTER SYSTEM SET cpu_count='||l_cpu_limit||' SCOPE=both';
  END IF;
  --
  SELECT value INTO l_resource_manager_plan FROM v$parameter WHERE name = 'resource_manager_plan'; 
  IF l_resource_manager_plan <> 'FORCE:'||UPPER(l_kiev_plan) THEN
     -- sets plan
    EXECUTE IMMEDIATE 'ALTER SYSTEM SET resource_manager_plan=''FORCE:'||UPPER(l_kiev_plan)||''' SCOPE=both';
  END IF;
END;
/

SHOW PARAMETER resource_manager_plan;
SELECT value resource_manager_plan FROM v$parameter WHERE name = 'resource_manager_plan'; 
SHOW PARAMETER cpu_count;
-- if query below returns no rows then instance caging is not enabled
SELECT value cpu_count FROM v$parameter WHERE name = 'cpu_count' AND (isdefault = 'FALSE' OR ismodified != 'FALSE'); 

PRO
SELECT   plan
       , comments
       --, plan_id
       --, status
       --, mandatory
  FROM dba_cdb_rsrc_plans
 ORDER BY
         plan
/
PRO
SELECT   plan
       , pluggable_database
       , shares
       , utilization_limit
       , parallel_server_limit
       , directive_type
       , comments
       --, status
       --, mandatory
  FROM dba_cdb_rsrc_plan_directives
 ORDER BY
         plan
       , directive_type
       , pluggable_database
/
PRO

SPO OFF;

EXIT;