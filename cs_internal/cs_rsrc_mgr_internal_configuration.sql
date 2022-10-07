--
COL mandatory PRI;
SET FEED ON;
--
PRO
PRO PDBs Configuration (&&cs_tools_schema..rsrc_mgr_pdb_config)
PRO ~~~~~~~~~~~~~~~~~~
SELECT pdb_name AS pluggable_database,
       utilization_limit,
       shares,
       parallel_server_limit,
       TO_CHAR(begin_date, '&&cs_datetime_full_format.') AS begin_date,
       TO_CHAR(end_date, '&&cs_datetime_full_format.') AS end_date,
       reference
  FROM &&cs_tools_schema..rsrc_mgr_pdb_config
 WHERE plan = '&&resource_manager_plan.'
   AND '&&cs_con_name.' IN ('CDB$ROOT', pdb_name)
 ORDER BY
       pdb_name
/
--
SET FEED OFF;
--
