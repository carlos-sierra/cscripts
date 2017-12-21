SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT OFF;

UNDEF sql_id child_number;
SELECT inst_id, child_number, plan_hash_value phv, executions execs, TO_CHAR(last_active_time, 'YYYY-MM-DD"T"HH24:MI:SS') last_active_time
FROM gv$sql WHERE SQL_ID = '&&sql_id.' ORDER BY inst_id, child_number
/
PRO &&child_number.
PRO
PRO FORMAT: 
PRO BASIC, TYPICAL, ALL, ALL ALLSTATS, ALL ALLSTATS LAST, 
PRO ADVANCED, ADVANCED ALLSTATS, ADVANCED ALLSTATS LAST (default)
SET LIN 300 PAGES 0;
SPO plan_&&sql_id._&&child_number..txt
SELECT plan.plan_table_output execution_plan 
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&&sql_id.', '&&child_number.', 
NVL('&format.', 'ADVANCED ALLSTATS LAST'))) plan
/
SPO OFF