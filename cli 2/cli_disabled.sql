SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
--
COL pdb_name FOR A30;
COL cnt FOR 990;
COL sql_text FOR A80 TRUNC;
COL action_reason FOR A15 TRUNC;
--
SELECT pdb_name, sql_id, SUBSTR(action_reason_desc, 1, 15) AS action_reason, COUNT(*) AS cnt,
       (SELECT sql_text FROM v$sqlstats s WHERE s.sql_id = l.sql_id AND ROWNUM = 1) AS sql_text
  FROM C##IOD.zapper_log_v l
 WHERE plans_create = 0
   AND plans_disable > 0
   AND log_time > SYSDATE - 5
 GROUP BY pdb_name, sql_id, SUBSTR(action_reason_desc, 1, 15)
 ORDER BY pdb_name, sql_id, SUBSTR(action_reason_desc, 1, 15)
 /