PRO
PRO Pack SQL Profile:
BEGIN
  FOR i IN (SELECT name 
              FROM dba_sql_profiles 
             WHERE signature = :cs_signature
             ORDER BY name)
  LOOP
    DBMS_SQLTUNE.pack_stgtab_sqlprof(profile_name => i.name, staging_table_name => '&&cs_stgtab_prefix._stgtab_sqlprof', staging_schema_owner => '&&cs_stgtab_owner.');
  END LOOP;
END;
/
