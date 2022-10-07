SELECT COUNT(*) FROM dba_sql_plan_baselines WHERE sql_handle = 'SQL_e5139807d3942f41' AND plan_name = 'SQL_PLAN_fa4ws0z9t8bu1b803ca70' AND enabled = 'YES' AND accepted = 'YES'
/
--
VAR plans NUMBER;
EXEC :plans := DBMS_SPM.DROP_SQL_PLAN_BASELINE(sql_handle => 'SQL_e5139807d3942f41', plan_name => 'SQL_PLAN_fa4ws0z9t8bu1b803ca70');
--
BEGIN
  FOR i IN (SELECT DISTINCT name FROM dba_sql_profiles WHERE signature = 16506704218624896833)
  LOOP
    DBMS_SQLTUNE.DROP_SQL_PROFILE(name => i.name, ignore => TRUE);
  END LOOP;
END;
/