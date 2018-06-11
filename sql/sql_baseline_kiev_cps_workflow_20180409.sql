----------------------------------------------------------------------------------------
--
-- File name:   sql_baseline_kiev_cps_workflow_20180409.sql
--
-- Purpose:     Disable SQL Plan Baselines on SQL matching some signature and metrics
--
-- Author:      Carlos Sierra
--
-- Version:     2018/04/09
--
-- Usage:       Execute connected into the CDB of interest.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sql_baseline_kiev_cps_workflow_20180409.sql
--
-- Notes:       Executes sql_baseline_kiev_cps_workflow_20180409.sql on each PDB 
--              driven by sql_baseline_kiev_cps_workflow_20180409_driver.sql
--
--              Only acts on SQL that matches:
--              1. Search String
--              2. Has an active SQL Plan Baseline
--              3. Takes more than 1s per Execution
--              4. Burns over 100K Buffer Gets per Execution
--
--              Use fs.sql script passing same search string to validate sql performance
--              before and after.
--             
---------------------------------------------------------------------------------------
--
SET HEA OFF FEED OFF ECHO OFF VER OFF;
SET LIN 300 SERVEROUT ON;
SET NUM 20;
--
DECLARE
  l_plans NUMBER;
BEGIN
  FOR i IN (SELECT exact_matching_signature signature,
                   sql_id, 
                   SUM(executions) executions, 
                   ROUND(SUM(elapsed_time)/1e6) elapsed_time,
                   ROUND(SUM(elapsed_time)/SUM(executions)/1e6,3) secs_per_exec,
                   SUM(buffer_gets) buffer_gets,
                   ROUND(SUM(buffer_gets)/SUM(executions)) bg_per_exec,
                   COUNT(DISTINCT sql_plan_baseline) baselines
                   --COUNT(DISTINCT sql_profile) profiles,
                   --COUNT(DISTINCT sql_patch) patches
              FROM v$sql
             WHERE UPPER(sql_text) LIKE UPPER('%&&search_string.%')
               AND UPPER(sql_text) NOT LIKE '%V$SQL%' -- filters out this query and similar ones
               AND executions > 0 -- avoid division by zero error on HAVING
               AND object_status = 'VALID'
               AND is_obsolete = 'N'
               AND is_shareable = 'Y'
               AND parsing_user_id > 0 -- exclude sys
               AND parsing_schema_id > 0 -- exclude sys
               AND sql_text NOT LIKE '%RESULT_CACHE%'
               AND sql_text NOT LIKE '%EXCLUDE_ME%'
               AND con_id > 2 -- exclue CDB$ROOT
             GROUP BY
                   exact_matching_signature, 
                   sql_id
            HAVING COUNT(DISTINCT sql_plan_baseline) > 0
               AND ROUND(SUM(elapsed_time)/SUM(executions)/1e6,3) > 1
               AND ROUND(SUM(buffer_gets)/SUM(executions)) > 1e5
             ORDER BY
                   exact_matching_signature,
                   sql_id)
  LOOP
    DBMS_OUTPUT.PUT_LINE('sign:'||i.signature||' sql_id:'||i.sql_id||' ex:'||i.executions||' et:'||i.elapsed_time||'s perf:'||i.secs_per_exec||'s bg:'||i.buffer_gets||' bge:'||i.bg_per_exec||' bl:'||i.baselines);
    IF '&&report_only.' = 'N' THEN
      FOR j IN (SELECT plan_name FROM dba_sql_plan_baselines WHERE signature = i.signature AND enabled = 'YES' AND accepted = 'YES')
      LOOP
        DBMS_OUTPUT.PUT_LINE('disabling: '||j.plan_name);
        l_plans :=
        DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
          plan_name         => j.plan_name,
          attribute_name    => 'ENABLED',
          attribute_value   => 'NO'
        );
      END LOOP;
    END IF;
  END LOOP;
END;
/
--



