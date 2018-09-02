set lin 400;
set feedback off;
set verify off;

prompt ========================================
prompt Installing IOD_SPACE objects
prompt ========================================

prompt granting PRIVILEGES to &&1.
@@grants.sql

prompt sets library version
@@version.sql

DEF conditional_skip = '';
COL conditional_skip NEW_V conditional_skip NOPRI;
SELECT CASE COUNT(*) WHEN 2 THEN '--skip--' END conditional_skip 
  FROM dba_source
 WHERE owner = UPPER(TRIM('&&1.')) 
   AND name = 'IOD_SPACE'
   AND line <= 3 
   AND type LIKE 'PACKAGE%' 
   AND text LIKE '%Header%'
   AND text LIKE '%&&library_version.%'
/

prompt creating objects
@@objects.sql

prompt compiling package specification (if there is a new version)
@@&&conditional_skip.iod_space.pks.sql
show errors package &&1..iod_space

prompt compiling package body (if there is a new version)
@@&&conditional_skip.iod_space.pkb.sql
show errors package body &&1..iod_space

-- exit if package does not exist
WHENEVER SQLERROR EXIT FAILURE;
COL package_version FOR A80;
SELECT '&&1..iod_space version: '||&&1..iod_space.get_package_version package_version FROM DUAL;
