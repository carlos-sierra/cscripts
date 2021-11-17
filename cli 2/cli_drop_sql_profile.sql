SET HEA OFF PAGES 0;
ALTER SESSION SET CONTAINER = CDB$ROOT;
SPO /tmp/drop_sql_profiles.sql
SELECT DISTINCT 
       'ALTER SESSION SET CONTAINER = '||c.name||';'||CHR(10)||
       'EXEC DBMS_SQLTUNE.drop_sql_profile(name => '''||s.sql_profile||''');' AS line 
  FROM v$sql s, v$containers c
 WHERE UPPER(s.sql_text) LIKE UPPER('%&&sql_decoration.%')
   AND s.sql_profile IS NOT NULL
   AND c.con_id = s.con_id
/
SPO OFF;
@/tmp/drop_sql_profiles.sql
ALTER SESSION SET CONTAINER = CDB$ROOT;
SET HEA ON PAGES 24;