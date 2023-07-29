SELECT name FROM dba_sql_profiles MINUS SELECT sql_profile FROM v$sql WHERE sql_profile IS NOT NULL;
BEGIN
  FOR i IN (SELECT name FROM dba_sql_profiles MINUS SELECT sql_profile FROM v$sql WHERE sql_profile IS NOT NULL) 
  LOOP
    DBMS_SQLTUNE.drop_sql_profile(name => i.name); 
  END LOOP;
END;
/
SELECT name FROM dba_sql_profiles MINUS SELECT sql_profile FROM v$sql WHERE sql_profile IS NOT NULL;