SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL current_resource_manager_plan FOR A128;
SELECT value current_resource_manager_plan FROM v$parameter WHERE name = 'resource_manager_plan';

COL start_time FOR A19;
COL end_time FOR A19;
COL enabled_by_scheduler FOR A10 HEA 'ENABLED|BY|SCHEDULER';
COL window_name FOR A20;
COL allowed_automated_switches FOR A10 HEA 'ALLOWED|AUTOMATED|SWITCHES';
COL cpu_managed FOR A10 HEA 'CPU|MANAGED';
COL instance_caging FOR A10 HEA 'INSTANCE|CAGING';
COL parallel_execution_managed FOR A10 HEA 'PARALLEL|EXECUTION|MANAGED';
COL con_id FOR 999999;

SELECT TO_CHAR(start_time, 'YYYY-MM-DD"T"HH24:MI:SS') start_time,
       TO_CHAR(end_time, 'YYYY-MM-DD"T"HH24:MI:SS') end_time,
       name plan,
       enabled_by_scheduler,
       window_name,
       allowed_automated_switches,
       cpu_managed,
       instance_caging,
       parallel_execution_managed,
       con_id
  FROM v$rsrc_plan_history
 ORDER BY
       start_time,
       end_time
/
