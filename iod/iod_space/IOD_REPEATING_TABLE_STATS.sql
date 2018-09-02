-- IOD_REPEATING_TABLE_STATS
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
SET SERVEROUT ON;
DECLARE
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows  INTEGER;
  l_identifier_must_be_declared EXCEPTION;
  PRAGMA EXCEPTION_INIT(l_identifier_must_be_declared, -06550);
BEGIN
  l_statement := 'BEGIN DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO; END;';
  l_cursor_id := DBMS_SQL.OPEN_CURSOR;
  FOR i IN (SELECT name FROM v$containers WHERE open_mode = 'READ WRITE')
  LOOP
    BEGIN
      DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => i.name);
      l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    EXCEPTION
      WHEN l_identifier_must_be_declared THEN
        DBMS_OUTPUT.PUT_LINE(i.name||' '||SQLERRM);
    END;
  END LOOP;
  DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
END;
/
EXEC c##iod.iod_space.gather_table_stats;
--
