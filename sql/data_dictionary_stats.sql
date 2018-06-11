SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
COL table_name FOR A30;
COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'data_dictionary_stats_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||TO_CHAR(SYSDATE, 'yyyymmdd"T"hh24miss') output_file_name FROM v$database, v$instance;
--
SPO &&output_file_name..txt;
PRO
PRO SQL> @data_dictionary_stats.sql
PRO
PRO &&output_file_name..txt;
PRO
SELECT table_name, 
       TO_CHAR(last_analyzed, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed, 
       num_rows
  FROM dba_tab_statistics
 WHERE owner = 'SYS' 
   AND object_type <> 'FIXED TABLE'
 ORDER BY 
      last_analyzed ASC
/
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
SELECT TRUNC(last_analyzed) last_analyzed,
       COUNT(*) tables
  FROM dba_tab_statistics
 WHERE owner = 'SYS' 
   AND object_type <> 'FIXED TABLE'
 GROUP BY
       TRUNC(last_analyzed)
 ORDER BY
       TRUNC(last_analyzed)
/
PRO
PRO &&output_file_name..txt;
PRO
SPO OFF;
