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
  WHERE type = 'USER' AND wait_class = 'Scheduler' AND sid <> SYS_CONTEXT('USERENV', 'SID');
  --
  IF l_sid_serial.LAST >= l_sid_serial.FIRST THEN -- sessions found
    SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF3')||' cs_kill_scheduler: killing '||(l_sid_serial.LAST - l_sid_serial.FIRST + 1)||' sessions on Scheduler');
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