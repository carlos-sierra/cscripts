-- warn if not executed from CDB$ROOT
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') <> 'CDB$ROOT' THEN
    raise_application_error(-20000, '*** Be aware! You are executing this script connected into '||SYS_CONTEXT('USERENV', 'CON_NAME')||' ***');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--