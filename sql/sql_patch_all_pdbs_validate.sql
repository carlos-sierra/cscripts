----------------------------------------------------------------------------------------
--
-- File name:   sql_patch_all_pdbs_validate.sql
--
-- Purpose:     Validate performance of SQL matching a search_string and having a
--              SQL patch (created by sql_patch_all_pdbs.sql).
--
-- Author:      Carlos Sierra
--
-- Version:     2018/03/26
--
-- Usage:       Verify SQL performance after creating SQL patches for all PDBs. 
--              Pass parameter search_string when asked.
--
-- Example:     @sql_patch_all_pdbs_validate.sql
--              then pass: "tombstones,HashRange"
--
-- Notes:       Do not include the double quotes used to highlight parameter values.
--
--              If implemented on an OEM job, replace then ACC command with DEF
--             
--              To drop a SQL patch use: EXEC DBMS_SQLDIAG.DROP_SQL_PATCH('patch_name');
--
---------------------------------------------------------------------------------------
--
--ACC search_string PROMPT 'Search string (e.g. "tombstones,HashRange"): ';
--
DEF search_string = 'tombstones,HashRange';
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
WHENEVER SQLERROR EXIT FAILURE;
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET HEA OFF;
SET LIN 2000 PAGES 0 RECSEP EACH;
SET SQLP '';
--
ALTER SESSION SET container = CDB$ROOT;
--
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
--
SPO /tmp/sql_patch_all_pdbs_validate_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO SEARCH_STRING: &&search_string.
PRO
SELECT 'PRO pdb:'||c.name||
       ' sql_id:'||s.sql_id||
       ' ph:'||COUNT(DISTINCT s.plan_hash_value)||
       ' '||MIN(s.plan_hash_value)||
       CASE WHEN COUNT(DISTINCT s.plan_hash_value) > 1 THEN ' '||MAX(s.plan_hash_value) END||
       ' ex:'||SUM(s.executions)||
       ' et:'||SUM(s.elapsed_time)||
       ' ms:'||TRIM(TO_CHAR(ROUND(SUM(s.elapsed_time)/1e3/SUM(s.executions),3),'999,990.000'))||
       ' bl:'||COUNT(DISTINCT s.sql_plan_baseline)||
       ' pf:'||COUNT(DISTINCT s.sql_profile)||
       ' pc:'||COUNT(DISTINCT s.sql_patch)||
       ' '||REPLACE(SUBSTR(MAX(s.sql_text),1,1000),CHR(10),' ')
  FROM v$sql s,
       v$containers c
 WHERE UPPER(s.sql_text) LIKE UPPER(CHR(37)||'&&search_string.'||CHR(37))
   AND UPPER(s.sql_text) NOT LIKE CHR(37)||'V$SQL'||CHR(37) -- filters out this query and similar ones
   AND s.sql_text NOT LIKE CHR(37)||'RESULT_CACHE'||CHR(37)
   AND s.sql_text NOT LIKE CHR(37)||'EXCLUDE_ME'||CHR(37)
   AND s.executions > 0 -- avoid division by zero error
   AND s.parsing_user_id > 0 -- exclude sys
   AND s.parsing_schema_id > 0 -- exclude sys
   AND c.con_id = s.con_id
   AND c.open_mode = 'READ WRITE'
--HAVING COUNT(DISTINCT s.sql_patch) > 0
 GROUP BY
       c.name,
       s.sql_id
 ORDER BY
       c.name,
       s.sql_id
/
SPO OFF;
--
SET ECHO OFF FEED ON HEA ON;
SET RECSEP WRAPPED;
SET SQLP 'SQL>';
