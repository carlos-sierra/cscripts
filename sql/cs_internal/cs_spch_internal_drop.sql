PRO
PRO Drop SQL Patch(es) for: "&&cs_sql_id."
BEGIN
  FOR i IN (SELECT name FROM dba_sql_patches WHERE signature = &&cs_signature.)
  LOOP
    DBMS_SQLDIAG.drop_sql_patch(name => i.name); 
  END LOOP;
END;
/
