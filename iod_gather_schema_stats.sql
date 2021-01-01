SET HEA OFF PAGES 0;
SPO /tmp/temp_gather_schema_stats.sql
SELECT 'ALTER SESSION SET CONTAINER = '||name||';'||CHR(10)||'exec dbms_stats.gather_schema_stats(''KAASRWUSER'', no_invalidate => FALSE);' AS line
  FROM v$containers WHERE name LIKE 'KAAS_2021_PDB_19C_TESTING%' OR name LIKE 'KAAS_2019_PDB_12C_TESTING%' 
ORDER BY name
/
SPO OFF;
@/tmp/temp_gather_schema_stats.sql
QUIT
