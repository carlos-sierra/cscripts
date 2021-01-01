-- gets tablespace
COL cs_default_tablespace NEW_V cs_default_tablespace NOPRI;
SELECT default_tablespace cs_default_tablespace FROM dba_users WHERE username = UPPER('&&cs_stgtab_owner.');
ALTER USER &&cs_stgtab_owner. QUOTA UNLIMITED ON &&cs_default_tablespace.;
--
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
