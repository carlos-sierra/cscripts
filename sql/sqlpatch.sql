----------------------------------------------------------------------------------------
--
-- File name:   sqlpatch.sql
--
-- Purpose:     Create Diagnostics SQL Patch for one SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2017/07/28
--
-- Usage:       This script inputs two parameters: SQL_ID and HINTS_TEXT
--
-- Example:     @sqlpatch.sql f995z9antmhxn "MONITOR BIND_AWARE GATHER_PLAN_STATISTICS"
--              @sqlpatch.sql 1xt0ygwgrgdpb "OPT_PARAM('_fix_control','13430622:OFF')"
--
--  Notes:      Developed and tested on 12.1.0.2
--              valid hint parameter: "OPT_PARAM('_fix_control', '13430622:OFF')"
--             
---------------------------------------------------------------------------------------
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
SET SERVEROUT ON;
--
COL hints_text NEW_V hints_text FOR A300;
PRO
PRO 1. SQL_ID (required)
DEF sql_id = '&1';
PRO
PRO 2. HINTS_TEXT (required) e.g.: FIRST_ROWS(1)
DEF hints_text = "&2.";
--
COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'sqlpatch_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||LOWER(SYS_CONTEXT('USERENV','CON_NAME'))||'_&&sql_id._'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM v$database, v$instance;
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
SPO &&output_file_name..txt
PRO
PRO SQL> @sqlpatch.sql &&sql_id. "&&hints_text."
PRO
PRO &&output_file_name..txt
PRO
PRO SQL_ID   : &&sql_id.
PRO SIGNATURE: &&signature.
PRO HINT_TEXT: "&&hints_text."
PRO
PRO Creating SQL Patch
PRO ~~~~~~~~~~~~~~~~~~
BEGIN
  FOR i IN (SELECT name FROM dba_sql_patches WHERE signature = :signature OR LOWER(name) = LOWER('iod_&&sql_id.'))
  LOOP
    SYS.DBMS_SQLDIAG.DROP_SQL_PATCH (
      name   => i.name, 
      ignore => TRUE
    );
  END LOOP;
END;
/
--
EXEC SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH(sql_text => :sql_text, hint_text => q'[&&hints_text.]', name => 'iod_&&sql_id.', description => q'[/*+ &&hints_text. */]');
--
PRO
PRO SQL Patch "iod_&&sql_id." was created
PRO
PRO Command to drop this SQL Patch:
PRO SQL> EXEC SYS.DBMS_SQLDIAG.DROP_SQL_PATCH(name => 'iod_&&sql_id.', ignore => TRUE);
PRO
PRO &&output_file_name..txt
PRO
SPO OFF;
UNDEFINE 1 2 sql_id hints_text

