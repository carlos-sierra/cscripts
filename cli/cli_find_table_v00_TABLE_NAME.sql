REM cli_find_table_v00_TABLE_NAME - Find Table for given Name
SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
ALTER SESSION SET "_px_cdb_view_enabled" = FALSE;
--
COL pdb_name FOR A30 TRUNC;
COL owner FOR A30 TRUNC;
COL table_name FOR A30 TRUNC;
COL gbs FOR 999,990.000;
COL num_rows FOR 999,999,999,990;
COL blocks FOR 999,999,999,990;
COL last_analyzed FOR A19;
COL lobs FOR 9999;
COL comp_lobs FOR 999999999; 
COL dedup_lobs FOR 9999999999;
--
SELECT c.name AS pdb_name,
       t.owner,
       t.table_name,
       ROUND(t.blocks * 8192 / POWER(10,9), 3) AS GBs,
       t.partitioned,
       CASE t.partitioned WHEN 'YES' THEN (SELECT COUNT(*) FROM cdb_tab_partitions p WHERE p.con_id = t.con_id AND p.table_owner = t.owner AND p.table_name = t.table_name) END AS partitions,
       t.num_rows,
       t.blocks,
       TO_CHAR(t.last_analyzed, 'YYYY-MM-DD"T"HH24:MI:SS') last_analyzed,
       (SELECT COUNT(*) FROM cdb_indexes i WHERE i.con_id = t.con_id AND i.owner = t.owner AND i.table_name = t.table_name AND i.partitioned = 'NO') AS non_part_indexes,
       (SELECT COUNT(*) FROM cdb_indexes i WHERE i.con_id = t.con_id AND i.owner = t.owner AND i.table_name = t.table_name AND i.partitioned = 'YES') AS part_indexes,
       (SELECT COUNT(*) FROM cdb_lobs l WHERE l.con_id = t.con_id AND l.owner = t.owner AND l.table_name = t.table_name) AS lobs,
       (SELECT COUNT(*) FROM cdb_lobs l WHERE l.con_id = t.con_id AND l.owner = t.owner AND l.table_name = t.table_name AND l.compression <> 'NO') AS comp_lobs,
       (SELECT COUNT(*) FROM cdb_lobs l WHERE l.con_id = t.con_id AND l.owner = t.owner AND l.table_name = t.table_name AND l.deduplication = 'LOB') AS dedup_lobs
  FROM cdb_tables t,
       v$containers c
 WHERE t.table_name = 'SPARSE_REP_LOG'
   --AND t.partitioned = 'NO'
   --AND (SELECT COUNT(*) FROM cdb_lobs l WHERE l.con_id = t.con_id AND l.owner = t.owner AND l.table_name = t.table_name AND l.deduplication = 'LOB') > 0
   AND c.con_id = t.con_id
 ORDER BY
      c.name,
      t.owner,
       t.table_name,
       t.num_rows DESC,
       t.table_name
/
