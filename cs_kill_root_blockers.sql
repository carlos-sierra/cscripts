----------------------------------------------------------------------------------------
--
-- File name:   cs_kill_root_blockers.sql
--
-- Purpose:     Kill Root Blocker User Sessions 
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kill_root_blockers.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET SERVEROUT ON;
DECLARE
  l_sid_serial DBMS_UTILITY.name_array; -- e.g.: 123,90536 (associative array type)
  l_statament VARCHAR2(32767);
  session_marked_for_kill EXCEPTION;
  PRAGMA EXCEPTION_INIT(session_marked_for_kill, -00031); -- ORA-00031: session marked for kill
  session_does_not_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT(session_does_not_exist, -00030); -- ORA-00030: User session ID does not exist.
BEGIN
  SELECT root_blocker.sid||','||root_blocker.serial# 
  BULK COLLECT INTO l_sid_serial
  FROM v$session blockee, v$session root_blocker 
  WHERE blockee.type = 'USER' AND blockee.sid <> SYS_CONTEXT('USERENV', 'SID') AND blockee.final_blocking_session_status = 'VALID' 
  AND root_blocker.sid = blockee.final_blocking_session AND root_blocker.type = 'USER' AND root_blocker.sid <> SYS_CONTEXT('USERENV', 'SID');
  --
  IF l_sid_serial.LAST >= l_sid_serial.FIRST THEN -- sessions found
    SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF3')||' cs_kill_root_blockers: killing '||(l_sid_serial.LAST - l_sid_serial.FIRST + 1)||' root blocker sessions');
    FOR i IN l_sid_serial.FIRST .. l_sid_serial.LAST
    LOOP
      l_statament := 'ALTER SYSTEM DISCONNECT SESSION '''||l_sid_serial(i)||''' IMMEDIATE';
      DBMS_OUTPUT.put_line(l_statament||';');
      BEGIN
        EXECUTE IMMEDIATE l_statament;
      EXCEPTION
        WHEN session_marked_for_kill OR session_does_not_exist THEN NULL;
      END;
    END LOOP;
    SYS.DBMS_OUTPUT.put_line((l_sid_serial.LAST - l_sid_serial.FIRST + 1)||' sessions killed!');
  ELSE
    DBMS_OUTPUT.put_line('no sessions found');
  END IF;
END;
/