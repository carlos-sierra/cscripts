----------------------------------------------------------------------------------------
--
-- File name:   cs_blackout_status.sql
--
-- Purpose:     Blackout Status - for OEM IOD Jobs
--
-- Author:      Carlos Sierra
--
-- Version:     2021/10/13
--
-- Usage:       Execute connected to CDB
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_blackout_status.sql
--
-- Steps:       1) Begin OEM IOD Blackout (Zapper, Space Maintenance, Session Killer, etc.)
--                 SQL> @cs_blackout_status.sql
--
--              2) Perform Task that require Blackout
--
--              3) End OEM IOD Blackout (Zapper, Space Maintenance, Session Killer, etc.)
--                 SQL> @cs_blackout_end.sql
--
---------------------------------------------------------------------------------------
--
COL cs_con_id NEW_V cs_con_id FOR A4 NOPRI;
COL cs_con_name NEW_V cs_con_name FOR A30 NOPRI;
SELECT SYS_CONTEXT('USERENV', 'CON_ID') AS cs_con_id,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name
  FROM DUAL
/
--
ALTER SESSION SET CONTAINER = CDB$ROOT;
--
SET SERVEROUT ON;
DECLARE
  l_count INTEGER;
  l_rec C##IOD.blackout%ROWTYPE;
BEGIN    
  SELECT COUNT(*) INTO l_count  FROM dba_rolling_plan;
  SELECT * INTO l_rec FROM C##IOD.blackout WHERE id = 1;
  --
  IF l_count > 0 THEN
    DBMS_OUTPUT.put_line('in rolling upgrade');
  ELSIF SYSDATE BETWEEN l_rec.begin_time AND l_rec.end_time THEN
    DBMS_OUTPUT.put_line('blackout in progress for the next '||TRIM(TO_CHAR((l_rec.end_time - SYSDATE) * 24 * 60, '9,990.0'))||' minutes, until '||TO_CHAR(l_rec.end_time, 'YYYY-MM-DD"T"HH24:MI:SS'));
  ELSE
    DBMS_OUTPUT.put_line('not in blackout');
  END IF;
END;
/
--
ALTER SESSION SET CONTAINER = &&cs_con_name.;
