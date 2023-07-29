BEGIN
  FOR i IN (SELECT name 
              FROM dba_sql_patches 
             WHERE signature = :cs_signature
               AND name = NVL('&&cs_name.', name)
             ORDER BY name)
  LOOP
    $IF DBMS_DB_VERSION.ver_le_12_1
    $THEN
      DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', value => '&&cs_category.'); -- 12c
    $ELSE
      DBMS_SQLDIAG.alter_sql_patch(name => i.name, attribute_name => 'CATEGORY', attribute_value => '&&cs_category.'); -- 19c
    $END
  END LOOP;
END;
/