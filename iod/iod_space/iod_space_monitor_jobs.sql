-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
--
-- execute connected into CDB$ROOT as SYS
ALTER SESSION SET container = CDB$ROOT;
COL action FOR A32;
PRO
PRO IOD sessions
PRO ~~~~~~~~~~~~
SELECT sid, serial#, module, action, last_call_et et_secs
  FROM v$session
 WHERE status = 'ACTIVE'
   AND type = 'USER'
   AND module LIKE '%IOD%'
 ORDER BY
       sid, serial#
/
