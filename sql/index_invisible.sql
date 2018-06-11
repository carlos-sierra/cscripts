DEF sleep_seconds = '60';
--
-- exit graciously if executed on standby
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
PRO
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
PRO
SET SERVEROUT ON;
PRO
ALTER SESSION SET CONTAINER = CDB$ROOT;
PRO
SPO make_index_invisible.sql
PRO
BEGIN
  FOR i IN (SELECT c.name pdb_name,
                   i.owner,
                   i.index_name
              FROM cdb_indexes i,
                   v$containers c
             WHERE i.index_name = 'KIEVTRANSACTIONS_AK2'
               AND i.visibility = 'VISIBLE'
               AND c.con_id = i.con_id
               AND c.open_mode = 'READ WRITE'
             ORDER BY
                   c.name,
                   i.owner)
  LOOP
    DBMS_OUTPUT.PUT_LINE('ALTER SESSION SET CONTAINER = '||i.pdb_name||';');
    DBMS_OUTPUT.PUT_LINE('ALTER INDEX '||i.owner||'.'||i.index_name||' INVISIBLE;');
    DBMS_OUTPUT.PUT_LINE('EXEC DBMS_LOCK.SLEEP(&&sleep_seconds.);');
  END LOOP;
END;
/
PRO
SPO OFF;
PRO
PRO Execute make_index_invisible.sql
PRO
SPO make_index_invisible.txt;
SET ECHO ON TIM ON TIMI ON;
@@make_index_invisible.sql
SPO OFF;
PRO
EXIT;
