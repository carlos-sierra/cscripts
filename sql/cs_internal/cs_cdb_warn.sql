-- warn if executed from CDB$ROOT
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN
    raise_application_error(-20000, '*** Be aware! You are executing this script connected into CDB$ROOT. ***');
  END IF;
END;
/
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN
    DBMS_LOCK.sleep(3);
  END IF;
END;
/ 
WHENEVER SQLERROR CONTINUE;
--