--
BREAK ON mandatory SKIP PAGE DUP;
COMPUTE SUM LABEL 'Total' OF utilization_limit ON mandatory;
COL mandatory NOPRI;
--
PRO
PRO PDBs Directives (CDB$ROOT dba_cdb_rsrc_plan_directives)
PRO ~~~~~~~~~~~~~~~
SELECT pluggable_database, 
       utilization_limit,
       shares, 
       parallel_server_limit,
       comments,
       mandatory,
       directive_type
  FROM dba_cdb_rsrc_plan_directives
 WHERE plan = '&&resource_manager_plan.'
 ORDER BY
       mandatory DESC,
       pluggable_database
/
--
CLEAR BREAK COMPUTE;
--