SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
DEF cs_file_name = '/tmp/iod_fleet_kiev_metadata';
HOS rm &&cs_file_name.
@@cs_internal/cs_pr_internal "WITH m AS (SELECT m.*, ROW_NUMBER() OVER (PARTITION BY m.jdbcurl ORDER BY m.version DESC) AS rn FROM c##iod.kiev_metadata m) SELECT * FROM m WHERE rn = 1 ORDER BY jdbcurl"
SPO OFF;
