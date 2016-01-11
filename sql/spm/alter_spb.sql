REM $Header: 215187.1 alter_spb.sql 11.4.5.8 2013/05/10 carlos.sierra $

ACC sql_text_piece PROMPT 'Enter SQL Text piece: '

SET PAGES 200 LONG 80000 ECHO ON;

COL sql_text PRI;

SELECT sql_handle, plan_name, sql_text /* exclude_me */
  FROM dba_sql_plan_baselines
 WHERE sql_text LIKE '%&&sql_text_piece.%'
   AND sql_text NOT LIKE '%/* exclude_me */%';

ACC sql_handle PROMPT 'Enter SQL Handle: ';

SPO &&sql_handle._spb.txt;

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

ACC attribute_name PROMPT 'Enter Attribute Name (ENABLED, FIXED, AUTOPURGE, PLAN_NAME or DESCRIPTION): ';

ACC attribute_value PROMPT 'Enter Attribute Value (for flags enter YES or NO): ';

VAR plans NUMBER;

BEGIN
  :plans := DBMS_SPM.alter_sql_plan_baseline (
    sql_handle      => '&&sql_handle.',
    plan_name       => '&&plan_name.',
    attribute_name  => '&&attribute_name.',
    attribute_value => '&&attribute_value.' );
END;
/

PRINT plans;

SELECT plan_name, /* exclude_me */
       enabled,
       accepted,
       fixed,
       reproduced,
       autopurge
  FROM dba_sql_plan_baselines
 WHERE sql_handle = '&&sql_handle.'
   AND plan_name = (CASE WHEN '&&attribute_name.' = 'PLAN_NAME' THEN '&&attribute_value.' ELSE NVL('&&plan_name.', plan_name) END)
 ORDER BY
       created;

SET PAGES 14 LONG 80 ECHO OFF;

UNDEF sql_text_piece sql_handle plan_name attribute_name attribute_value
