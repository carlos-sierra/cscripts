COL pdb_name FOR A30 TRUNC;
SELECT b.con_id, (SELECT c.name AS pdb_name FROM v$containers c WHERE c.con_id = b.con_id) AS pdb_name,
COUNT(*), SUM(CASE WHEN created < SYSDATE - 30 THEN 1 ELSE 0 END) AS old 
FROM cdb_sql_plan_baselines b
WHERE b.enabled = 'YES' AND b.accepted = 'YES'
GROUP BY b.con_id
HAVING COUNT(*) > 1000
/