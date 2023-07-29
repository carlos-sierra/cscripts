----------------------------------------------------------------------------------------
--
-- File name:   cs_kill_sql_id.sql
--
-- Purpose:     Kill User Sessions executing some SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kill_sql_id.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
PRO
PRO 1. Enter SQL_ID:
DEF sql_id = '&1.';
UNDEF 1;
--
VAR sql_id VARCHAR2(13);
EXEC :sql_id := '&&sql_id.';
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
  SELECT sid||','||serial# 
  BULK COLLECT INTO l_sid_serial 
  FROM v$session 
  WHERE type = 'USER' AND sql_id = :sql_id AND sid <> SYS_CONTEXT('USERENV', 'SID');
  --
  IF l_sid_serial.LAST >= l_sid_serial.FIRST THEN -- sessions found
    SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF3')||' cs_kill_sql_id: killing '||(l_sid_serial.LAST - l_sid_serial.FIRST + 1)||' sessions executing SQL_ID '||:sql_id);
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