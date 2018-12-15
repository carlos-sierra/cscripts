SET HEA OFF PAGES 0 TERM OFF;
SPO &&cs_file_dir.cursors_not_shared_dynamic.sql
SELECT CASE WHEN ROWNUM = 1 THEN '( ' ELSE ', ' END||column_name
  FROM dba_tab_columns
 WHERE owner = 'SYS'
   AND table_name = 'V_$SQL_SHARED_CURSOR'
   AND data_type = 'VARCHAR2'
   AND data_length = 1
/
SPO OFF;
GET &&cs_file_dir.cursors_not_shared_dynamic.sql
I )
I )
I WHERE value = 'Y'
I AND sql_id = '&&cs_sql_id.'
I GROUP BY reason_not_shared
I ORDER BY cursors_count DESC, reason_not_shared
0 ( value FOR reason_not_shared IN 
0 FROM v$sql_shared_cursor UNPIVOT
0 SELECT COUNT(*) cursors_count, reason_not_shared
L
!rm &&cs_file_dir.cursors_not_shared_dynamic.sql
SET HEA ON PAGES 100 TERM ON;
SPO &&cs_file_name..txt APP
PRO
PRO CURSORS NOT SHARED (v$sql_shared_cursor)
PRO ~~~~~~~~~~~~~~~~~~
/
