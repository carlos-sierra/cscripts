
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0;
SPO /tmp/cli_drop_all_zap_profiles.sql
SELECT 'ALTER SESSION SET CONTAINER = '||c.name||';'||CHR(10)||
       'EXEC DBMS_SQLTUNE.drop_sql_profile(name => '''||p.name||''');' AS line
  FROM cdb_sql_profiles p, v$containers c
 WHERE p.name LIKE 'zap%'
   AND c.con_id = p.con_id
ORDER BY c.name, p.name
/
SPO OFF;
@/tmp/cli_drop_all_zap_profiles.sql

