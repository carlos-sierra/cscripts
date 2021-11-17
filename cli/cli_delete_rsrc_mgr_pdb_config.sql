SELECT * FROM c##iod.rsrc_mgr_pdb_config WHERE utilization_limit <= 12 OR utilization_limit > 32
/
DELETE c##iod.rsrc_mgr_pdb_config WHERE utilization_limit <= 12 OR utilization_limit > 32
/
COMMIT
/
