-- Create SQL Plan Baselin from AWR Plan
SET PAGES 200 LONG 80000;

ACC sql_id PROMPT 'Enter SQL_ID: ';

WITH
p AS (
SELECT plan_hash_value
  FROM dba_hist_sql_plan
 WHERE sql_id = TRIM('&&sql_id.')
   AND other_xml IS NOT NULL ),
a AS (
SELECT plan_hash_value,
       SUM(elapsed_time_total)/SUM(executions_total) avg_et_secs,
       MAX(executions_total) executions_total
  FROM dba_hist_sqlstat
 WHERE sql_id = TRIM('&&sql_id.')
   AND executions_total > 0
 GROUP BY
       plan_hash_value )
SELECT p.plan_hash_value,
       ROUND(a.avg_et_secs/1e6, 6) avg_et_secs,
       a.executions_total
  FROM p, a
 WHERE p.plan_hash_value = a.plan_hash_value(+)
 ORDER BY
       avg_et_secs NULLS LAST;

ACC plan_hash_value PROMPT 'Enter Plan Hash Value: ';

COL dbid NEW_V dbid NOPRI;
SELECT dbid FROM v$database;

COL begin_snap_id NEW_V begin_snap_id NOPRI;
COL end_snap_id NEW_V end_snap_id NOPRI;

SELECT MIN(p.snap_id) begin_snap_id, MAX(p.snap_id) end_snap_id
  FROM dba_hist_sqlstat p,
       dba_hist_snapshot s
 WHERE p.dbid = &&dbid
   AND p.sql_id = '&&sql_id.'
   AND p.plan_hash_value = TO_NUMBER('&&plan_hash_value.')
   AND s.snap_id = p.snap_id
   AND s.dbid = p.dbid
   AND s.instance_number = p.instance_number;

VAR sqlset_name VARCHAR2(30);

EXEC :sqlset_name := REPLACE('s_&&sql_id._&&plan_hash_value._awr', ' ');

PRINT sqlset_name;

SET SERVEROUT ON;

VAR plans NUMBER;

DECLARE
  l_sqlset_name VARCHAR2(30);
  l_description VARCHAR2(256);
  sts_cur       SYS.DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
  l_sqlset_name := :sqlset_name;
  l_description := 'SQL_ID:&&sql_id., PHV:&&plan_hash_value., BEGIN:&&begin_snap_id., END:&&end_snap_id.';
  l_description := REPLACE(REPLACE(l_description, ' '), ',', ', ');

  BEGIN
    DBMS_OUTPUT.put_line('dropping sqlset: '||l_sqlset_name);
    SYS.DBMS_SQLTUNE.drop_sqlset (
      sqlset_name  => l_sqlset_name,
      sqlset_owner => USER );
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.put_line(SQLERRM||' while trying to drop STS: '||l_sqlset_name||' (safe to ignore)');
  END;

  l_sqlset_name :=
  SYS.DBMS_SQLTUNE.create_sqlset (
    sqlset_name  => l_sqlset_name,
    description  => l_description,
    sqlset_owner => USER );
  DBMS_OUTPUT.put_line('created sqlset: '||l_sqlset_name);

  OPEN sts_cur FOR
    SELECT VALUE(p)
      FROM TABLE(DBMS_SQLTUNE.select_workload_repository (&&begin_snap_id., &&end_snap_id.,
      'sql_id = ''&&sql_id.'' AND plan_hash_value = TO_NUMBER(''&&plan_hash_value.'') AND loaded_versions > 0',
      NULL, NULL, NULL, NULL, 1, NULL, 'ALL')) p;

  SYS.DBMS_SQLTUNE.load_sqlset (
    sqlset_name     => l_sqlset_name,
    populate_cursor => sts_cur );
  DBMS_OUTPUT.put_line('loaded sqlset: '||l_sqlset_name);

  CLOSE sts_cur;

  :plans := DBMS_SPM.load_plans_from_sqlset (
    sqlset_name  => l_sqlset_name,
    sqlset_owner => USER );
END;
/

PRINT plans;

SET PAGES 14 LONG 80 ECHO OFF SERVEROUT OFF;

UNDEF sql_id plan_hash_value
CL COL
