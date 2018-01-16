-- sql_shared_cursor.sql
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET PAGES 0;
SPO all_reasons.sql
SELECT CASE WHEN ROWNUM = 1 THEN '( ' ELSE ', ' END||column_name
  FROM dba_tab_columns
 WHERE table_name = 'V_$SQL_SHARED_CURSOR'
   AND owner = 'SYS'
   AND data_type = 'VARCHAR2'
   AND data_length = 1
/
SPO OFF;
GET all_reasons.sql
I )
I )
I WHERE value = 'Y'
I AND sql_id = NVL('&sql_id.', sql_id)
I GROUP BY reason_not_shared
I ORDER BY cursors DESC, sql_ids DESC, reason_not_shared
0 ( value FOR reason_not_shared IN 
0 FROM v$sql_shared_cursor UNPIVOT
0 SELECT COUNT(*) cursors, COUNT(DISTINCT sql_id) sql_ids, reason_not_shared
L
SET HEA ON NEWP 1 PAGES 30
PRO please wait
/
!rm all_reasons.sql
