-- COL dummy NOPRI;
COL pdb_name FOR A30 TRUNC;
COL owner FOR A30 TRUNC;
COL table_name FOR A30 TRUNC;
COL tablespace_name FOR A30 TRUNC;
COL total_MB NEW_V total_MB FOR 99,999,990.000 HEA 'Total MB';
COL table_MB NEW_V table_MB FOR 99,999,990.000 HEA 'Table MB';
COL indexes_MB NEW_V indexes_MB FOR 99,999,990.000 HEA 'Index(es) MB';
COL lobs_MB NEW_V lobs_MB FOR 99,999,990.000 HEA 'Lob(s) MB';
COL est_data_MB FOR 99,999,990.000 HEA 'Est Data MB';
COL tabs FOR 9990;
COL lobs FOR 9990;
COL idxs FOR 9990;
COL num_rows FOR 999,999,999,990;
COL avg_row_len FOR 999,999,990;
COL last_analyzed FOR A19;
--
WITH
tables AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       s.owner,
       s.segment_name table_name,
       s.tablespace_name,
       SUM(s.bytes) bytes
  FROM cdb_segments s,
       cdb_users u,
       v$containers c
 WHERE 1 = 1
   AND s.segment_type LIKE 'TABLE%'
  --  AND s.owner NOT LIKE 'C##%'
   AND s.segment_name = COALESCE('&&specific_table.', s.segment_name)
   AND u.con_id = s.con_id
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
   AND c.con_id = s.con_id
 GROUP BY
       c.name,
       s.owner,
       s.segment_name,
       s.tablespace_name
),
dtables AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       t.owner,
       t.table_name,
       t.num_rows,
       t.avg_row_len,
       t.last_analyzed,
       t.tablespace_name
  FROM cdb_tables t,
       cdb_users u,
       v$containers c
 WHERE 1 = 1
  --  AND t.owner NOT LIKE 'C##%'
   AND u.con_id = t.con_id
   AND u.username = t.owner
   AND u.oracle_maintained = 'N'
   AND c.con_id = t.con_id
),
indexes AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       s.owner,
       i.table_name,
       SUM(s.bytes) bytes,
       COUNT(DISTINCT s.segment_name) cnt
  FROM cdb_segments s,
       cdb_users u,
       v$containers c,
       cdb_indexes i
 WHERE 1 = 1
   AND s.segment_type LIKE '%INDEX%'
  --  AND s.owner NOT LIKE 'C##%'
   AND u.con_id = s.con_id
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
   AND c.con_id = s.con_id
   AND i.con_id = s.con_id
   AND i.owner = s.owner
   AND i.index_name = s.segment_name
 GROUP BY
       c.name,
       s.owner,
       i.table_name
),
lobs AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       c.name pdb_name,
       s.owner,
       l.table_name,
       SUM(s.bytes) bytes,
       COUNT(DISTINCT s.segment_name) cnt
  FROM cdb_segments s,
       cdb_users u,
       v$containers c,
       cdb_lobs l
 WHERE 1 = 1
   AND s.segment_type LIKE 'LOB%'
  --  AND s.owner NOT LIKE 'C##%'
   AND s.segment_type <> 'LOBINDEX'
   AND u.con_id = s.con_id
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
   AND c.con_id = s.con_id
   AND l.con_id = s.con_id
   AND l.owner = s.owner
   AND l.segment_name = s.segment_name
 GROUP BY
       c.name,
       s.owner,
       l.table_name
)
SELECT -- NULL dummy,
       t.owner,
       t.table_name,
       NVL(d.tablespace_name, t.tablespace_name) AS tablespace_name,
       (NVL(t.bytes,0)+NVL(i.bytes,0)+NVL(l.bytes,0))/POWER(10,6) total_MB,
       NVL(t.bytes,0)/POWER(10,6) table_MB,
       NVL(l.bytes,0)/POWER(10,6) lobs_MB,
       NVL(i.bytes,0)/POWER(10,6) indexes_MB,
       1 tabs,
       NVL(l.cnt,0) lobs,
       NVL(i.cnt,0) idxs,
       NVL(d.num_rows,0) num_rows,
       NVL(d.avg_row_len,0) avg_row_len,
       NVL(d.num_rows*d.avg_row_len,0)/POWER(10,6) est_data_MB,
       d.last_analyzed,
       t.pdb_name
  FROM tables t,
       dtables d,
       indexes i,
       lobs l
 WHERE d.pdb_name(+) = t.pdb_name
   AND d.owner(+) = t.owner
   AND d.table_name(+) = t.table_name
   AND i.pdb_name(+) = t.pdb_name
   AND i.owner(+) = t.owner
   AND i.table_name(+) = t.table_name
   AND l.pdb_name(+) = t.pdb_name
   AND l.owner(+) = t.owner
   AND l.table_name(+) = t.table_name
 ORDER BY
       &&order_by.
 FETCH FIRST &&fetch_first_N_rows. ROWS ONLY
/