DEF timestamp_as_hexdump = '&1.';
--
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF6';
--
COL time FOR A20;
COL timestamp FOR A30;
--
WITH
FUNCTION get_date (p_hexdump IN VARCHAR2) 
RETURN DATE
IS
  l_date DATE;
BEGIN
  DBMS_STATS.convert_raw_value(rawval => HEXTORAW(p_hexdump), resval => l_date);
  RETURN l_date;
END get_date;
FUNCTION get_timestamp (p_hexdump IN VARCHAR2) 
RETURN TIMESTAMP
IS
BEGIN
  RETURN
  TO_TIMESTAMP(
  TO_CHAR(get_date(p_hexdump), 'YYYY-MM-DD"T"HH24:MI:SS')||
  ROUND(TO_NUMBER(SUBSTR('&&timestamp_as_hexdump.', LENGTH('&&timestamp_as_hexdump.') - 7), 'XXXXXXXX')/POWER(10,9), 6),
  'YYYY-MM-DD"T"HH24:MI:SS.FF6');
END get_timestamp;
SELECT get_date('&&timestamp_as_hexdump.') AS time, get_timestamp('&&timestamp_as_hexdump.') AS timestamp FROM DUAL
/
--