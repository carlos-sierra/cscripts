----------------------------------------------------------------------------------------
--
-- File name:   cs_blackout_status.sql
--
-- Purpose:     Blackout Status - for IOD/DBPERF Jobs
--
-- Author:      Carlos Sierra
--
-- Version:     2022/05/18
--
-- Usage:       Execute connected to CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_blackout_status.sql
--
-- Steps:       1) Begin IOD/DBPERF Blackout (Zapper, Space Maintenance, Session Killer, etc.)
--                 SQL> @cs_blackout_status.sql
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
PRO
PRO Blackout
PRO ~~~~~~~~
COL pmb FOR A20 HEA 'PART_MAINT_BLACKOUT';
COL locked FOR A6;
COL ticket FOR A20;
SELECT begin_time, end_time, CASE part_maint_blackout WHEN 0 THEN 'N' ELSE 'Y' END AS pmb, locked, ticket FROM &&cs_tools_schema..blackout WHERE id = 1;
PRO
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
    IF l_rec.locked = 'Y' THEN
      DBMS_OUTPUT.put_line('blackout locked!');
    END IF;
  ELSE
    DBMS_OUTPUT.put_line('not in blackout');
  END IF;
END;
/
--
SET SERVEROUT OFF;
CLEAR COLUMNS;
--
-- @@cs_internal/&&cs_set_container_to_curr_pdb.
ALTER SESSION SET CONTAINER = &&cs_con_name.;
PRO