--
-- IAD AD1 COMPUTE IOD03A1 iod-db-01045.node.ad1.us-ashburn-1
--
COL buffer_hit_ratio FOR 990.000;
COL pdb_name FOR A30 TRUNC;
--
SELECT 100 * (SUM(s.delta_buffer_gets) - SUM(s.delta_disk_reads) - SUM(s.delta_direct_reads)) / SUM(s.delta_buffer_gets) AS buffer_hit_ratio
  FROM v$sqlstats s
 WHERE s.sql_text LIKE '/* getValues%'
/
--
SELECT 100 * (SUM(s.delta_buffer_gets) - SUM(s.delta_disk_reads) - SUM(s.delta_direct_reads)) / SUM(s.delta_buffer_gets) AS buffer_hit_ratio,
       c.name AS pdb_name
  FROM v$sqlstats s, v$containers c
 WHERE s.sql_text LIKE '/* getValues%'
   AND c.con_id = s.con_id
 GROUP BY c.name
HAVING SUM(s.delta_buffer_gets) > 0
 ORDER BY c.name 
/
--
BUFFER_HIT_RATIO
----------------
	      94.785
--
BUFFER_HIT_RATIO PDB_NAME
---------------- ------------------------------
	      94.785 COMPUTE