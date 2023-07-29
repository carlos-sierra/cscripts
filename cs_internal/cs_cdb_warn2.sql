-- warn if executed from CDB$ROOT
SET SERVEROUT ON;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN
    DBMS_OUTPUT.put_line(CHR(10));
    DBMS_OUTPUT.put_line('***');
    DBMS_OUTPUT.put_line('*** On CDB$ROOT ***');
    DBMS_OUTPUT.put_line('***');
    DBMS_OUTPUT.put_line('*** This script is expeted to execute from a PDB ***');
    DBMS_OUTPUT.put_line('***');
    DBMS_OUTPUT.put_line(CHR(10));
  END IF;
END;
/
SET SERVEROUT OFF;
BEGIN
 IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN
   DBMS_LOCK.sleep(1);
 END IF;
END;
/
