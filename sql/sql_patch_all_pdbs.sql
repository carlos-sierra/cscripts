----------------------------------------------------------------------------------------
--
-- File name:   sql_patch_all_pdbs.sql
--
-- Purpose:     Create SQL patches in all PDBs for queries matching a search string,
--              but only query performance per execution is over 100ms, and there is no
--              active SQL SQL patch on it. Disable SQL Plan Baselines (if any).
--
-- Author:      Carlos Sierra
--
-- Version:     2018/03/26
--
-- Usage:       Apply a SQL patch with one or few CBO hints on queries for which we
--              are confident such patch is needed (e.g. tombstones). 
--              Pass parameters report_only, search_string and cbo_hints when asked.
--
-- Example:     @sql_patch_all_pdbs.sql
--              then pass: "Y", "tombstones,HashRange" and "FIRST_ROWS(1)"
--
-- Notes:       Do not include the double quotes used to highlight parameter values.
--
--              If implemented on an OEM job, replace then ACC commands with DEF
--             
--              To drop a SQL patch use: EXEC DBMS_SQLDIAG.DROP_SQL_PATCH('patch_name');
--
---------------------------------------------------------------------------------------
--
--ACC report_only PROMPT 'Report only? [ Y | N ] (N: create SQL patches for matching SQL): ';
--ACC search_string PROMPT 'Search string (e.g. "tombstones,HashRange"): ';
--ACC cbo_hints PROMPT 'CBO Hints (e.g. "FIRST_ROWS(1)"): ';
--
DEF report_only = 'N';
DEF search_string = 'tombstones,HashRange';
DEF cbo_hints = 'FIRST_ROWS(1)';
--
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
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET HEA OFF;
SET LIN 2000 PAGES 0 RECSEP EACH;
SET SQLP '';
VAR sql_fulltext CLOB;
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
SPO sql_patch_all_pdbs_&&current_time._dynamic.sql;
SELECT CHR(10)||'PRO'||
       CASE 
       WHEN SUM(s.elapsed_time)/1e3/SUM(s.executions) > 100 -- elapsed time per execution > 100ms
       AND SUM(s.executions) > 100 -- over 100 executions
       --AND COUNT(DISTINCT s.sql_plan_baseline) = 0 -- has no baseline
       --AND COUNT(DISTINCT s.sql_profile) = 0 -- has no profile
       AND COUNT(DISTINCT s.sql_patch) = 0 -- has no patch
       THEN
       ' ***'
       END||
       ' pdb:'||c.name||
       ' sql_id:'||s.sql_id||
       ' signature:'||s.exact_matching_signature||
       ' ph:'||COUNT(DISTINCT s.plan_hash_value)||
       ' '||MIN(s.plan_hash_value)||
       CASE WHEN COUNT(DISTINCT s.plan_hash_value) > 1 THEN ' '||MAX(s.plan_hash_value) END||
       ' ex:'||SUM(s.executions)||
       ' et:'||SUM(s.elapsed_time)||
       ' ms:'||TRIM(TO_CHAR(ROUND(SUM(s.elapsed_time)/1e3/SUM(s.executions),3),'999,990.000'))||
       ' bl:'||COUNT(DISTINCT s.sql_plan_baseline)||
       ' pf:'||COUNT(DISTINCT s.sql_profile)||
       ' pc:'||COUNT(DISTINCT s.sql_patch)||
       ' '||REPLACE(SUBSTR(MAX(s.sql_text),1,1000),CHR(10),' ')||CHR(10)||
       CASE 
       WHEN SUM(s.elapsed_time)/1e3/SUM(s.executions) > 100 -- elapsed time per execution > 100ms
       AND SUM(s.executions) > 100 -- over 100 executions
       --AND COUNT(DISTINCT s.sql_plan_baseline) = 0 -- has no baseline
       --AND COUNT(DISTINCT s.sql_profile) = 0 -- has no profile
       AND COUNT(DISTINCT s.sql_patch) = 0 -- has no patch
       AND '&&report_only.' = 'N'
       THEN
       CHR(10)||'ALTER SESSION SET CONTAINER = '||c.name||';'||CHR(10)||
       'DECLARE '||CHR(10)||
       '  l_count NUMBER; '||CHR(10)||
       'BEGIN '||CHR(10)||
       '  SELECT sql_fulltext '||CHR(10)||
       '    INTO :sql_fulltext '||CHR(10)||
       '    FROM v$sql '||CHR(10)||
       '   WHERE sql_id = '''||s.sql_id||''''||CHR(10)||
       '     AND ROWNUM = 1; '||CHR(10)||
       '  -- disable baselines (if any) '||CHR(10)||
       '  FOR i IN (SELECT sql_handle, plan_name  '||CHR(10)||
       '              FROM dba_sql_plan_baselines  '||CHR(10)||
       '             WHERE signature = '||s.exact_matching_signature||' '||CHR(10)||
       q'[             AND enabled = 'YES' ]'||CHR(10)||
       '             ORDER BY signature, plan_name) '||CHR(10)||
       '  LOOP '||CHR(10)||
       q'[    l_count := DBMS_SPM.ALTER_SQL_PLAN_BASELINE(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO'); ]'||CHR(10)||
       q'[    DBMS_OUTPUT.PUT_LINE(l_count||' SQL Plan Baselines wehere disabled'); -- OEM ignores this command ]'||CHR(10)||
       '  END LOOP; '||CHR(10)||
       '  -- got patch? '||CHR(10)||
       '  SELECT COUNT(*) '||CHR(10)||
       '    INTO l_count  '||CHR(10)||
       '    FROM dba_sql_patches '||CHR(10)||
       '   WHERE name = ''sql_patch_'||s.sql_id||'''; '||CHR(10)||
       '  -- create patch only if non exists '||CHR(10)||
       '  IF l_count = 0 THEN '||CHR(10)||
       '    SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH ('||CHR(10)||
       '      sql_text => :sql_fulltext,'||CHR(10)||
       q'[      hint_text => '&&cbo_hints.',]'||CHR(10)||
       '      name => ''sql_patch_'||s.sql_id||''','||CHR(10)||
       q'[      description => '&&cbo_hints.',]'||CHR(10)||
       '      category => ''DEFAULT'','||CHR(10)||
       '      validate => TRUE'||CHR(10)||
       '    );'||CHR(10)||
       q'[    DBMS_OUTPUT.PUT_LINE('SQL Patch was created'); -- OEM ignores this command ]'||CHR(10)||
       '  END IF; '||CHR(10)||
       'END;'||CHR(10)||
       '/'
       END||CHR(10)
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
 GROUP BY
       c.name,
       s.sql_id,
       s.exact_matching_signature
 ORDER BY
       c.name,
       s.sql_id
/
SPO OFF;
--
SET ECHO ON VER ON FEED ON;
SPO /tmp/sql_patch_all_pdbs_&&current_time..txt; 
PRO **************************************************************************************
PRO
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO SEARCH_STRING: &&search_string.
PRO CBO_HINTS: &&cbo_hints.
PRO
@sql_patch_all_pdbs_&&current_time._dynamic.sql;
PRO
PRO **************************************************************************************
--SPO OFF;
SET ECHO OFF FEED ON HEA ON;
SET RECSEP WRAPPED;
SET SQLP 'SQL>';
ALTER SESSION SET container = CDB$ROOT;
