ACC search_string PROMPT 'SEARCH_STRING (i.e. "tombstones,HashRange") req: ';
ACC cbo_hints PROMPT 'CBO Hints (i.e. "FIRST_ROWS(1)") req: ';

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

SPO sql_patch_create_string_&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO SEARCH_STRING: &&search_string.
PRO CBO_HINTS: &&cbo_hints.

SET LIN 300 SERVEROUT ON;
DECLARE
  l_sql_fulltext CLOB;
BEGIN
  FOR i IN (SELECT sql_id
              FROM v$sql
             WHERE sql_text LIKE '%&&search_string.%'
               AND executions > 100
             GROUP BY
                   sql_id
            HAVING MAX(sql_plan_baseline) IS NULL -- has no baseline
               AND MAX(sql_profile) IS NULL -- has no sql profile
               AND MAX(sql_patch) IS NULL -- has no patch
               AND SUM(elapsed_time)/SUM(executions)/1e3 > 100 -- elapsed time per execution is > 100ms
             ORDER BY
                   SUM(executions) DESC)
  LOOP
    SELECT sql_fulltext INTO l_sql_fulltext FROM v$sql WHERE sql_id = i.sql_id AND ROWNUM = 1;
    DBMS_OUTPUT.PUT_LINE('creating sql patch "sql_patch_'||i.sql_id||'" with hint(s) /*+ &&cbo_hints. */ on '||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'));
    SYS.DBMS_SQLDIAG_INTERNAL.I_CREATE_PATCH (
      sql_text    => l_sql_fulltext,
      hint_text   => q'[&&cbo_hints.]',
      name        => 'sql_patch_'||i.sql_id,
      description => q'[/*+ &&cbo_hints. */ &&search_string.]',
      category    => 'DEFAULT',
      validate    => TRUE
    );  
    DBMS_OUTPUT.PUT_LINE('to drop: EXEC DBMS_SQLDIAG.DROP_SQL_PATCH(name => ''sql_patch_'||i.sql_id||''', ignore => TRUE);');
    --EXIT; this is to do 1st one and stop
  END LOOP;
END;
/

SPO OFF;
