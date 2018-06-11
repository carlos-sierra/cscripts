----------------------------------------------------------------------------------------
--
-- File name:   drop_sql_plan_baselines_by_sql_id.sql
--
-- Purpose:     Drop SQL Plan Baseline for a given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2018/01/31
--
-- Usage:       Execute connected into the PDB of interest.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @drop_sql_plan_baselines_by_sql_id.sql
-- 
--              pass string such as: 
--                d0r59da3g1mbj
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT OFF;
SET NUM 20;

ACC sql_id PROMPT 'SQL_ID: ';

VAR signature NUMBER;
VAR sql_text CLOB;

BEGIN
  SELECT exact_matching_signature, sql_text INTO :signature, :sql_text FROM gv$sql WHERE sql_id = '&&sql_id.' AND ROWNUM = 1;
END;
/

BEGIN
  IF :signature IS NULL THEN
    SELECT sql_text INTO :sql_text FROM dba_hist_sqltext WHERE sql_id = '&&sql_id.' AND ROWNUM = 1;
    :signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:sql_text);
  END IF;
END;
/

COL sql_handle NEW_V sql_handle;
SELECT sql_handle FROM dba_sql_plan_baselines WHERE signature = :signature AND ROWNUM = 1;

COL signature NEW_V signature;
SELECT :signature signature FROM DUAL;

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT REPLACE(SYS_CONTEXT('USERENV', 'CON_NAME'), '$') x_container FROM DUAL;

SPO drop_sql_plan_baselines_by_sql_id_&&sql_id._&&x_container._&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO SQL_ID: "&&sql_id."

COL sql_text_100 FOR A100;
COL sql_handle FOR A20;
COL signature FOR 99999999999999999999;
COL plan_name FOR A30;
COL created FOR A30;
COL last_executed FOR A30;
COL last_modified FOR A30;
COL description FOR A100;
BRE ON sql_handle SKIP PAGE ON signature;


SELECT sql_handle, signature, plan_name, 
       created, origin, enabled, accepted, fixed, reproduced, adaptive, last_executed, last_modified, description,
       REPLACE(DBMS_LOB.SUBSTR(sql_text, 100), CHR(10), CHR(32)) sql_text_100
  FROM dba_sql_plan_baselines
 WHERE signature = &&signature.
 ORDER BY
       signature,
       plan_name
/

SELECT plan_name, 
       created, origin, enabled, accepted, fixed, reproduced, adaptive, last_executed, last_modified
  FROM dba_sql_plan_baselines
 WHERE signature = &&signature.
 ORDER BY
       signature,
       plan_name
/

ACC plan_name PROMPT 'Enter optional Plan Name: ';

DECLARE
  l_plans INTEGER;
BEGIN
  FOR i IN (SELECT sql_handle, signature, plan_name 
              FROM dba_sql_plan_baselines 
             WHERE signature = &&signature.
               AND enabled = 'YES'
               AND plan_name = NVL('&&plan_name.', plan_name)
             ORDER BY signature, plan_name)
  LOOP
    l_plans := DBMS_SPM.DROP_SQL_PLAN_BASELINE(sql_handle => i.sql_handle, plan_name => i.plan_name);
  END LOOP;
END;
/

SELECT plan_name, 
       created, origin, enabled, accepted, fixed, reproduced, adaptive, last_executed, last_modified
  FROM dba_sql_plan_baselines
 WHERE signature = &&signature.
 ORDER BY
       signature,
       plan_name
/

SPO OFF;