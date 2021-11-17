SET SERVEROUT ON;
DECLARE
  l_time_begin NUMBER;
  l_process_time NUMBER := 0;
  l_process_time_total NUMBER := 0;
  l_cursor INTEGER;
  l_return INTEGER;
  l_dummy VARCHAR2(1);
  l_logon_count INTEGER := 0;
BEGIN
  FOR i IN 1 .. 100
  LOOP
    FOR j IN (SELECT name AS pdb_name FROM v$containers WHERE con_id > 2 ORDER BY name)
    LOOP
        l_time_begin := DBMS_UTILITY.get_time;
        l_cursor := DBMS_SQL.open_cursor;
        DBMS_SQL.parse(c => l_cursor, statement => 'SELECT dummy FROM DUAL', language_flag => DBMS_SQL.native, container => j.pdb_name);
        DBMS_SQL.define_column_char(c => l_cursor, position => 1, column => l_dummy, column_size => 1);
        l_return := DBMS_SQL.execute(c => l_cursor);
        LOOP
        IF DBMS_SQL.fetch_rows(c => l_cursor) > 0 THEN
            DBMS_SQL.column_value_char(c => l_cursor, position => 1, value => l_dummy);
        ELSE
            EXIT;
        END IF;
        END LOOP;
        DBMS_SQL.close_cursor(c => l_cursor);
        l_process_time := DBMS_UTILITY.get_time - l_time_begin;
        l_process_time_total := l_process_time_total + l_process_time;
        l_logon_count := l_logon_count + 1;
    END LOOP;
  END LOOP;
  DBMS_OUTPUT.put_line(ROUND((l_process_time_total / l_logon_count * 10), 1)||' ms on avg, over '||l_logon_count||' logons');
END;
/
