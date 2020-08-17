----------------------------------------------------------------------------------------
--
-- File name:   cs_blackout_end.sql
--
-- Purpose:     Blackout End - for OEM IOD Jobs
--
-- Author:      Carlos Sierra
--
-- Version:     2020/08/05
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
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF6';
--
SPO /tmp/cs_blackout_end.txt;
SET SERVEROUT ON;
COMMIT;
ALTER SESSION SET CONTAINER = CDB$ROOT;
--
-- PRO
-- PRO Retake Blackout
-- PRO ~~~~~~~~~~~~~~~
-- EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_end.sql Retake Blackout');
-- EXEC C##IOD.iod_admin.set_blackout(p_minutes => 60);
-- PRO
-- PRO Kill OEM IOD Jobs (wait 1 minute)
-- PRO ~~~~~~~~~~~~~~~~~
-- EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_end.sql Kill OEM IOD Jobs');
-- EXEC C##IOD.iod_admin.kill_iod_jobs;
PRO
PRO Ending Blackout
PRO ~~~~~~~~~~~~~~~
EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_end.sql Ending Blackout');
EXEC C##IOD.iod_admin.set_blackout(p_minutes => 0);
PRO
PRO Open Automatic Maintenance Windows (please wait)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_end.sql Open Automatic Maintenance Windows');
EXEC C##IOD.iod_amw.enable_pdb_auto_maint_windows;
PRO
PRO Starts IOD_CDB_PLAN Resource Manager Plan
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EXEC SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSDATE)||' cs_blackout_end.sql Starts IOD_CDB_PLAN Resource Manager Plan');
ALTER SYSTEM SET RESOURCE_MANAGER_PLAN='FORCE:IOD_CDB_PLAN';
PRO
PRO Blackout Ended
PRO ~~~~~~~~~~~~~~
SPO OFF;