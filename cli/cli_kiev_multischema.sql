COL pdb_name FOR A30;
COL owner FOR A30;
WITH
kiev AS (
    SELECT con_id, owner,
           COUNT(*) OVER (PARTITION BY con_id) AS schema_count
      FROM cdb_tables
     WHERE table_name = 'KIEVDATASTOREMETADATA'
       AND owner NOT IN ('KIEVGCUSER', 'KAASRWUSER')
       AND ROWNUM >= 1
)
SELECT c.name AS pdb_name,
       k.owner
  FROM kiev k, v$containers c
 WHERE k.schema_count > 1
   AND c.con_id = k.con_id
 ORDER BY 1,2
/
