SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
SELECT d.pluggable_database, 
       r.avg_running_sessions,
       d.utilization_limit,
       d.shares, 
       d.parallel_server_limit,
       d.comments
  FROM dba_cdb_rsrc_plan_directives d, v$containers c, v$rsrcmgrmetric r
 WHERE 1 = 1
   AND d.comments LIKE '%CNT%'
   AND d.plan = 'IOD_CDB_PLAN'
   AND d.pluggable_database <> 'CDB$ROOT'
   AND d.mandatory = 'NO'
   AND d.status IS NULL
   AND d.directive_type = 'PDB'
   AND c.name(+) = d.pluggable_database
   AND c.con_id(+) > 2
   AND r.con_id(+) = c.con_id
   AND r.consumer_group_name(+) = 'OTHER_GROUPS'
 ORDER BY
       d.pluggable_database
/
