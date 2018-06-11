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

COL plan_name FOR A30;
COL created FOR A30;
COL last_executed FOR A30;
COL last_modified FOR A30;
COL description FOR A100;

COL dbid NEW_V dbid;
COL db_name NEW_V db_name;
SELECT dbid, LOWER(name) db_name FROM v$database
/

COL instance_number NEW_V instance_number;
COL host_name NEW_V host_name;
SELECT instance_number, LOWER(host_name) host_name FROM v$instance
/

COL con_name NEW_V con_name;
SELECT 'NONE' con_name FROM DUAL;
SELECT LOWER(SYS_CONTEXT('USERENV', 'CON_NAME')) con_name FROM DUAL
/

COL locale NEW_V locale;
SELECT LOWER(REPLACE(SUBSTR('&&host_name.', 1 + INSTR('&&host_name.', '.', 1, 2), 30), '.', '_')) locale FROM DUAL
/

COL output_file_name NEW_V output_file_name;
SELECT 'display_sql_plan_baseline_by_sql_id_&&locale._&&db_name._'||REPLACE('&&con_name.','$')||'_'||TO_CHAR(SYSDATE, 'YYYYMMDD"T"HH24MMSS') output_file_name FROM DUAL
/

SPO &&output_file_name..txt;
PRO
PRO &&output_file_name..txt
PRO
PRO LOCALE   : &&locale.
PRO DATABASE : &&db_name.
PRO CONTAINER: &&con_name.
PRO HOST     : &&host_name.


SELECT created, plan_name, origin, enabled, accepted, fixed, reproduced, adaptive, last_executed, last_modified, description
FROM dba_sql_plan_baselines WHERE signature = :signature
ORDER BY created, plan_name;

SET HEA OFF PAGES 0
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE('&&sql_handle.', NULL, 'ADVANCED'));
SET HEA ON PAGES 25

SELECT created, plan_name, origin, enabled, accepted, fixed, reproduced, adaptive, last_executed, last_modified, description
FROM dba_sql_plan_baselines WHERE signature = :signature
ORDER BY created, plan_name;

PRO
PRO &&output_file_name..txt

SPO OFF;
CL COL;

