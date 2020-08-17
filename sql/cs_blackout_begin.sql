----------------------------------------------------------------------------------------
--
-- File name:   cs_blackout_begin.sql
--
-- Purpose:     Blackout Begin - for OEM IOD Jobs
--
-- Author:      Carlos Sierra
--
-- Version:     2020/08/05
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
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
SET SERVEROUT ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF6';
--
PRO
PRO 1. Enter Blackout Hours: [{1}|1-24]
DEF blackout_hours = '&1.';
UNDEF 1;
COL blackout_hours NEW_V blackout_hours FOR A3 NOPRI;
SELECT TRIM(TO_CHAR(TO_NUMBER(COALESCE(TRIM('&&blackout_hours.'), '1')))) AS blackout_hours FROM DUAL
/
SPO /tmp/cs_blackout_begin.txt;
SET SERVEROUT ON;
COMMIT;
ALTER SESSION SET CONTAINER = CDB$ROOT;
--
PRO
PRO Request Blackout
PRO ~~~~~~~~~~~~~~~~
EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_begin.sql Request Blackout');
EXEC C##IOD.iod_admin.set_blackout(p_minutes => &&blackout_hours. * 60);
PRO
PRO Kill OEM IOD Jobs (wait 1 minute)
PRO ~~~~~~~~~~~~~~~~~
EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_begin.sql Kill OEM IOD Jobs');
EXEC C##IOD.iod_admin.kill_iod_jobs;
EXEC C##IOD.iod_admin.set_blackout(p_minutes => &&blackout_hours. * 60);
PRO
PRO Close Automatic Maintenance Windows (please wait)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_begin.sql Close Automatic Maintenance Windows');
EXEC C##IOD.iod_amw.disable_pdb_auto_maint_windows;
PRO
PRO Stop IOD_CDB_PLAN Resource Manager Plan
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_begin.sql Stops IOD_CDB_PLAN Resource Manager Plan');
ALTER SYSTEM SET RESOURCE_MANAGER_PLAN='FORCE:';
PRO
PRO Blackout Began
PRO ~~~~~~~~~~~~~~
EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_begin.sql Blackout Begin');
PRO
PRO Execute Task that requires Blackout then execute cs_blackout_end.sql when done
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SPO OFF;
--