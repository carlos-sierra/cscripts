SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
--
PRO
PRO Before
PRO ~~~~~~
SELECT TRUNC(b.last_modified) AS last_modified, TRUNC(SYSDATE) - TRUNC(b.last_modified) AS days, COUNT(*) AS baselines,
       COUNT(DISTINCT sql_id) AS queries
  FROM cdb_sql_plan_baselines b,
       v$sql s
 WHERE b.enabled = 'YES'
 AND   b.accepted = 'YES'
 AND   s.sql_plan_baseline(+) = b.plan_name
 AND   s.con_id(+) = b.con_id
 GROUP BY
       TRUNC(b.last_modified)
 ORDER BY
 1
 /
--
PRO
PRO Disabling Baselines unused for 7 weeks
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
DECLARE
  mySQL CLOB := q'[
DECLARE
  l_plans INTEGER;
BEGIN
  FOR i IN (SELECT sql_handle, plan_name, description FROM dba_sql_plan_baselines WHERE enabled = 'YES' AND accepted = 'YES' AND last_modified < SYSDATE - (7 * 7))
  LOOP
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'ENABLED', attribute_value => 'NO');
    l_plans := DBMS_SPM.alter_sql_plan_baseline(sql_handle => i.sql_handle, plan_name => i.plan_name, attribute_name => 'DESCRIPTION', attribute_value => TRIM(i.description||' DISABLED='||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))||' DBPERF-7018');   
  END LOOP;
END;
]';
  procedure run_sql( runSQL in varchar2, conName in varchar2 default 'cdb$root' )
  is
    rc number := 0;
    cn number := 0;
  begin
    dbms_output.put_line( conName || ':' || runSQL );
    cn := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(
      c => cn,
      statement => runSQL,
      language_flag => DBMS_SQL.NATIVE,
      edition => NULL,
      apply_crossedition_trigger => NULL,
      --schema => 'PDBADMIN',
      container => conName
    );
    rc := DBMS_SQL.EXECUTE(c => cn);
  end run_sql;
BEGIN
  FOR i IN (SELECT name FROM v$containers WHERE con_id > 2 ORDER BY name)
  LOOP
    run_sql(mySQL, i.name);
  END LOOP;
END;
/
--
PRO
PRO After
PRO ~~~~~
SELECT TRUNC(b.last_modified) AS last_modified, TRUNC(SYSDATE) - TRUNC(b.last_modified) AS days, COUNT(*) AS baselines,
       COUNT(DISTINCT sql_id) AS queries
  FROM cdb_sql_plan_baselines b,
       v$sql s
 WHERE b.enabled = 'YES'
 AND   b.accepted = 'YES'
 AND   s.sql_plan_baseline(+) = b.plan_name
 AND   s.con_id(+) = b.con_id
 GROUP BY
       TRUNC(b.last_modified)
 ORDER BY
 1
 /