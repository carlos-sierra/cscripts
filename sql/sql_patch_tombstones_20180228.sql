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
DECLARE
  l_sql_fulltext CLOB;
BEGIN
  FOR i IN (SELECT sql_id
              FROM v$sql
             WHERE UPPER(sql_text) LIKE UPPER('%&&search_string.%')
               AND executions > 0 -- avoid division by zero error on HAVING
             GROUP BY
                   sql_id
            HAVING MAX(sql_plan_baseline) IS NULL -- sql has no baseline
               AND MAX(sql_profile) IS NULL -- sql has no sql profile
               AND MAX(sql_patch) IS NULL -- sql has no patch
               AND SUM(elapsed_time)/SUM(executions)/1e3 > 100 -- sql elapsed time per execution is > 100ms
               AND SUM(executions) > 50 -- sql has over 100 executions
             ORDER BY
                   SUM(executions) DESC)
  LOOP
    SELECT sql_fulltext INTO l_sql_fulltext FROM v$sql WHERE sql_id = i.sql_id AND ROWNUM = 1;
    DBMS_OUTPUT.PUT_LINE('creating sql patch "sql_patch_'||i.sql_id||'" with hint(s) /*+ &&cbo_hints. */ on '||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'));
    /*
    SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH (
      sql_text    => l_sql_fulltext,
      hint_text   => q'[&&cbo_hints.]',
      name        => 'sql_patch_'||i.sql_id,
      description => SUBSTR(q'[HINT(S): "&&cbo_hints."]',
      category    => 'DEFAULT',
      validate    => TRUE
    );  
    */
    --DBMS_OUTPUT.PUT_LINE('to drop: EXEC DBMS_SQLDIAG.DROP_SQL_PATCH(name => ''sql_patch_'||i.sql_id||''', ignore => TRUE);');
    --EXIT; this is to do 1st one and stop
  END LOOP;
END;
/
--
