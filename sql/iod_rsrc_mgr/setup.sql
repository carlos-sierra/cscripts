set lin 400;
set feedback off;
set verify off;

prompt ========================================
prompt Installing IOD_RSRC_MGR 
prompt ========================================

prompt granting PRIVILEGES to &&1.
@@grants.sql

prompt compiling package specification
@@iod_rsrc_mgr.pks.sql
SHOW ERRORS PACKAGE &&1..iod_rsrc_mgr;

prompt compiling package body
@@iod_rsrc_mgr.pkb.sql
SHOW ERRORS PACKAGE BODY &&1..iod_rsrc_mgr;
