--
COL mandatory PRI;
SET FEED ON;
--
PRO
PRO PDBs Configuration (CDB$ROOT c##iod.rsrc_mgr_pdb_config)
PRO ~~~~~~~~~~~~~~~~~~
SELECT pdb_name pluggable_database,
       utilization_limit,
       shares,
       parallel_server_limit,
       TO_CHAR(end_date, '&&cs_datetime_full_format.') end_date,
       reference
  FROM c##iod.rsrc_mgr_pdb_config
 WHERE plan = '&&resource_manager_plan.'
 ORDER BY
       pdb_name
/
--
SET FEED OFF;
--
