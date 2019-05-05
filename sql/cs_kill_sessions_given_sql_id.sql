-- see also cancel_sql.sql
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
--
COL host_name NEW_V host_name;
SELECT host_name FROM v$instance;
--
PRO 1. Enter SQL_ID:
DEF sql_id = '&1.';
PRO
COL db_secs FOR 999,999,990.000;
COL secs_per_exec FOR 999,999,990.000;
SELECT SUM(sq.elapsed_time)/1e6 db_secs,
       SUM(sq.executions) executions,
       SUM(sq.elapsed_time)/1e6/GREATEST(SUM(sq.executions), 1) secs_per_exec,
       sq.plan_hash_value,
       TO_CHAR(MAX(sq.last_active_time), 'YYYY-MM-DD"T"HH24:MI:SS') last_active_time
  FROM v$sql sq
 WHERE sq.sql_id = '&&sql_id.'
 GROUP BY
       sq.plan_hash_value
 ORDER BY
       SUM(sq.elapsed_time) DESC
/
PRO
PRO 2. Enter Plan Hash Value (opt):
DEF plan_hash_value = '&2.';
SET HEA OFF PAGES 0 FEED OFF VER OFF ECHO OFF;
SPO kill_sessions_driver.sql;
SELECT 'ALTER SYSTEM DISCONNECT SESSION '''||e.sid||','||e.serial#||''' IMMEDIATE;' 
  FROM v$session e, v$sql s
 WHERE e.sql_id = '&&sql_id.' 
   AND s.con_id = e.con_id
   AND s.sql_id = e.sql_id
   AND s.child_number = e.sql_child_number
   AND s.plan_hash_value = NVL(TO_NUMBER('&&plan_hash_value.'), s.plan_hash_value)
   AND e.type = 'USER'
   AND e.sid <> USERENV('SID')
   AND e.machine <> '&&host_name.'
/
SPO OFF;
PRO
PRO Execute: kill_sessions_driver.sql to kill sessions executing &&sql_id. &&plan_hash_value.
SET HEA ON LIN 80 PAGES 24;
