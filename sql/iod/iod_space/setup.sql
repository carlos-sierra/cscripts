set lin 400;
set feedback off;
set verify off;

prompt ========================================
prompt Installing IOD_SPACE objects
prompt ========================================

prompt granting PRIVILEGES to &&1.
@@grants.sql

prompt creating objects
@@objects.sql

prompt compiling package specification
@@iod_space.pks.sql
show errors package &&1..iod_space

prompt compiling package body
@@iod_space.pkb.sql
show errors package body &&1..iod_space

-- exit if package does not exist
WHENEVER SQLERROR EXIT FAILURE;
COL package_version FOR A80;
SELECT '&&1..iod_space version: '||&&1..iod_space.get_package_version package_version FROM DUAL;
