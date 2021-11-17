/* -------------------------------------------------------------------------------------- */
--
-- File name:   /tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_ROLLBACK.sql
--
-- Purpose:     Rollsback Execution Plans for some SQL_ID or all SQL on a PDB using SQL Profile(s)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/05/12
--
-- Usage:       Connecting into PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @/tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_ROLLBACK.sql
--
/* --------------------------------------------------------------------------------------- */
-- exit if executed on standby or from CDB$ROOT
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
l_is_primary VARCHAR2(5);
BEGIN
SELECT CASE WHEN open_mode = 'READ WRITE' AND database_role = 'PRIMARY' THEN 'TRUE' ELSE 'FALSE' END AS is_primary INTO l_is_primary FROM v$database;
IF l_is_primary = 'FALSE' THEN raise_application_error(-20000, '*** MUST EXECUTE ON READ WRITE PRIMARY ***'); END IF;
IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN raise_application_error(-20000, '*** MUST EXECUTE ON PDB AND NOT ON CDB$ROOT ***'); END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET SERVEROUT ON;
COL report_time NEW_V report_time NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24.MI.SS') AS report_time FROM DUAL;
--
SPO /tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_ROLLBACK_&&report_time..txt;
PRO PRO
PRO PRO /tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_ROLLBACK_&&report_time..txt
PRO PRO
VAR v_rolled_back NUMBER;
EXEC :v_rolled_back := 0;
--
DECLARE
l_plans      NUMBER;
PROCEDURE o(p_line IN VARCHAR2) IS BEGIN DBMS_OUTPUT.put_line(p_line); END;
BEGIN
o('~~~~~~~~~~~~~~~~~~~~~~~~~~');
o('drop imported sql_profiles');
o('~~~~~~~~~~~~~~~~~~~~~~~~~~');
FOR i IN (SELECT name FROM dba_sql_profiles WHERE name LIKE 'exp_%_210910193242' AND category = 'DEFAULT' AND status = 'ENABLED' AND description LIKE '%][EXP][%')
LOOP
o('SPRF drop: '||i.name);
DBMS_SQLTUNE.drop_sql_profile(name => i.name);
:v_rolled_back := :v_rolled_back + 1;
END LOOP;
o('~~~~~~~~~~~~~~~~~~~~~~~~~');
o('enable prior sql_profiles');
o('~~~~~~~~~~~~~~~~~~~~~~~~~');
FOR i IN (SELECT name FROM dba_sql_profiles WHERE name NOT LIKE 'exp_%_210910193242' AND category = 'BACKUP' AND status = 'ENABLED' AND NVL(description, 'NULL') NOT LIKE '%][EXP][%')
LOOP
o('SPRF enable: '||i.name);
DBMS_SQLTUNE.alter_sql_profile(name => i.name, attribute_name => 'CATEGORY', value => 'DEFAULT');
END LOOP;
o('~~~~~~~~~~~~~~~~~~~~~~~~');
o('enable prior sql_patches');
o('~~~~~~~~~~~~~~~~~~~~~~~~');
FOR i IN (SELECT p.name FROM dba_sql_patches p WHERE p.category = 'BACKUP' AND p.status = 'ENABLED' AND NOT EXISTS (SELECT NULL FROM dba_sql_patches e WHERE e.name = p.name AND e.category = 'DEFAULT'))
LOOP
o('SPCH enable: '||i.name);
$IF DBMS_DB_VERSION.ver_le_12_1
$THEN
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', value => 'DEFAULT');
$ELSE
DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', attribute_value => 'DEFAULT');
$END
END LOOP;
o('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
o('enable prior sql_plan_baselines');
o('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
FOR i IN (SELECT p.sql_handle, p.plan_name, p.description FROM dba_sql_plan_baselines p WHERE p.enabled = 'NO' AND p.accepted = 'YES' AND p.description  LIKE '%[210910193242]%')
LOOP
o('SPBL enable: '||i.sql_handle||' '||i.plan_name||' '||i.description);
l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'YES');
END LOOP;
END;
/
--
PRINT v_rolled_back;
PRO PRO
PRO PRO /tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_ROLLBACK_&&report_time..txt
PRO PRO
SPO OFF;
SET SERVEROUT OFF;
--
-- /tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_ROLLBACK.sql
--
HOS ls -l /tmp/DBPERF-7513_2021-09-10T19.32.29Z_OC1_BOM_RGN_KIEV02RG_VCN_V2_cs_sprf_export_ROLLBACK*
