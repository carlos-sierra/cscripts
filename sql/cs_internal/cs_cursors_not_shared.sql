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
I GROUP BY reason_not_shared, con_id )
I SELECT s.con_id, c.name AS pdb_name, s.cursors_count, s.reason_not_shared 
I FROM s, v$containers c
I WHERE c.con_id = s.con_id
I ORDER BY s.con_id, s.cursors_count DESC, s.reason_not_shared
0 ( value FOR reason_not_shared IN 
0 FROM v$sql_shared_cursor UNPIVOT
0 SELECT COUNT(*) AS cursors_count, reason_not_shared, con_id
0 WITH s AS (
L
!rm &&cs_file_dir.cursors_not_shared_dynamic.sql
SET HEA ON PAGES 100 TERM ON;
COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL cursors_count FOR 999,990 HEA 'Cursors';
COL reason_not_shared FOR A30 HEA 'Reason not Shared';
SPO &&cs_file_name..txt APP
PRO
PRO CURSORS NOT SHARED (v$sql_shared_cursor)
PRO ~~~~~~~~~~~~~~~~~~
/
