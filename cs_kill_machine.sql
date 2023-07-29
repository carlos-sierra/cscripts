----------------------------------------------------------------------------------------
--
-- File name:   cs_kill_machine.sql
--
-- Purpose:     Kill User Sessions connected from some Machine(s)
--
-- Author:      Carlos Sierra
--
-- Version:     2023/01/27
--
-- Usage:       Execute connected to CDB or PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_kill_machine.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL sessions FOR 999,990;
COL active FOR 999,990;
COL inactive FOR 999,990;
COL killed FOR 999,990;
--
SELECT COUNT(*) sessions, 
       SUM(CASE status WHEN 'ACTIVE' THEN 1 ELSE 0 END) active,
       SUM(CASE status WHEN 'INACTIVE' THEN 1 ELSE 0 END) inactive,
       SUM(CASE status WHEN 'KILLED' THEN 1 ELSE 0 END) killed,
       machine
  FROM v$session
 WHERE type = 'USER'
   AND sid <> SYS_CONTEXT('USERENV', 'SID')
 GROUP BY 
       machine
 ORDER BY
       machine
/
PRO
PRO 1. Enter MACHINE: (opt)
DEF machine = '&1.';
UNDEF 1;
PRO
PRO 2. Enter STATUS: [{INACTIVE}|ACTIVE|ALL]
DEF status = '&2.';
UNDEF 2;
COL status NEW_V status NOPRI;
SELECT CASE WHEN UPPER(TRIM('&&status.')) IN ('ALL', 'ACTIVE', 'INACTIVE') THEN  UPPER(TRIM('&&status.')) ELSE 'INACTIVE' END AS status FROM DUAL
/
PRO
PRO 3. Last Call Elapsed Time Seconds: [{3600}]
DEF last_call_et = '&3.';
UNDEF 3;
COL last_call_et_secs NEW_V last_call_et_secs NOPRI;
SELECT NVL('&&last_call_et.', '3600') AS last_call_et_secs FROM DUAL
/
--
VAR machine VARCHAR2(64);
EXEC :machine := '&&machine.';
VAR status VARCHAR2(8);
EXEC :status := '&&status.';
VAR last_call_et NUMBER;
EXEC :last_call_et := TO_NUMBER('&&last_call_et_secs.');
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
  WHERE type = 'USER' AND machine LIKE '%'||:machine||'%' AND :status IN ('ALL', status) AND last_call_et > :last_call_et AND sid <> SYS_CONTEXT('USERENV', 'SID');
  --
  IF l_sid_serial.LAST >= l_sid_serial.FIRST THEN -- sessions found
    SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF3')||' cs_kill_machine: killing '||(l_sid_serial.LAST - l_sid_serial.FIRST + 1)||' sessions from machine %'||:machine||'% with status '||:status);
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