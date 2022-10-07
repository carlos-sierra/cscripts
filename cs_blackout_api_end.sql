----------------------------------------------------------------------------------------
--
-- File name:   cs_blackout_api_end.sql
--
-- Purpose:     Blackout API Begin - for IOD/DBPERF APIs
--
-- Author:      Carlos Sierra
--
-- Version:     2022/05/18
--
-- Usage:       Execute connected to CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_blackout_api_end.sql
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
COL cs_con_id NEW_V cs_con_id FOR A4 NOPRI;
COL cs_con_name NEW_V cs_con_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_ID') AS cs_con_id,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name
  FROM DUAL
/
-- @@cs_internal/&&cs_set_container_to_cdb_root.
ALTER SESSION SET container = CDB$ROOT;
PRO
PRO APIs
PRO ~~~~
COL api FOR A61;
COL in_blackout FOR A11;
COL hours FOR 990.0;
COL ticket FOR A20;
SELECT api, CASE WHEN SYSDATE BETWEEN begin_time AND end_time THEN 'BLACKOUT' END AS in_blackout, CASE WHEN end_time > SYSDATE THEN (end_time - SYSDATE) * 24 END AS hours, begin_time, end_time, ticket
  FROM &&cs_tools_schema..blackout_api
 WHERE api NOT IN ('__anonymous_block', 'IOD_RSRC_MGR.GET_CDB_WEIGHT')
 ORDER BY api
/
PRO
PRO 1. API:
DEF api_name = '&1.';
UNDEF 1;
--
SPO /tmp/cs_blackout_api_end_&&api_name..txt;
--
PRO
PRO End API Blackout
PRO ~~~~~~~~~~~~~~~~
EXEC &&cs_tools_schema..IOD_LOG.configure(logName => 'cs_blackout_api_end.sql', logToOutput => 'Y', logToAlertLog => 'Y'); 
EXEC &&cs_tools_schema..IOD_LOG.info(msg => 'Request End Blackout. api:"&&api_name."');
UPDATE &&cs_tools_schema..blackout_api SET end_time = SYSDATE - (1/24/3600), ticket = NULL WHERE api = TRIM('&&api_name.');
COMMIT;
EXEC &&cs_tools_schema..IOD_LOG.info(msg => 'Blackout API Ended');
PRO
PRO APIs
PRO ~~~~
COL api FOR A61;
COL in_blackout FOR A11;
COL hours FOR 990.0;
COL ticket FOR A20;
SELECT api, CASE WHEN SYSDATE BETWEEN begin_time AND end_time THEN 'BLACKOUT' END AS in_blackout, CASE WHEN end_time > SYSDATE THEN (end_time - SYSDATE) * 24 END AS hours, begin_time, end_time, ticket
  FROM &&cs_tools_schema..blackout_api
 WHERE api NOT IN ('__anonymous_block', 'IOD_RSRC_MGR.GET_CDB_WEIGHT')
 ORDER BY api
/
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