REM $Header: 215187.1 imp_and_unpack_spb.sql 11.4.5.8 2013/05/10 carlos.sierra $

PAU About to re-create staging table SPM_STGTAB_SPB. Hit "Enter" to proceed

SET ECHO ON;

DROP TABLE spm_stgtab_spb;

ACC pwd PROMPT 'Enter &&_user. password, needed by import command: ' HIDE

HOS imp &&_user./&&pwd. FILE=spm_stgtab_spb.dmp TABLES=spm_stgtab_spb STATISTICS=NONE

UPDATE spm_stgtab_spb SET creator = USER;

VAR plans NUMBER;

BEGIN
  :plans := DBMS_SPM.unpack_stgtab_baseline (
    table_name  => 'SPM_STGTAB_SPB',
    table_owner => USER );
END;
/

PRINT plans;

SET ECHO OFF;
