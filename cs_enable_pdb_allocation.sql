----------------------------------------------------------------------------------------
--
-- File name:   cs_enable_pdb_allocation.sql
--
-- Purpose:     Enable PDB Allocation
--
-- Author:      Carlos Sierra
--
-- Version:     2022/02/04
--
-- Usage:       Execute connected to CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_enable_pdb_allocation.sql
--
---------------------------------------------------------------------------------------
--
DEF cs_tools_schema = 'C##IOD';
--
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_is_primary VARCHAR2(5);
BEGIN
  SELECT CASE WHEN open_mode = 'READ WRITE' AND database_role = 'PRIMARY' THEN 'TRUE' ELSE 'FALSE' END AS is_primary INTO l_is_primary FROM v$database;
  IF l_is_primary = 'FALSE' THEN raise_application_error(-20000, 'Not PRIMARY'); END IF;
END;
/
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SPO /tmp/cs_enable_pdb_allocation.txt;
PRO
PRO 1. Enter ticket number if available?: [e.g: CHANGE-123]
DEF reference = '&1.';
UNDEF 1;
COL reference NEW_V reference FOR A30 NOPRI;
SELECT UPPER(TRIM('&&reference.')) AS reference FROM DUAL
/
SET SERVEROUT ON;
EXEC &&cs_tools_schema..iod_rsrc_mgr.enable_pdb_allocation(p_reference => '&&reference.');
SPO OFF;
CLEAR COLUMNS;
SET SERVEROUT OFF;
--
WHENEVER SQLERROR CONTINUE;