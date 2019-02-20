-- warn if executed on standby
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, '*** Be aware! You are executing this script on STANDBY ***');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
