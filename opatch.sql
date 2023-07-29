-- opatch.sql - Oracle Patch Registry and History
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF6';
CLEAR SQL
PRO
PRO dba_registry
PRO ~~~~~~~~~~~~
1 SELECT * FROM dba_registry;
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO dba_registry_sqlpatch
PRO ~~~~~~~~~~~~~~~~~~~~~
1 SELECT action_time,action,status,description,logfile,ru_logfile,patch_id,patch_uid,patch_type,source_version,target_version FROM dba_registry_sqlpatch ORDER by action_time;
@@cs_internal/cs_pr_internal.sql ""
PRO
PRO dba_registry_history
PRO ~~~~~~~~~~~~~~~~~~~~
1 SELECT * FROM dba_registry_history;
@@cs_internal/cs_pr_internal.sql ""
