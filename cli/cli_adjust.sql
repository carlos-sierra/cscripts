
UPDATE C##IOD.pdb_allocation_config SET max_pdbs = 200 WHERE id = 1 AND (max_pdbs IS NULL OR max_pdbs <> 200)
/
UPDATE C##IOD.pdb_allocation_config SET fs_u02_util_perc_max = 85 WHERE id = 1 AND (fs_u02_util_perc_max IS NULL OR fs_u02_util_perc_max <> 85)
/
COMMIT
/
