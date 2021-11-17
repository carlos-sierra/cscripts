SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
SET HEA OFF PAGES 0;
COL line FOR A300;
SPO /tmp/cli_disabled_exp_profiles_IMPLEMENT.sql;
SELECT 'ALTER SESSION SET CONTAINER = '||c.name||';'||CHR(10)||'EXEC DBMS_SQLTUNE.ALTER_SQL_PROFILE('''||p.name||''', ''STATUS'', ''ENABLED'');' AS line
FROM cdb_sql_profiles p, v$containers c WHERE p.description LIKE '%[EXP]%' AND p.status = 'DISABLED' AND c.con_id = p.con_id;
SPO OFF;
@/tmp/cli_disabled_exp_profiles_IMPLEMENT.sql