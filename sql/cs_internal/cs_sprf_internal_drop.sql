PRO
PRO Drop SQL Profile(s) for: "&&cs_sql_id."
BEGIN
  FOR i IN (SELECT name FROM dba_sql_profiles WHERE signature = &&cs_signature.) 
  LOOP
    DBMS_SQLTUNE.drop_sql_profile(name => i.name); 
  END LOOP;
END;
/
