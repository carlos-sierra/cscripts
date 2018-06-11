REM $Header: 215187.1 create_sts_from_awr.sql 11.4.5.8 2013/05/10 carlos.sierra $

PAU Requires Oracle Tuning Pack license. Hit "Enter" to proceed

ACC sql_text_piece PROMPT 'Enter SQL Text piece: '

SET PAGES 200 LONG 80000 ECHO ON;

COL sql_text PRI;

SELECT dbid, sql_id, sql_text /* exclude_me */
  FROM dba_hist_sqltext
 WHERE sql_text LIKE '%&&sql_text_piece.%'
   AND sql_text NOT LIKE '%/* exclude_me */%';

ACC dbid NUM PROMPT 'Enter DBID: ';

ACC sql_id PROMPT 'Enter SQL_ID: ';

SELECT p.snap_id, s.startup_time, s.begin_interval_time, s.end_interval_time, /* exclude_me */
       p.instance_number, p.plan_hash_value, p.executions_total, p.elapsed_time_total,
       CASE WHEN p.executions_total > 0 THEN ROUND(p.elapsed_time_total/p.executions_total/1e6, 3) END avg_secs_per_exec
  FROM dba_hist_sqlstat p,
       dba_hist_snapshot s
 WHERE p.dbid = &&dbid
   AND p.sql_id = '&&sql_id.'
   AND s.snap_id = p.snap_id
   AND s.dbid = p.dbid
   AND s.instance_number = p.instance_number
 ORDER BY
       p.snap_id, p.plan_hash_value;

ACC plan_hash_value PROMPT 'Enter Plan Hash Value: ';

SELECT p.snap_id, s.startup_time, s.begin_interval_time, s.end_interval_time, /* exclude_me */
       p.instance_number, p.executions_total, p.elapsed_time_total,
       CASE WHEN p.executions_total > 0 THEN ROUND(p.elapsed_time_total/p.executions_total/1e6, 3) END avg_secs_per_exec
  FROM dba_hist_sqlstat p,
       dba_hist_snapshot s
 WHERE p.dbid = &&dbid
   AND p.sql_id = '&&sql_id.'
   AND p.plan_hash_value = TO_NUMBER('&&plan_hash_value.')
   AND s.snap_id = p.snap_id
   AND s.dbid = p.dbid
   AND s.instance_number = p.instance_number
 ORDER BY
       p.snap_id, p.plan_hash_value;

ACC begin_snap_id NUM PROMPT 'Enter begin SNAP_ID: ';

ACC end_snap_id NUM PROMPT 'Enter end SNAP_ID: ';

VAR sqlset_name VARCHAR2(30);

EXEC :sqlset_name := 's_&&sql_id._&&plan_hash_value._awr';

PRINT sqlset_name;

SET SERVEROUT ON;

DECLARE
  l_sqlset_name VARCHAR2(30);
  l_description VARCHAR2(256);
  sts_cur       SYS.DBMS_SQLTUNE.SQLSET_CURSOR;
BEGIN
  l_sqlset_name := :sqlset_name;
  l_description := 'SQL_ID:&&sql_id., PHV:&&plan_hash_value., BEGIN:&&begin_snap_id., END:&&end_snap_id.';

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
      FROM TABLE(DBMS_SQLTUNE.select_workload_repository(&&begin_snap_id., &&end_snap_id.,
      'sql_id = ''&&sql_id.'' AND plan_hash_value = TO_NUMBER(''&&plan_hash_value.'') AND loaded_versions > 0',
      NULL, NULL, NULL, NULL, 1, NULL, 'ALL')) p;

  SYS.DBMS_SQLTUNE.load_sqlset (
    sqlset_name     => l_sqlset_name,
    populate_cursor => sts_cur );
  DBMS_OUTPUT.put_line('loaded sqlset: '||l_sqlset_name);

  CLOSE sts_cur;
END;
/

SET PAGES 14 LONG 80 ECHO OFF SERVEROUT OFF;

UNDEF sql_text_piece dbid sql_id plan_hash_value begin_snap_id end_snap_id
