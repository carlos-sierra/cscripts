----------------------------------------------------------------------------------------
--
-- File name:   OEM IOD_IMMEDIATE_SPACE_KILL_JOBS
--
-- Purpose:     Graciously kill SPACE_MAINTENANCE OEM jobs
--
-- Frequency:   Immediate
--
-- Author:      Carlos Sierra
--
-- Version:     2019/02/04
--
-- Usage:       Execute connected into CDB 
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @IOD_IMMEDIATE_SPACE_KILL_JOBS.sql
--
-- Notes:       Collected data is used by cs_sgstat* and cs_shared_pool* scripts to
--              report and chart SGA and Shared Pool sizes over time.
--
---------------------------------------------------------------------------------------
--
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Not PRIMARY');
  END IF;
END;
/
-- exit graciously if executed on excluded host
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_host_name VARCHAR2(64);
BEGIN
  SELECT host_name INTO l_host_name FROM v$instance;
  IF LOWER(l_host_name) LIKE CHR(37)||'casper'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'control-plane'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'omr'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'oem'||CHR(37) OR 
     LOWER(l_host_name) LIKE CHR(37)||'telemetry'||CHR(37)
  THEN
    raise_application_error(-20000, '*** Excluded host: "'||l_host_name||'" ***');
  END IF;
END;
/
-- exit graciously if executed on unapproved database
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_db_name VARCHAR2(9);
BEGIN
  SELECT name INTO l_db_name FROM v$database;
  IF UPPER(l_db_name) LIKE 'DBE'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'DBTEST'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'IOD'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'KIEV'||CHR(37) OR 
     UPPER(l_db_name) LIKE 'LCS'||CHR(37)
  THEN
    NULL;
  ELSE
    raise_application_error(-20000, '*** Unapproved database: "'||l_db_name||'" ***');
  END IF;
END;
/
-- exit graciously if executed on a PDB
WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') <> 'CDB$ROOT' THEN
    raise_application_error(-20000, '*** Within PDB "'||SYS_CONTEXT('USERENV', 'CON_NAME')||'" ***');
  END IF;
END;
/
-- exit not graciously if any error
WHENEVER SQLERROR EXIT FAILURE;
--
-- PL/SQL block to be executed on each PDB
VAR v_cursor CLOB;
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
--
---------------------------------------------------------------------------------------