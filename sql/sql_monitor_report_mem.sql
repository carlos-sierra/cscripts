SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET LIN 32767 PAGES 0 LONG 32767000 LONGC 32767;

ACC sql_id PROMPT 'SQL_ID (req): ';
PRO SQL Execution ID (from sql_execution_outliers_mem)
ACC sql_exec_id PROMPT 'SQL_EXEC_ID (opt): ';
PRO Report Type: XML | TEXT | HTML | ACTIVE (default)
ACC report_type PROMPT 'Report Type (opt): ';

COL file_suffix NEW_V file_suffix NOPRI;
SELECT CASE UPPER(TRIM('&&report_type.')) WHEN 'TEXT' THEN 'txt' WHEN 'XML' THEN 'xml' ELSE 'html' END file_suffix FROM DUAL;

SPO sql_monitor_report_&&report_type._mem_&&sql_id._&&sql_exec_id..&&file_suffix.;
SELECT DBMS_SQL_MONITOR.REPORT_SQL_MONITOR(sql_id => '&&sql_id.', sql_exec_id => TO_NUMBER('&&sql_exec_id.'), type => NVL('&&report_type.', 'ACTIVE')) FROM DUAL
/
SPO OFF;

SET LIN 500 PAGES 100;
