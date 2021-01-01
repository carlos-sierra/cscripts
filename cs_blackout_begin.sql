----------------------------------------------------------------------------------------
--
-- File name:   cs_blackout_begin.sql
--
-- Purpose:     Blackout Begin - for OEM IOD Jobs
--
-- Author:      Carlos Sierra
--
-- Version:     2020/11/04
--
-- Usage:       Execute connected to CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_blackout_begin.sql
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
SPO /tmp/cs_blackout_begin.txt;
PRO
PRO 1. Enter Blackout Hours: [{1}|1-48]
DEF blackout_hours = '&1.';
UNDEF 1;
COL blackout_hours NEW_V blackout_hours FOR A3 NOPRI;
SELECT TRIM(TO_CHAR(TO_NUMBER(COALESCE(TRIM('&&blackout_hours.'), '1')))) AS blackout_hours FROM DUAL
/
PRO
PRO 2. Block also Partitions Maintenance?: [{N}|Y]
DEF part_maint_blackout = '&2.';
UNDEF 2;
COL part_maint_blackout NEW_V part_maint_blackout FOR A1 NOPRI;
SELECT CASE WHEN SUBSTR(TRIM(UPPER('&&part_maint_blackout.')), 1, 1) = 'Y' THEN '1' ELSE '0' END AS part_maint_blackout FROM DUAL
/
PRO
PRO 3. Enter ticket number if available?: [e.g: CHANGE-123]
DEF blackout_ticket = '&3.';
UNDEF 3;
COL blackout_ticket NEW_V blackout_ticket FOR A3 NOPRI;
SELECT UPPER('&&blackout_ticket.') AS blackout_ticket FROM DUAL
/
PRO
PRO 4. Additional blackout message for PDB communication?: [e.g: 19c Upgrade]
DEF blackout_pdb_message = '&4.';
UNDEF 4;
COL blackout_pdb_message NEW_V blackout_pdb_message FOR A3 NOPRI;
SELECT UPPER('&&blackout_pdb_message.') AS blackout_pdb_message FROM DUAL
/
SET SERVEROUT ON;
COMMIT;
ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
PRO
PRO Request Blackout
PRO ~~~~~~~~~~~~~~~~
EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_begin.sql: Request Blackout');
PRO
PRO Kill OEM IOD Jobs (wait 1 minute)
PRO ~~~~~~~~~~~~~~~~~
EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_begin.sql: Kill OEM IOD Jobs');
EXEC C##IOD.iod_admin.kill_iod_jobs;
EXEC C##IOD.iod_admin.set_blackout(p_minutes => &&blackout_hours. * 60, p_part_maint_blackout => &&part_maint_blackout., p_ticket => '&&blackout_ticket.', p_msgcontent => '&&blackout_pdb_message.');
PRO
PRO Close Automatic Maintenance Windows (please wait)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_begin.sql: Close Automatic Maintenance Windows');
EXEC C##IOD.iod_amw.disable_pdb_auto_maint_windows;
PRO
--PRO Stop IOD_CDB_PLAN Resource Manager Plan
--PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_begin.sql: Stops IOD_CDB_PLAN Resource Manager Plan');
--ALTER SYSTEM SET RESOURCE_MANAGER_PLAN='FORCE:';
PRO
PRO Blackout Began
PRO ~~~~~~~~~~~~~~
EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_begin.sql: Blackout Begin');
PRO
PRO Blackout
PRO ~~~~~~~~
COL pmb FOR A20 HEA 'PART_MAINT_BLACKOUT';
SELECT begin_time, end_time, CASE part_maint_blackout WHEN 0 THEN 'N' ELSE 'Y' END AS pmb FROM C##IOD.blackout;
PRO
PRO Execute Task that requires Blackout then execute cs_blackout_end.sql when done
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SPO OFF;
--
WHENEVER SQLERROR CONTINUE;