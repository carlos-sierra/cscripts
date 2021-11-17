----------------------------------------------------------------------------------------
--
-- File name:   cs_blackout_end.sql
--
-- Purpose:     Blackout End - for OEM IOD Jobs
--
-- Author:      Carlos Sierra
--
-- Version:     2021/11/13
--
-- Usage:       Execute connected to CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_blackout_end.sql
--
-- Steps:       1) Begin OEM IOD Blackout (Zapper, Space Maintenance, Session Killer, etc.)
--                 SQL> @cs_blackout_begin.sql
--
--              2) Perform Task that require Blackout
--
--              3) End OEM IOD Blackout (Zapper, Space Maintenance, Session Killer, etc.)
--                 SQL> @cs_blackout_end.sql
--
---------------------------------------------------------------------------------------
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
SPO /tmp/cs_blackout_end.txt;
SET SERVEROUT ON;
COMMIT;
COL cs_con_id NEW_V cs_con_id FOR A4 NOPRI;
COL cs_con_name NEW_V cs_con_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_ID') AS cs_con_id,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name
  FROM DUAL
/
--
ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
EXEC C##IOD.IOD_LOG.configure(logName => 'cs_blackout_end.sql', logToOutput => 'Y', logToAlertLog => 'Y'); 
PRO
PRO Blackout
PRO ~~~~~~~~
COL pmb FOR A20 HEA 'PART_MAINT_BLACKOUT';
SELECT begin_time, end_time, CASE part_maint_blackout WHEN 0 THEN 'N' ELSE 'Y' END AS pmb FROM C##IOD.blackout;
PRO
PRO Ending Blackout
PRO ~~~~~~~~~~~~~~~
-- EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_end.sql: Ending Blackout');
EXEC C##IOD.IOD_LOG.configure(logName => 'cs_blackout_end.sql', logToOutput => 'Y', logToAlertLog => 'Y'); 
EXEC C##IOD.IOD_LOG.info(msg => 'Ending Blackout');
EXEC C##IOD.iod_admin.set_blackout(p_minutes => 0, p_part_maint_blackout => 0);
PRO
PRO Open Automatic Maintenance Windows (please wait)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_end.sql: Open Automatic Maintenance Windows');
EXEC C##IOD.IOD_LOG.configure(logName => 'cs_blackout_end.sql', logToOutput => 'Y', logToAlertLog => 'Y'); 
EXEC C##IOD.IOD_LOG.info(msg => 'Open Automatic Maintenance Windows');
EXEC C##IOD.iod_amw.enable_pdb_auto_maint_windows;
PRO
--PRO Starts IOD_CDB_PLAN Resource Manager Plan
--PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_end.sql: Starts IOD_CDB_PLAN Resource Manager Plan');
--EXEC C##IOD.IOD_LOG.configure(logName => 'cs_blackout_end.sql', logToOutput => 'Y', logToAlertLog => 'Y'); 
--EXEC C##IOD.IOD_LOG.info(msg => ' Starts IOD_CDB_PLAN Resource Manager Plan');
--ALTER SYSTEM SET RESOURCE_MANAGER_PLAN='FORCE:IOD_CDB_PLAN';
PRO
PRO Blackout
PRO ~~~~~~~~
COL pmb FOR A20 HEA 'PART_MAINT_BLACKOUT';
SELECT begin_time, end_time, CASE part_maint_blackout WHEN 0 THEN 'N' ELSE 'Y' END AS pmb FROM C##IOD.blackout;
PRO
PRO Blackout Ended
PRO ~~~~~~~~~~~~~~
EXEC C##IOD.IOD_LOG.configure(logName => 'cs_blackout_end.sql', logToOutput => 'Y', logToAlertLog => 'Y'); 
EXEC C##IOD.IOD_LOG.info(msg => 'Blackout Ended');
SPO OFF;
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
WHENEVER SQLERROR CONTINUE;