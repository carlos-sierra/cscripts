set lin 400;
set feedback off;
set verify off;

prompt ========================================
prompt Installing IOD_SESS objects
prompt ========================================

prompt granting PRIVILEGES to &&1.
@@grants.sql

prompt creating objects
@@objects.sql

prompt compiling package specification
@@iod_sess.pks.sql
show errors package &&1..iod_sess

prompt compiling package body
@@iod_sess.pkb.sql
show errors package body &&1..iod_sess

-- exit if package does not exist
WHENEVER SQLERROR EXIT FAILURE;
COL package_version FOR A80;
SELECT '&&1..iod_sess version: '||&&1..iod_sess.get_package_version package_version FROM DUAL;
