PRO
PRO Pack SQL Patch:
BEGIN
  FOR i IN (SELECT name, category
              FROM dba_sql_patches 
             WHERE signature = :cs_signature
             ORDER BY name)
  LOOP
    DELETE &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_sqlpatch WHERE obj_name = i.name AND category = i.category;
    DBMS_SQLDIAG.pack_stgtab_sqlpatch(patch_name => i.name, patch_category => i.category, staging_table_name => '&&cs_stgtab_prefix._stgtab_sqlpatch', staging_schema_owner => '&&cs_stgtab_owner.');
  END LOOP;
END;
/
