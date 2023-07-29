COL pdb_name FOR A30;
SELECT c.pdb_name, bl.cnt AS bl, pr.cnt AS pr, pa.cnt AS pa
  FROM (SELECT con_id, name AS pdb_name FROM v$containers) c,
       (SELECT con_id, COUNT(*) As cnt FROM cdb_sql_plan_baselines GROUP BY con_id) bl,
       (SELECT con_id, COUNT(*) As cnt FROM cdb_sql_profiles GROUP BY con_id) pr,
       (SELECT con_id, COUNT(*) As cnt FROM cdb_sql_patches GROUP BY con_id) pa
 WHERE bl.con_id = c.con_id
   AND pr.con_id = c.con_id
   AND pa.con_id = c.con_id
 ORDER BY
       c.pdb_name
/