set lin 400;
set feedback off;
set verify off;

prompt ========================================
prompt Installing IOD_SPM 
prompt ========================================

prompt granting PRIVILEGES to &&1.
@@grants.sql

prompt compiling package specification
@@iod_spm.pks.sql
SHOW ERRORS PACKAGE &&1..iod_spm;

prompt compiling package body
@@iod_spm.pkb.sql
SHOW ERRORS PACKAGE BODY &&1..iod_spm;
