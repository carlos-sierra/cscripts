----------------------------------------------------------------------------------------
--
-- File name:   disable_sql_plan_baselines.sql
--
-- Purpose:     Disable SQL Plan Baseline for a given SQL Text string
--
-- Author:      Carlos Sierra
--
-- Version:     2017/12/15
--
-- Usage:       Execute connected into the PDB of interest.
--
--              Enter SQL Text string when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @disable_sql_plan_baselines.sql
-- 
--              pass string such as: /* perform%Scan%(deployments,%FROM %.deployments
--
-- Notes:       Acts on SQL Plan Baselines that are currently enabled
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT OFF;

PRO Enter SQL Text string (e.g. "/* perform%Scan%(deployments,%FROM %.deployments")
ACC sql_text_string PROMPT 'SQL Text string: ';
PRO Do you want to disable also "FIXED" SPBs?
ACC include_fixed_spbs PROMPT 'Include FIXED SPBs? ( N | Y ): '

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT REPLACE(SYS_CONTEXT('USERENV', 'CON_NAME'), '$') x_container FROM DUAL;

SPO disable_sql_plan_baselines_&&x_container._&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO SQL Text string: "&&sql_text_string."

COL sql_text_100 FOR A100;
COL sql_handle FOR A20;
COL signature FOR 99999999999999999999;
COL plan_name FOR A30;
COL created FOR A30;
COL last_executed FOR A30;
COL last_modified FOR A30;
COL description FOR A60;
BRE ON sql_handle SKIP PAGE ON signature;

SELECT sql_handle, signature, plan_name, 
       created, origin, enabled, accepted, fixed, reproduced, last_executed, last_modified, description,
       REPLACE(DBMS_LOB.SUBSTR(sql_text, 100), CHR(10), CHR(32)) sql_text_100
  FROM dba_sql_plan_baselines
 WHERE LOWER(DBMS_LOB.SUBSTR(sql_text, 4000)) LIKE LOWER('&&sql_text_string.%')
 ORDER BY
       signature,
       plan_name
/

SELECT plan_name, 
       created, origin, enabled, accepted, fixed, reproduced, last_executed, last_modified
  FROM dba_sql_plan_baselines
 WHERE LOWER(DBMS_LOB.SUBSTR(sql_text, 4000)) LIKE LOWER('&&sql_text_string.%')
 ORDER BY
       signature,
       plan_name
/

PRO Review list and hit "enter" (or "return") key to continue. Or enter <control>-C to cancel.
PAUSE

DECLARE
  l_plans INTEGER;
BEGIN
  FOR i IN (SELECT sql_handle, signature, plan_name 
              FROM dba_sql_plan_baselines 
             WHERE LOWER(DBMS_LOB.SUBSTR(sql_text, 4000)) LIKE LOWER('&&sql_text_string.%') 
               AND enabled = 'YES'
               AND CASE WHEN NVL(SUBSTR(UPPER(TRIM('&&include_fixed_spbs.')), 1, 1), 'N') = 'N' AND fixed = 'YES' THEN 0 ELSE 1 END = 1 
             ORDER BY signature, plan_name)
  LOOP
    l_plans := DBMS_SPM.ALTER_SQL_PLAN_BASELINE(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
  END LOOP;
END;
/

SELECT plan_name, 
       created, origin, enabled, accepted, fixed, reproduced, last_executed, last_modified
  FROM dba_sql_plan_baselines
 WHERE LOWER(DBMS_LOB.SUBSTR(sql_text, 4000)) LIKE LOWER('&&sql_text_string.%')
 ORDER BY
       signature,
       plan_name
/

SPO OFF;