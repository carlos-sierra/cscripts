----------------------------------------------------------------------------------------
--
-- File name:   drop_sql_plan_baselines_by_sql_text.sql
--
-- Purpose:     Drop SQL Plan Baseline for a given string matching SQL Text or
--              SPB description, such as <string>%
--
-- Author:      Carlos Sierra
--
-- Version:     2018/01/02
--
-- Usage:       Execute connected into the PDB of interest.
--
--              Enter SQL Text string when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @drop_sql_plan_baselines_by_sql_text.sql
-- 
--              pass string such as: 
--                /* perform%Scan%(deployments,%FROM %.deployments
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT OFF;

PRO Enter Text string (e.g. "/* perform%Scan%(deployments,%FROM %.deployments")
ACC text_string PROMPT 'Text string: ';

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT REPLACE(SYS_CONTEXT('USERENV', 'CON_NAME'), '$') x_container FROM DUAL;

SPO drop_sql_plan_baselines_by_sql_text_&&x_container._&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO SQL Text string: "&&text_string."

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
 WHERE LOWER(DBMS_LOB.SUBSTR(sql_text, 4000)) LIKE LOWER('&&text_string.%')
    OR LOWER(description) LIKE LOWER('&&text_string.%')
 ORDER BY
       signature,
       plan_name
/

SELECT plan_name, 
       created, origin, enabled, accepted, fixed, reproduced, last_executed, last_modified
  FROM dba_sql_plan_baselines
 WHERE LOWER(DBMS_LOB.SUBSTR(sql_text, 4000)) LIKE LOWER('&&text_string.%')
    OR LOWER(description) LIKE LOWER('&&text_string.%')
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
             WHERE (LOWER(DBMS_LOB.SUBSTR(sql_text, 4000)) LIKE LOWER('&&text_string.%') OR LOWER(description) LIKE LOWER('&&text_string.%'))
               AND enabled = 'YES'
             ORDER BY signature, plan_name)
  LOOP
    l_plans := DBMS_SPM.DROP_SQL_PLAN_BASELINE(sql_handle => i.sql_handle, plan_name => i.plan_name);
  END LOOP;
END;
/

SELECT plan_name, 
       created, origin, enabled, accepted, fixed, reproduced, last_executed, last_modified
  FROM dba_sql_plan_baselines
 WHERE LOWER(DBMS_LOB.SUBSTR(sql_text, 4000)) LIKE LOWER('&&text_string.%')
    OR LOWER(description) LIKE LOWER('&&text_string.%')
 ORDER BY
       signature,
       plan_name
/

SPO OFF;