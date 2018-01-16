SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET LIN 32767 PAGES 0 LONG 32767000 LONGC 32767;
PRO
PRO Date Range (format YYYY-MM-DD"T"HH24:MI:SS). Default to last 24 hours.
ACC date_from PROMPT 'Since (i.e. 2017-12-23T06:28:10) (opt): ';
ACC date_to PROMPT 'Until (i.e. 2017-12-23T06:28:10) (opt): ';
PRO
PRO Format: XML | TEXT | HTML (default)
ACC p_format PROMPT 'Format (opt): ';
PRO
PRO Detail Level: TYPICAL | ALL | BASIC (default)
ACC p_detail_level PROMPT 'Detail Level (opt): ';

COL p_since NEW_V p_since NOPRI;
COL p_until NEW_V p_until NOPRI;
SELECT NVL('&&date_from.', TO_CHAR(SYSDATE-1,'YYYY-MM-DD"T"HH24:MI:SS')) p_since, NVL('&&date_to.', TO_CHAR(SYSDATE,'YYYY-MM-DD"T"HH24:MI:SS')) p_until FROM DUAL;
COL file_suffix NEW_V file_suffix NOPRI;
SELECT CASE UPPER(TRIM('&&p_format.')) WHEN 'TEXT' THEN 'txt' WHEN 'XML' THEN 'xml' ELSE 'html' END file_suffix FROM DUAL;
COL current_time NEW_V current_time FOR A15 NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;

SPO dbms_stats_report_&&current_time..&&file_suffix.;
SELECT DBMS_STATS.REPORT_STATS_OPERATIONS(detail_level => NVL('&&p_detail_level.', 'BASIC'), format => NVL('&&p_format.', 'HTML'), since => TO_TIMESTAMP('&&p_since.', 'YYYY-MM-DD"T"HH24:MI:SS'), until => TO_TIMESTAMP('&&p_until.', 'YYYY-MM-DD"T"HH24:MI:SS')) FROM DUAL
/
SPO OFF;

SET LIN 500 PAGES 100;
