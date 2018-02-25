SET HEA ON LIN 1000 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL name FOR A4;
COL value_string FOR A100;
SELECT TO_CHAR(last_captured, 'YYYY-MM-DD"T"HH24:MI:SS') last_captured,
       name,
       value_string
  FROM v$sql_bind_capture
 WHERE sql_id = '&sql_id.'
/
