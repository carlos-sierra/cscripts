SET HEA ON LIN 1000 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;

COL pdb_name FOR A30;
COL owner FOR A30;
COL table_name FOR A30;

BREAK ON pdb_name SKIP 1 ON owner ON table_name;

SELECT pdb_name,
       owner,
       table_name,
       TRUNC(last_analyzed) last_analyzed,
       SUM(inserts)
  FROM c##iod.tab_modifications_hist
 WHERE owner <> 'SYS'
   AND table_name <> 'KIEVGCEVENTS_PART'
   AND last_analyzed > TRUNC(SYSDATE)
 GROUP BY
       pdb_name,
       owner,
       table_name,
       TRUNC(last_analyzed)
HAVING SUM(inserts) > 0
   AND SUM(deletes) = 0
 ORDER BY
       pdb_name,
       owner,
       table_name
/

