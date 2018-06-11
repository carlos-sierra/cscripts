-- IOD_SPACE_KILL_JOBS (IOD_IMMEDIATE_SPACE_KILL_JOBS)
-- Graciously kill SPACE_MAINTENANCE OEM jobs
--
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
WHENEVER SQLERROR EXIT FAILURE;
--
-- exit graciously if package does not exist
WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  DBMS_OUTPUT.PUT_LINE('API version: '||c##iod.iod_space.gk_package_version);
END;
/
WHENEVER SQLERROR EXIT FAILURE;
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET HEA OFF;
--
VAR v_cursor CLOB;
--
-- PL/SQL block to be executed on each PDB
BEGIN
  :v_cursor := q'[
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
  l_lock_request_return INTEGER;
BEGIN
  l_lock_request_return := DBMS_LOCK.REQUEST(id=>666,lockmode=>DBMS_LOCK.X_MODE,timeout=>1,release_on_commit=>FALSE);
  COMMIT;
END;
]';
END;
/
--
-- execute connected into CDB$ROOT as SYS
ALTER SESSION SET container = CDB$ROOT;
DECLARE
  l_cursor_id INTEGER;
  l_rows_processed INTEGER;
  l_open_mode VARCHAR2(20);
  l_pdb_count INTEGER := 0;
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode = 'READ WRITE' THEN
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    FOR i IN (SELECT c.con_id, c.name con_name
                FROM v$containers c
               WHERE c.open_mode = 'READ WRITE'
               ORDER BY
                     c.con_id)
    LOOP
      DBMS_OUTPUT.PUT_LINE('DBMS_LOCK.REQUEST for '||i.con_name);
      DBMS_SQL.PARSE(c => l_cursor_id, statement => :v_cursor, language_flag => DBMS_SQL.NATIVE, container => i.con_name);
      l_rows_processed := DBMS_SQL.EXECUTE(c => l_cursor_id);
      l_pdb_count := l_pdb_count + 1;
    END LOOP;
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    DBMS_OUTPUT.PUT_LINE(l_pdb_count||' PDBs were requested to be locked');
    DBMS_OUTPUT.PUT_LINE('IOD_REPETITIVE_SPACE_MAINTENANCE jobs will be interrupted.');
  END IF;
END;
/
--
PRO
PRO IOD sessions
PRO ~~~~~~~~~~~~
SELECT sid, serial#, module, action, last_call_et et_secs
  FROM v$session
 WHERE status = 'ACTIVE'
   AND type = 'USER'
   AND module LIKE CHR(37)||'IOD'||CHR(37)
 ORDER BY
       sid, serial#
/
--
PRO
PRO Sleep for 1hr then release lock by closing own session at the end of this job
PRO During the next 1hr, any IOD_REPETITIVE_SPACE_MAINTENANCE will be graciously killed
PRO
--
EXEC DBMS_LOCK.SLEEP(3600);
--
PRO bye!