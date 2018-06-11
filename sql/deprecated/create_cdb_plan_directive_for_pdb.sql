-- Outputs a scrtipt with CDB plan directives for a PDB that is migrated
PRO Enter pdb_name;
DEF pdb_name = '&&1.';
DEF plan_name = 'IOD_CDB_PLAN';

VAR create_cdb_plan_directive CLOB;
BEGIN
:create_cdb_plan_directive := q'[
-- Execute this script on Target CDB where a PDB is being migrated
SET SERVEROUT ON;
DECLARE
  gk_plan CONSTANT VARCHAR2(128) := 'PLAN_NAME';
  gk_pluggable_database CONSTANT VARCHAR2(128) := 'PDB_NAME';
  gk_shares CONSTANT NUMBER := SHARES;
  gk_utilization_limit CONSTANT NUMBER := UTILIZATION_LIMIT;
  gk_parallel_server_limit CONSTANT NUMBER := PARALLEL_SERVER_LIMIT;
  gk_date_format CONSTANT VARCHAR2(30) := 'YYYY-MM-DD"T"HH24:MI:SS';
  l_open_mode VARCHAR2(20);
  l_count NUMBER;
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    RETURN;
  END IF;
  SELECT COUNT(*) INTO l_count FROM dba_cdb_rsrc_plans WHERE plan = gk_plan;
  IF l_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Create RSRC MGR Plan: '||gk_plan);
    DBMS_RESOURCE_MANAGER.clear_pending_area;
    DBMS_RESOURCE_MANAGER.create_pending_area;
    DBMS_RESOURCE_MANAGER.create_cdb_plan (
      plan    => gk_plan,
      comment => 'IOD_RSRC_MGR '||TO_CHAR(SYSDATE, gk_date_format)
    );
    DBMS_RESOURCE_MANAGER.validate_pending_area;
    DBMS_RESOURCE_MANAGER.submit_pending_area;
  ELSE
    DBMS_OUTPUT.PUT_LINE('RSRC MGR Plan already exists: '||gk_plan);
  END IF;
  SELECT COUNT(*) INTO l_count FROM dba_cdb_rsrc_plan_directives WHERE plan = gk_plan AND pluggable_database = gk_pluggable_database;
  IF l_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Create RSRC MGR Directive: '||gk_pluggable_database||' for '||gk_plan);
    DBMS_RESOURCE_MANAGER.clear_pending_area;
    DBMS_RESOURCE_MANAGER.create_pending_area;
    DBMS_RESOURCE_MANAGER.create_cdb_plan_directive (
      plan                      => gk_plan,
      pluggable_database        => gk_pluggable_database,
      comment                   => 'IOD_RSRC_MGR NEW:'||TO_CHAR(SYSDATE, gk_date_format),
      shares                    => gk_shares,
      utilization_limit         => gk_utilization_limit,
      parallel_server_limit     => gk_parallel_server_limit
    );
    DBMS_RESOURCE_MANAGER.validate_pending_area;
    DBMS_RESOURCE_MANAGER.submit_pending_area;
  ELSE
    DBMS_OUTPUT.PUT_LINE('PDB directive already exists: '||gk_pluggable_database);
  END IF;
END;
]'||CHR(47);
END;
/

SET HEA OFF LIN 500 PAGES 0 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET LONG 50000 LONGC 500;

COL output_filename NEW_V output_filename;

SELECT 'create_cdb_plan_directive_for_'||UPPER(TRIM('&&pdb_name.'))||'_on_'||UPPER(TRIM('&&plan_name.')) output_filename FROM DUAL;

SPO &&output_filename..sql

SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(:create_cdb_plan_directive, 'PLAN_NAME', UPPER(TRIM('&&plan_name.'))), 'PDB_NAME', UPPER(TRIM('&&pdb_name.'))), 'UTILIZATION_LIMIT', utilization_limit), 'SHARES', shares), 'PARALLEL_SERVER_LIMIT', parallel_server_limit) create_cdb_plan_directive
  FROM dba_cdb_rsrc_plan_directives
 WHERE plan = UPPER(TRIM('&&plan_name.'))
   AND pluggable_database = UPPER(TRIM('&&pdb_name.'))
/

SPO OFF;
PRO
HOS cat &&output_filename..sql
PRO
PRO Execute &&output_filename..sql on Target
