----------------------------------------------------------------------------------------
--
-- File name:   cs_blackout_begin.sql
--
-- Purpose:     Blackout Begin - for IOD/DBPERF Jobs
--
-- Author:      Carlos Sierra
--
-- Version:     2022/05/18
--
-- Usage:       Execute connected to CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_blackout_begin.sql
--
-- Steps:       1) Begin IOD/DBPERF Blackout (Zapper, Space Maintenance, Session Killer, etc.)
--                 SQL> @cs_blackout_begin.sql
--
--              2) Perform Task that requires Blackout
--
--              3) End IOD/DBPERF Blackout (Zapper, Space Maintenance, Session Killer, etc.)
--                 SQL> @cs_blackout_end.sql
--
-- Notes:       1) To "lock" the Blackout so it cannot be ended
--                 SQL> @cs_blackout_lock.sql
--
--              2) To "unlock" the Blackout so it can be ended
--                 SQL> @cs_blackout_unlock.sql
--
--              3) To begin a blackout of one IOD/DBPERF API
--                 SQL> @cs_blackout_api_begin.sql
--
--              4) To end a blackout of one IOD/DBPERF API
--                 SQL> @cs_blackout_api_end.sql
--
---------------------------------------------------------------------------------------
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET SERVEROUT ON;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
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
SPO /tmp/cs_blackout_begin.txt;
PRO
PRO 1. Enter Blackout Hours: [{1}|1-120]
DEF blackout_hours = '&1.';
UNDEF 1;
COL blackout_hours NEW_V blackout_hours FOR A3 NOPRI;
SELECT TRIM(TO_CHAR(TO_NUMBER(COALESCE(TRIM('&&blackout_hours.'), '1')))) AS blackout_hours FROM DUAL
/
-- warn if blackout hours is out of range
BEGIN
  IF NOT TO_NUMBER('&&blackout_hours.') BETWEEN 1 AND 120 THEN
    DBMS_OUTPUT.put_line(CHR(10));
    DBMS_OUTPUT.put_line('***');
    DBMS_OUTPUT.put_line('*** &&blackout_hours. is out of range, API caps at 120 ***');
    DBMS_OUTPUT.put_line('***');
    DBMS_OUTPUT.put_line(CHR(10));
  END IF;
END;
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
COL blackout_ticket NEW_V blackout_ticket FOR A128 NOPRI;
SELECT UPPER(TRIM('&&blackout_ticket.')) AS blackout_ticket FROM DUAL
/
PRO
PRO 4. Additional blackout message for PDB communication?: [e.g: 19c Upgrade]
DEF blackout_pdb_message = '&4.';
UNDEF 4;
COL blackout_pdb_message NEW_V blackout_pdb_message FOR A128 NOPRI;
SELECT UPPER(TRIM('&&blackout_pdb_message.')) AS blackout_pdb_message FROM DUAL
/
--
COL cs_con_id NEW_V cs_con_id FOR A4 NOPRI;
COL cs_con_name NEW_V cs_con_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_ID') AS cs_con_id,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name
  FROM DUAL
/
--
-- @@cs_internal/&&cs_set_container_to_cdb_root.
ALTER SESSION SET container = CDB$ROOT;
EXEC &&cs_tools_schema..IOD_LOG.configure(logName => 'cs_blackout_begin.sql', logToOutput => 'Y', logToAlertLog => 'Y'); 
--
PRO
PRO Blackout Status
PRO ~~~~~~~~~~~~~~~
COL pmb FOR A20 HEA 'PART_MAINT_BLACKOUT';
COL locked FOR A6;
COL ticket FOR A20;
SELECT begin_time, end_time, CASE part_maint_blackout WHEN 0 THEN 'N' ELSE 'Y' END AS pmb, locked, ticket FROM &&cs_tools_schema..blackout WHERE id = 1;
PRO
PRO Request Blackout
PRO ~~~~~~~~~~~~~~~~
EXEC &&cs_tools_schema..IOD_LOG.info(msg => 'Request Blackout. blackout_hours:"&&blackout_hours." part_maint_blackout:"&&part_maint_blackout." blackout_ticket:"&&blackout_ticket." blackout_pdb_message:"&&blackout_pdb_message."');
PRO
PRO Kill IOD/DBPERF Jobs? (wait up to 1 minute)
PRO ~~~~~~~~~~~~~~~~~~~~~
BEGIN -- check if it is already in a blackout and not kill any running jobs
  IF &&cs_tools_schema..iod_admin.in_blackout(p_outputs_call_stack => FALSE, p_performs_dml => FALSE) THEN
    DBMS_OUTPUT.put_line('Since already in Blackout there is no need to kill jobs!');
  ELSE
    &&cs_tools_schema..IOD_LOG.configure(logName => 'cs_blackout_begin.sql', logToOutput => 'Y', logToAlertLog => 'Y'); 
    &&cs_tools_schema..IOD_LOG.info(msg => 'Kill executing IOD/DBPERF Jobs');
    &&cs_tools_schema..iod_admin.kill_iod_jobs;
  END IF;
END;
/
PRO
PRO Set Blackout
PRO ~~~~~~~~~~~~
EXEC &&cs_tools_schema..iod_admin.set_blackout(p_minutes => &&blackout_hours. * 60, p_part_maint_blackout => &&part_maint_blackout., p_ticket => '&&blackout_ticket.', p_msgcontent => '&&blackout_pdb_message.');
PRO
PRO Close Automatic Maintenance Windows? (please wait)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EXEC &&cs_tools_schema..IOD_LOG.configure(logName => 'cs_blackout_begin.sql', logToOutput => 'Y', logToAlertLog => 'Y'); 
EXEC &&cs_tools_schema..IOD_LOG.info(msg => 'Close Automatic Maintenance Windows');
EXEC &&cs_tools_schema..iod_amw.disable_pdb_auto_maint_windows;
PRO
PRO Blackout Began
PRO ~~~~~~~~~~~~~~
EXEC &&cs_tools_schema..IOD_LOG.configure(logName => 'cs_blackout_begin.sql', logToOutput => 'Y', logToAlertLog => 'Y'); 
EXEC &&cs_tools_schema..IOD_LOG.info(msg => 'Blackout Began');
PRO
PRO Blackout Status
PRO ~~~~~~~~~~~~~~~
COL pmb FOR A20 HEA 'PART_MAINT_BLACKOUT';
COL locked FOR A6;
COL ticket FOR A20;
SELECT begin_time, end_time, CASE part_maint_blackout WHEN 0 THEN 'N' ELSE 'Y' END AS pmb, locked, ticket FROM &&cs_tools_schema..blackout WHERE id = 1;
PRO
PRO Note: Execute Task that requires Blackout then execute cs_blackout_end.sql when done
PRO
SPO OFF;
SET SERVEROUT OFF;
CLEAR COLUMNS;
--
-- @@cs_internal/&&cs_set_container_to_curr_pdb.
ALTER SESSION SET CONTAINER = &&cs_con_name.;
PRO
--
WHENEVER SQLERROR CONTINUE;