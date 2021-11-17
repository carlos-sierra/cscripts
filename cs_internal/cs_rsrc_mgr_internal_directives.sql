--
BREAK ON mandatory SKIP PAGE DUP;
COMPUTE SUM LABEL 'Total' OF avg_running_sessions running_sessions_limit utilization_limit ON mandatory;
COL mandatory NOPRI;
--
PRO
PRO PDBs Directives (v$rsrcmgrmetric and dba_cdb_rsrc_plan_directives)
PRO ~~~~~~~~~~~~~~~
SELECT d.pluggable_database, 
       r.avg_running_sessions,
       LEAST(r.running_sessions_limit, ROUND(&&cs_cpu_count. * d.utilization_limit / 100, 1)) AS running_sessions_limit,
       d.utilization_limit,
       d.shares, 
       d.parallel_server_limit,
       d.comments,
       d.mandatory,
       d.directive_type
  FROM dba_cdb_rsrc_plan_directives d, v$containers c, v$rsrcmgrmetric r
 WHERE d.plan = '&&resource_manager_plan.'
   AND '&&cs_con_name.' IN ('CDB$ROOT', d.pluggable_database)
   AND c.name = d.pluggable_database
   AND c.con_id > 2
   AND r.con_id(+) = c.con_id
   AND r.consumer_group_name(+) = 'OTHER_GROUPS'
 ORDER BY
       d.mandatory DESC,
       d.pluggable_database
/
--
CLEAR BREAK COMPUTE;
--