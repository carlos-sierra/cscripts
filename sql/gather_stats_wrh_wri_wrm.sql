SPO gather_stats.sql;
SELECT 'EXEC DBMS_STATS.GATHER_TABLE_STATS(''SYS'','''||table_name||''');'
  FROM dba_tables
 WHERE owner = 'SYS'
   AND SUBSTR(table_name, 1, 4) IN ('WRH$', 'WRI$', 'WRM$')
 ORDER BY
       table_name
/
SPO OFF;
SET ECHO ON;
@gather_stats.sql
