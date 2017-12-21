SELECT ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER ()) percent,
       (SELECT pdb_name FROM cdb_pdbs WHERE con_id = h.con_id) pdb_name
  FROM dba_hist_active_sess_history h
 WHERE wait_class = 'Commit' AND event = 'log file sync'
   AND snap_id BETWEEN 17644 AND 23426
   AND dbid = 1354234658
 GROUP BY
       con_id 
 ORDER BY
       1 DESC
/

/*
   PERCENT PDB_NAME
---------- --------------------
	34 CEREBROFLEETTRACKER
	13 COMPUTE
	13 WFS_TENANT_B
	13 WFS_TENANT_A
	 9 COMPUTE_WF
	 4 BLOCKSTORAGE_WF
	 4 BACKGROUND_WORKFLOW
	 3 DBAAS_WF
	 2 DBAAS_API
	 2 FLAMINGO_OPS
	 1 FLAMINGO_CTL
*/
