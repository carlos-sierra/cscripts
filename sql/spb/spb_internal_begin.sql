-- spb_internal_begin.sql
-- validation and setup
-- this script is for internal use and only to be called from other scriprs

-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
-- exit graciously if executed from CDB$ROOT
WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN
    raise_application_error(-20000, 'Must execute from a PDB');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT OFF;
--
PRO
PRO 1. Enter SQL_ID (required)
DEF sql_id = '&1.';
PRO
--
VAR signature NUMBER;
VAR sql_text CLOB;
--
-- most times sql is in memory, so we get signature and sql_text from v$sql
BEGIN
  SELECT exact_matching_signature, sql_text INTO :signature, :sql_text FROM v$sql WHERE sql_id = '&&sql_id.' AND ROWNUM = 1;
END;
/
--
-- sometimes sql is not in memory but on awr, so we get sql_text from awr and we compute signature
BEGIN
  IF :signature IS NULL THEN
    SELECT sql_text INTO :sql_text FROM dba_hist_sqltext WHERE sql_id = '&&sql_id.' AND ROWNUM = 1;
    :signature := DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(:sql_text);
  END IF;
END;
/
--
COL signature NEW_V signature;
SELECT TO_CHAR(:signature) signature FROM DUAL;
--
COL sql_handle NEW_V sql_handle;
SELECT sql_handle FROM dba_sql_plan_baselines WHERE signature = :signature AND ROWNUM = 1;
--
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;
--
COL output_file_name NEW_V output_file_name NOPRI;
SELECT '&&spb_script._'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||LOWER(SYS_CONTEXT('USERENV','CON_NAME'))||'_&&sql_id._'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM v$database, v$instance;
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
--
SPO &&output_file_name..txt
PRO SQL> @spm/&&spb_script..sql &&sql_id.
PRO
PRO &&output_file_name..txt
PRO
PRO HOST      : &&x_host_name.
PRO DATABASE  : &&x_db_name.
PRO CONTAINER : &&x_container.
PRO SQL_ID    : &&sql_id.
PRO SQL_HANDLE: &&sql_handle.
PRO SIGNATURE : &&signature.
PRO
