REM $Header: 215187.1 pack_and_exp_spb.sql 11.4.5.8 2013/05/10 carlos.sierra $

ACC sql_text_piece PROMPT 'Enter SQL Text piece: '

SET PAGES 200 LONG 80000 ECHO ON;

COL sql_text PRI;

SELECT sql_handle, plan_name, sql_text /* exclude_me */
  FROM dba_sql_plan_baselines
 WHERE sql_text LIKE '%&&sql_text_piece.%'
   AND sql_text NOT LIKE '%/* exclude_me */%';

ACC sql_handle PROMPT 'Enter SQL Handle: ';

SELECT plan_name, created /* exclude_me */
  FROM dba_sql_plan_baselines
 WHERE sql_handle = '&&sql_handle.'
 ORDER BY
       created;

ACC plan_name PROMPT 'Enter optional Plan Name: ';

PAU About to re-create staging table SPM_STGTAB_SPB. Hit "Enter" to proceed

DROP TABLE spm_stgtab_spb;

EXEC DBMS_SPM.create_stgtab_baseline(table_name => 'SPM_STGTAB_SPB', table_owner => USER);

VAR plans NUMBER;

BEGIN
  IF '&&plan_name.' IS NULL THEN
    :plans := DBMS_SPM.pack_stgtab_baseline (
      table_name  => 'SPM_STGTAB_SPB',
      table_owner => USER,
      sql_handle  => '&&sql_handle.' );
  ELSE
    :plans := DBMS_SPM.pack_stgtab_baseline (
      table_name  => 'SPM_STGTAB_SPB',
      table_owner => USER,
      sql_handle  => '&&sql_handle.',
      plan_name   => '&&plan_name.' );
  END IF;
END;
/

PRINT plans;

ACC pwd PROMPT 'Enter &&_user. password, needed by export command: ' HIDE

HOS exp &&_user./&&pwd. FILE=spm_stgtab_spb.dmp TABLES=spm_stgtab_spb STATISTICS=NONE

SET PAGES 14 LONG 80 ECHO OFF;

UNDEF sql_text_piece sql_handle plan_name pwd

PRO spm_stgtab_spb.dmp was created
