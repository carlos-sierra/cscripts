----------------------------------------------------------------------------------------
--
-- File name:   sql_patch_tombstones_20180228.sql
--
-- Purpose:     SQL Patch first_rows hint into queries on tombstones table(s).
--
-- Author:      Carlos Sierra
--
-- Version:     2018/02/28
--
-- Usage:       Execute connected into the CDB of interest.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @sql_patch_tombstones.sql
--
-- Notes:       Executes on each PDB driven by sql_patch_tombstones_20180228_driver.sql
--
--              Compatible with SQL Plan Baselines.
--
--              Only acts on SQL decorated with search string below, executed over
--              100 times, with no prior SPB, Profile or Patch, and with performance
--              worse than 100ms per execution.
--
--              Use fs.sql script passing same search string to validate sql performance
--              before and after.
--             
---------------------------------------------------------------------------------------
--
SET HEA OFF FEED OFF ECHO OFF VER OFF;
SET LIN 300 SERVEROUT ON;
--
DECLARE
  l_sql_fulltext CLOB;
BEGIN
  FOR i IN (SELECT sql_id, 
                   SUM(executions) executions, 
                   SUM(elapsed_time) elapsed_time,
                   COUNT(DISTINCT sql_plan_baseline) baselines,
                   COUNT(DISTINCT sql_profile) profiles,
                   COUNT(DISTINCT sql_patch) patches
              FROM v$sql
             WHERE UPPER(sql_text) LIKE UPPER('%&&search_string.%')
               AND UPPER(sql_text) NOT LIKE '%V$SQL%' -- filters out this query and similar ones
               AND executions > 0 -- avoid division by zero error on HAVING
               AND parsing_user_id > 0 -- exclude sys
               AND parsing_schema_id > 0 -- exclude sys
               AND sql_text NOT LIKE '%RESULT_CACHE%'
               AND sql_text NOT LIKE '%EXCLUDE_ME%'
             GROUP BY
                   sql_id
            /*
            HAVING SUM(executions) > 1 -- sql has over 1 executions
               AND MAX(sql_plan_baseline) IS NULL -- sql has no baseline
               AND MAX(sql_profile) IS NULL -- sql has no sql profile
               AND MAX(sql_patch) IS NULL -- sql has no patch
               AND SUM(elapsed_time)/SUM(executions)/1e3 > 100 -- sql elapsed time per execution is > 100ms
            */
             ORDER BY
                   sql_id)
  LOOP
    DBMS_OUTPUT.PUT_LINE('sql_id:'||i.sql_id||' ex:'||i.executions||' et:'||i.elapsed_time||' ms:'||ROUND(i.elapsed_time/1e3/i.executions,3)||' bl:'||i.baselines||' pf:'||i.profiles||' pc:'||i.patches);
    SELECT sql_fulltext INTO l_sql_fulltext FROM v$sql WHERE sql_id = i.sql_id AND ROWNUM = 1;
    --DBMS_OUTPUT.PUT_LINE('creating sql patch "sql_patch_'||i.sql_id||'" with hint(s) /*+ &&cbo_hints. */ on '||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'));
    IF '&&report_only.' = 'N' THEN
      SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH (
        sql_text    => l_sql_fulltext,
        hint_text   => q'[&&cbo_hints.]',
        name        => UPPER('sql_patch_'||i.sql_id),
        description => SUBSTR(q'[HINT: "&&cbo_hints."]', 1, 500),
        category    => 'DEFAULT',
        validate    => TRUE
      );  
    END IF;
    --DBMS_OUTPUT.PUT_LINE('to drop: EXEC DBMS_SQLDIAG.DROP_SQL_PATCH(name => ''sql_patch_'||i.sql_id||''', ignore => TRUE);');
    --EXIT; this is to do 1st one and stop
  END LOOP;
END;
/
--
