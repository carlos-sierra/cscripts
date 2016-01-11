REM $Header: 215187.1 imp_and_unpack_sts.sql 11.4.5.8 2013/05/10 carlos.sierra $

PAU Requires Oracle Tuning Pack license. Hit "Enter" to proceed

PAU About to re-create staging table SPM_STGTAB_STS. Hit "Enter" to proceed

SET ECHO ON;

DROP TABLE spm_stgtab_sts;

ACC pwd PROMPT 'Enter &&_user. password, needed by import command: ' HIDE

HOS imp &&_user./&&pwd. FILE=spm_stgtab_sts.dmp TABLES=spm_stgtab_sts STATISTICS=NONE

UPDATE spm_stgtab_sts SET owner = USER;

COL sqlset_name NEW_V sqlset_name;

SELECT name sqlset_name FROM spm_stgtab_sts WHERE ROWNUM = 1;

BEGIN
  DBMS_SQLTUNE.unpack_stgtab_sqlset (
   sqlset_name          => '&&sqlset_name.',
   sqlset_owner         => USER,
   replace              => TRUE,
   staging_table_name   => 'SPM_STGTAB_STS',
   staging_schema_owner => USER );
END;
/

SET ECHO OFF;

UNDEF sqlset_name
