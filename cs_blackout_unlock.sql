----------------------------------------------------------------------------------------
--
-- File name:   cs_blackout_unlock.sql
--
-- Purpose:     Blackout Unlock - for IOD/DBPERF Jobs
--
-- Author:      Carlos Sierra
--
-- Version:     2022/05/18
--
-- Usage:       Execute connected to CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_blackout_unlock.sql
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
SPO /tmp/cs_blackout_unlock.txt;
COL cs_con_id NEW_V cs_con_id FOR A4 NOPRI;
COL cs_con_name NEW_V cs_con_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_ID') AS cs_con_id,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name
  FROM DUAL
/
--
-- @@cs_internal/&&cs_set_container_to_cdb_root.
ALTER SESSION SET container = CDB$ROOT;
--
EXEC &&cs_tools_schema..IOD_LOG.configure(logName => 'cs_blackout_unlock.sql', logToOutput => 'Y', logToAlertLog => 'Y'); 
EXEC &&cs_tools_schema..IOD_LOG.info(msg => 'Unock Blackout');
--
DECLARE
  l_count INTEGER;
  l_rec &&cs_tools_schema..blackout%ROWTYPE;
BEGIN    
  SELECT COUNT(*) INTO l_count  FROM dba_rolling_plan;
  SELECT * INTO l_rec FROM &&cs_tools_schema..blackout WHERE id = 1;
  --
  IF l_count > 0 THEN
    DBMS_OUTPUT.put_line('in rolling upgrade');
  ELSIF SYSDATE BETWEEN l_rec.begin_time AND l_rec.end_time THEN
    DBMS_OUTPUT.put_line('blackout in progress for the next '||TRIM(TO_CHAR((l_rec.end_time - SYSDATE) * 24 * 60, '9,990.0'))||' minutes, until '||TO_CHAR(l_rec.end_time, 'YYYY-MM-DD"T"HH24:MI:SS')||' ticket:'||l_rec.ticket);
    UPDATE &&cs_tools_schema..blackout SET locked = 'N' WHERE id = 1;
    COMMIT;
    &&cs_tools_schema..IOD_LOG.info(msg => 'blackout unlocked!');
  ELSE
    DBMS_OUTPUT.put_line('not in blackout');
  END IF;
END;
/
PRO
PRO Blackout
PRO ~~~~~~~~
COL pmb FOR A20 HEA 'PART_MAINT_BLACKOUT';
COL locked FOR A6;
COL ticket FOR A20;
SELECT begin_time, end_time, CASE part_maint_blackout WHEN 0 THEN 'N' ELSE 'Y' END AS pmb, locked, ticket FROM &&cs_tools_schema..blackout WHERE id = 1;
PRO
--
SPO OFF;
SET SERVEROUT OFF;
CLEAR COLUMNS;
--
@@cs_internal/&&cs_set_container_to_curr_pdb.
PRO
--
WHENEVER SQLERROR CONTINUE;