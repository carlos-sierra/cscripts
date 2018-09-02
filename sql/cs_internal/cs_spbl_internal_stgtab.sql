EXEC DBMS_SPM.create_stgtab_baseline(table_name => '&&cs_stgtab_prefix._stgtab_baseline', table_owner => '&&cs_stgtab_owner.');
--
COL cs_default_tablespace NEW_V cs_default_tablespace NOPRI;
SELECT default_tablespace cs_default_tablespace FROM dba_users WHERE username = UPPER('&&cs_stgtab_owner.');
ALTER USER &&cs_stgtab_owner. QUOTA UNLIMITED ON &&cs_default_tablespace.;
--
SET LIN 80;
DESC &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline;
SET LIN 32767;
--
PRO
PRO &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline;
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT COUNT(*) FROM &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline;
--