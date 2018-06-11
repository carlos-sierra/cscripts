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
SELECT 'planm_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_'))||'_'||LOWER(SYS_CONTEXT('USERENV','CON_NAME'))||'_&&sql_id._'||TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') output_file_name FROM v$database, v$instance;

SPO &&output_file_name..txt
PRO SQL> @planm.sql &&sql_id.
PRO
PRO &&output_file_name..txt
PRO
PRO V$SQL_PLAN_STATISTICS_ALL Plans
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

COL last_active_time FOR A19;
COL is_obsolete FOR A8 HEA 'OBSOLETE';
COL is_shareable FOR A9 HEA 'SHAREABLE'

WITH
ranked_child_cursors AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id,
       child_number,
       ROW_NUMBER () OVER (PARTITION BY plan_hash_value ORDER BY 
       CASE 
         WHEN object_status = 'VALID' AND is_obsolete = 'N' AND is_shareable = 'Y' THEN 1
         WHEN object_status = 'VALID' AND is_obsolete = 'N' AND is_shareable = 'N' THEN 2
         WHEN object_status = 'VALID' AND is_obsolete = 'Y' THEN 3
         ELSE 4
       END,
       last_active_time DESC) row_number,
       plan_hash_value,
       last_active_time,
       object_status,
       is_obsolete,
       is_shareable
  FROM v$sql 
 WHERE sql_id = '&&sql_id.'
 ORDER BY
       last_active_time DESC
)
SELECT TO_CHAR(last_active_time, 'YYYY-MM-DD"T"HH24:MI:SS') last_active_time,
       plan_hash_value,
       child_number,
       object_status,
       is_obsolete,
       is_shareable
  FROM ranked_child_cursors r
 WHERE r.row_number = 1
/

PRO
SET HEA OFF;
WITH
ranked_child_cursors AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sql_id,
       child_number,
       ROW_NUMBER () OVER (PARTITION BY plan_hash_value ORDER BY 
       CASE 
         WHEN object_status = 'VALID' AND is_obsolete = 'N' AND is_shareable = 'Y' THEN 1
         WHEN object_status = 'VALID' AND is_obsolete = 'N' AND is_shareable = 'N' THEN 2
         WHEN object_status = 'VALID' AND is_obsolete = 'Y' THEN 3
         ELSE 4
       END,
       last_active_time DESC) row_number
  FROM v$sql 
 WHERE sql_id = '&&sql_id.'
 ORDER BY
       last_active_time DESC
)
SELECT p.plan_table_output
  FROM ranked_child_cursors r,
       TABLE(DBMS_XPLAN.DISPLAY_CURSOR(r.sql_id, r.child_number, 'ADVANCED ALLSTATS LAST -PROJECTION -ALIAS')) p
 WHERE r.row_number = 1
/
SET HEA ON;

PRO &&output_file_name..txt
PRO
SPO OFF;

UNDEF 1 sql_id