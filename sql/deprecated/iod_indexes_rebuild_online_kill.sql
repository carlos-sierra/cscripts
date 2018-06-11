----------------------------------------------------------------------------------------
--
-- File name:   iod_indexes_rebuild_online_kill.sql
--
-- Purpose:     Kill execution of iod_indexes_rebuild_online.sql
--
-- Author:      Carlos Sierra
--
-- Version:     2017/10/01
--
-- Usage:       Execute on CDB$ROOT. OEM ready.
--
-- Example:     @iod_indexes_rebuild_online_kill.sql
--
---------------------------------------------------------------------------------------
SET SERVEROUT ON ECHO OFF FEED OFF VER OFF TAB OFF LINES 300 TRIMS ON TRIM ON TI OFF TIMI OFF;

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

PRO
PAU Press "return" to lock PDBs and terminate IOD job.

VAR v_cursor CLOB;

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

-- execute connected into CDB$ROOT as SYS
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
               WHERE c.con_id > -1 -- all containers 
                 AND c.open_mode = 'READ WRITE'
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
    DBMS_OUTPUT.PUT_LINE('IOD script will be interrupted.');
  END IF;
END;
/

PRO
PAU Press "return" to list PDBs locked.

PRO
PRO PDBs locked
PRO ~~~~~~~~~~~
BREAK ON sid SKIP 1;
SELECT l.sid,
       l.con_id,
       p.name pdb_locked
  FROM v$lock l,
       v$pdbs p
 WHERE l.type = 'UL'
   AND l.id1 = 666
   AND l.lmode = 6
   AND p.con_id = l.con_id
 ORDER BY
       1,2
/

PRO
PAU Press "return" to query IOD session.

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

PRO
PRO Keep executing this last query until IOD session(s) terminates.
PRO
