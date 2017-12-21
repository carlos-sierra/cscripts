SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT OFF;

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

COL plan_name FOR A30;
COL created FOR A30;
COL last_executed FOR A30;
SELECT created, plan_name, origin, enabled, accepted, fixed, reproduced, last_executed, last_modified, description
FROM dba_sql_plan_baselines WHERE signature = :signature
ORDER BY created, plan_name;

SET HEA OFF PAGES 0
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE('&&sql_handle.'));
SET HEA ON PAGES 25

SELECT created, plan_name, origin, enabled, accepted, fixed, reproduced, last_executed, last_modified, description
FROM dba_sql_plan_baselines WHERE signature = :signature
ORDER BY created, plan_name;


