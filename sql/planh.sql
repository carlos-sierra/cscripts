SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET SERVEROUT OFF;

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
--WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') = 'CDB$ROOT' THEN
    raise_application_error(-20000, 'Be aware! You are executing this script connected into CDB$ROOT.');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;

PRO
PRO 1. Enter SQL_ID
DEF sql_id = '&1.';

COL output_file_name NEW_V output_file_name NOPRI;
SELECT 'planh_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||LOWER(SYS_CONTEXT('USERENV','CON_NAME'))||'_&&sql_id._'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM v$database, v$instance;

SPO &&output_file_name..txt
PRO SQL> @planh.sql &&sql_id.
PRO
PRO &&output_file_name..txt
PRO
PRO DBA_HIST_SQL_PLAN Plans
PRO ~~~~~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(timestamp, 'YYYY-MM-DD"T"HH24:MI:SS') timestamp,
       plan_hash_value
  FROM dba_hist_sql_plan
 WHERE sql_id = '&&sql_id.'
   AND id = 0
 ORDER BY
       timestamp DESC
/

PRO
SET HEA OFF;
WITH 
plans_by_timestamp AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id,
       plan_hash_value
  FROM dba_hist_sql_plan
 WHERE sql_id = '&&sql_id.'
   AND id = 0
 ORDER BY
       timestamp DESC
)
SELECT p.plan_table_output
  FROM plans_by_timestamp h,
       TABLE(DBMS_XPLAN.DISPLAY_AWR(h.sql_id, h.plan_hash_value, NULL, 'ADVANCED -PROJECTION -ALIAS')) p
/
SET HEA ON;

PRO &&output_file_name..txt
PRO
SPO OFF;

UNDEF 1 sql_id