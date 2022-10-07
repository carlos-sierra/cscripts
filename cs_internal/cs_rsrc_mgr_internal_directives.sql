--
COL plan FOR A25;
BREAK ON plan SKIP PAGE DUP;
COMPUTE SUM LABEL 'Total' OF utilization_limit shares parallel_server_limit ON plan;
--
PRO
PRO Directives other than &&resource_manager_plan. (dba_cdb_rsrc_plan_directives)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT d.plan,
       d.pluggable_database, 
       d.utilization_limit,
       d.shares, 
       d.parallel_server_limit,
       d.comments,
       d.mandatory,
       d.status,
       d.directive_type
  FROM dba_cdb_rsrc_plan_directives d, v$containers c
 WHERE 1 = 1
   AND ((d.plan <> '&&resource_manager_plan.') OR (d.plan = '&&resource_manager_plan.' AND d.directive_type <> 'PDB'))
   AND '&&cs_con_name.' IN ('CDB$ROOT', d.pluggable_database)
   AND c.name(+) = d.pluggable_database
   AND c.con_id(+) > 2
 ORDER BY
       d.plan,
       d.mandatory DESC,
       d.pluggable_database
/
--
BREAK ON REPORT;
COMPUTE SUM LABEL 'Total' OF avg_running_sessions running_sessions_limit utilization_limit shares parallel_server_limit ON REPORT;
PRO
PRO &&resource_manager_plan. PDBs Directives (v$rsrcmgrmetric and dba_cdb_rsrc_plan_directives)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT d.pluggable_database, 
       r.avg_running_sessions,
       LEAST(r.running_sessions_limit, ROUND(&&cs_cpu_count. * d.utilization_limit / 100, 1)) AS running_sessions_limit,
       d.utilization_limit,
       d.shares, 
       d.parallel_server_limit,
       d.comments
  FROM dba_cdb_rsrc_plan_directives d, v$containers c, v$rsrcmgrmetric r
 WHERE 1 = 1
   AND d.plan = '&&resource_manager_plan.'
   AND '&&cs_con_name.' IN ('CDB$ROOT', d.pluggable_database)
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
--
CLEAR BREAK COMPUTE;
--