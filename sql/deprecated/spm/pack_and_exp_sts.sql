REM $Header: 215187.1 pack_and_exp_sts.sql 11.4.5.8 2013/05/10 carlos.sierra $

PAU Requires Oracle Tuning Pack license. Hit "Enter" to proceed

ACC sql_text_piece PROMPT 'Enter SQL Text piece: '

SET PAGES 200 LONG 80000 ECHO ON;

COL sql_text PRI;

SELECT sql_id, sql_text /* exclude_me */
  FROM dba_sqlset_statements
 WHERE sql_text LIKE '%&&sql_text_piece.%'
   AND sql_text NOT LIKE '%/* exclude_me */%';

ACC sql_id PROMPT 'Enter SQL_ID: ';

SELECT sqlset_name, sqlset_owner /* exclude_me */
  FROM dba_sqlset_statements
 WHERE sql_id = '&&sql_id.';

ACC sqlset_name PROMPT 'Enter SQL Set Name: '

ACC sqlset_owner PROMPT 'Enter SQL Set Owner: ';

PAU About to re-create staging table SPM_STGTAB_STS. Hit "Enter" to proceed

DROP TABLE spm_stgtab_sts;

EXEC DBMS_SQLTUNE.create_stgtab_sqlset(table_name => 'SPM_STGTAB_STS', schema_name => USER);

BEGIN
  DBMS_SQLTUNE.pack_stgtab_sqlset (
   sqlset_name          => '&&sqlset_name.',
   sqlset_owner         => '&&sqlset_owner.',
   staging_table_name   => 'SPM_STGTAB_STS',
   staging_schema_owner => USER );
END;
/

ACC pwd PROMPT 'Enter &&_user. password, needed by export command: ' HIDE

HOS exp &&_user./&&pwd. FILE=spm_stgtab_sts.dmp TABLES=spm_stgtab_sts STATISTICS=NONE

SET PAGES 14 LONG 80 ECHO OFF;

UNDEF sql_text_piece sql_id sqlset_name sqlset_owner pwd

PRO spm_stgtab_sts.dmp was created
