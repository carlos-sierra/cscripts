@@cs_set_quota_tools_owner.sql
-- create staging table
DECLARE
  l_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER('&&cs_stgtab_owner.') AND table_name = UPPER('&&cs_stgtab_prefix._stgtab_sqlpatch');
  IF l_exists = 0 THEN
    DBMS_SQLDIAG.create_stgtab_sqlpatch(table_name => UPPER('&&cs_stgtab_prefix._stgtab_sqlpatch'), schema_name => UPPER('&&cs_stgtab_owner.'), tablespace_name => UPPER('&&cs_default_tablespace.'));
  END IF;
END;
/
--
PRO
PRO &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_sqlpatch;
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT COUNT(*) AS "ROWS" FROM &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_sqlpatch;
--
