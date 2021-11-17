SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL log_time FOR A27 TRUNC;
COL parsing_schema_name FOR A20 TRUNC;
SELECT log_time, parsing_schema_name, plan_hash_value, plans_create, /*plans_disable,*/ plans_drop
FROM c##iod.zapper_log
WHERE sql_id = '3hahc9c3zmc6d'
AND pdb_name = 'VCN_V2'
AND plans_create + plans_disable + plans_drop > 0
ORDER BY log_time
/