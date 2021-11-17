/* -------------------------------------------------------------------------------------- */
--
-- File name:   /tmp/DBPERF-7120_2021-05-12T12.35.47Z_SEA_RGN_IOD01_COMPARTMENTS_WFAAS_cs_sprf_export_VERIFY.sql
--
-- Purpose:     Verify Implemented Execution Plans for some SQL_ID or all SQL on a PDB using SQL Profile(s)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/01/20
--
-- Usage:       Connecting into PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @/tmp/DBPERF-7120_2021-05-12T12.35.47Z_SEA_RGN_IOD01_COMPARTMENTS_WFAAS_cs_sprf_export_VERIFY.sql
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
SET FEED ON SERVEROUT ON;
COL report_time NEW_V report_time NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24.MI.SS') AS report_time FROM DUAL;
--
SPO /tmp/DBPERF-7120_2021-05-12T12.35.47Z_SEA_RGN_IOD01_COMPARTMENTS_WFAAS_cs_sprf_export_VERIFY_&&report_time..txt;
PRO PRO
PRO PRO /tmp/DBPERF-7120_2021-05-12T12.35.47Z_SEA_RGN_IOD01_COMPARTMENTS_WFAAS_cs_sprf_export_VERIFY_&&report_time..txt
PRO PRO
SELECT * FROM dba_sql_profiles WHERE name LIKE 'exp_%_210512123640' AND category = 'DEFAULT' AND status = 'ENABLED' AND description LIKE '%][EXP][%';
PRO PRO
PRO PRO /tmp/DBPERF-7120_2021-05-12T12.35.47Z_SEA_RGN_IOD01_COMPARTMENTS_WFAAS_cs_sprf_export_VERIFY_&&report_time..txt
PRO PRO
SPO OFF;
SET FEED OFF SERVEROUT OFF;
--
-- /tmp/DBPERF-7120_2021-05-12T12.35.47Z_SEA_RGN_IOD01_COMPARTMENTS_WFAAS_cs_sprf_export_VERIFY.sql
--
HOS ls -l /tmp/DBPERF-7120_2021-05-12T12.35.47Z_SEA_RGN_IOD01_COMPARTMENTS_WFAAS_cs_sprf_export_VERIFY*
