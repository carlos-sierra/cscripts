SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF3';
--
COL object_owner_name FOR A60 TRUNC;
COL created FOR A23 TRUNC;
COL last_modified FOR A23 TRUNC;
COL last_used FOR A23 TRUNC;
--
SELECT d.directive_id,
       o.owner||'.'||o.object_name||CASE WHEN o.subobject_name IS NOT NULL THEN '.' END||o.subobject_name AS object_owner_name,
       o.object_type,
       d.type,
       d.enabled,
       d.state,
       d.auto_drop,
       d.reason,
       d.created,
       d.last_modified,
       d.last_used
  FROM dba_sql_plan_directives d,
       dba_sql_plan_dir_objects o,
       dba_users u
 WHERE o.directive_id = d.directive_id
   AND u.username = o.owner
   AND u.oracle_maintained = 'N'
ORDER BY
       d.directive_id,
       o.owner,
       o.object_name,
       o.subobject_name,
       o.object_type
/
