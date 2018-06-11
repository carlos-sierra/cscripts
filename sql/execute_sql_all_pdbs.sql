SET SERVEROUT ON
DECLARE
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows  INTEGER;
  l_identifier_must_be_declared EXCEPTION;
  PRAGMA EXCEPTION_INIT(l_identifier_must_be_declared, -06550);
BEGIN
  l_statement := q'[SELECT COUNT(*) FROM SYS.SCHEDULER$_CLASS]';
  l_cursor_id := DBMS_SQL.OPEN_CURSOR;
  FOR i IN (SELECT name FROM v$containers WHERE open_mode = 'READ WRITE')
  LOOP
    BEGIN
      DBMS_OUTPUT.PUT_LINE(i.name);
      DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => i.name);
      l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    EXCEPTION
      WHEN l_identifier_must_be_declared THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END;
  END LOOP;
  DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
END;
/
