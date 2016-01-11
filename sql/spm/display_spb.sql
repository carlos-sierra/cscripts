REM $Header: 215187.1 display_spb.sql 11.4.5.8 2013/05/10 carlos.sierra $

ACC sql_text_piece PROMPT 'Enter SQL Text piece: '

SET PAGES 200 LONG 80000 ECHO ON;

COL sql_text PRI;

SELECT sql_handle, plan_name, sql_text /* exclude_me */
  FROM dba_sql_plan_baselines
 WHERE sql_text LIKE '%&&sql_text_piece.%'
   AND sql_text NOT LIKE '%/* exclude_me */%';

ACC sql_handle PROMPT 'Enter SQL Handle: ';

SELECT sql_handle, sql_text /* exclude_me */
  FROM dba_sql_plan_baselines
 WHERE sql_handle = '&&sql_handle.'
   AND ROWNUM = 1;

SELECT plan_name, created /* exclude_me */
  FROM dba_sql_plan_baselines
 WHERE sql_handle = '&&sql_handle.'
 ORDER BY
       created;

ACC plan_name PROMPT 'Enter optional Plan Name: ';

SPO &&sql_handle._&&plan_name._spb.txt;

SET NUM 20;

SELECT signature, /* exclude_me */
       plan_name,
       creator,
       origin,
       parsing_schema_name,
       description,
       version,
       created,
       last_modified,
       last_executed,
       last_verified,
       enabled,
       accepted,
       fixed,
       reproduced,
       autopurge,
       optimizer_cost,
       module,
       action,
       executions,
       elapsed_time,
       cpu_time,
       buffer_gets,
       disk_reads,
       direct_writes,
       rows_processed,
       fetches,
       end_of_fetch_count
  FROM dba_sql_plan_baselines
 WHERE sql_handle = '&&sql_handle.'
   AND plan_name = NVL('&&plan_name.', plan_name)
 ORDER BY
       created;

SELECT plan_name, /* exclude_me */
       enabled,
       accepted,
       fixed,
       reproduced,
       autopurge
  FROM dba_sql_plan_baselines
 WHERE sql_handle = '&&sql_handle.'
   AND plan_name = NVL('&&plan_name.', plan_name)
 ORDER BY
       created;

SET PAGES 2000 LIN 300 TRIMS ON ECHO ON FEED OFF HEA OFF;

SELECT * /* exclude_me */
FROM TABLE(DBMS_XPLAN.display_sql_plan_baseline('&&sql_handle.', '&&plan_name.', 'ADVANCED'));

SPO OFF;

SET NUM 10 PAGES 14 LONG 80 LIN 80 TRIMS OFF ECHO OFF FEED 6 HEA ON;

UNDEF sql_text_piece sql_handle plan_name
