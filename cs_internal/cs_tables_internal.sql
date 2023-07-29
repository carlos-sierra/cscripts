COL owner FOR A30;
COL table_name FOR A30;
COL tablespace_name FOR A30;
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
       s.owner,
       s.segment_name AS table_name,
       MAX(s.tablespace_name) AS tablespace_name,
       SUM(s.bytes) AS bytes
  FROM dba_segments s,
       dba_users u
 WHERE s.segment_type LIKE 'TABLE%'
   AND s.owner = COALESCE('&&specific_owner.', s.owner)
   AND s.segment_name = COALESCE('&&specific_table.', s.segment_name)
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
 GROUP BY
       s.owner,
       s.segment_name
),
dtables AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       t.owner,
       t.table_name,
       t.num_rows,
       t.avg_row_len,
       t.last_analyzed,
       t.tablespace_name
  FROM dba_tables t,
       dba_users u
 WHERE u.username = t.owner
   AND u.oracle_maintained = 'N'
   AND t.owner = COALESCE('&&specific_owner.', t.owner)
   AND t.table_name = COALESCE('&&specific_table.', t.table_name)
),
indexes AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.owner,
       i.table_name,
       SUM(s.bytes) AS bytes,
       COUNT(DISTINCT s.segment_name) AS cnt
  FROM dba_segments s,
       dba_users u,
       dba_indexes i
 WHERE s.segment_type LIKE '%INDEX%'
   AND s.owner = COALESCE('&&specific_owner.', s.owner)
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
   AND u.common = 'NO'
   AND i.owner = s.owner
   AND i.index_name = s.segment_name
   AND i.table_name = COALESCE('&&specific_table.', i.table_name)
 GROUP BY
       s.owner,
       i.table_name
),
lobs AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       s.owner,
       l.table_name,
       SUM(s.bytes) AS bytes,
       COUNT(DISTINCT s.segment_name) AS cnt
  FROM dba_segments s,
       dba_users u,
       dba_lobs l
 WHERE s.segment_type LIKE 'LOB%'
   AND s.segment_type <> 'LOBINDEX'
   AND s.owner = COALESCE('&&specific_owner.', s.owner)
   AND u.username = s.owner
   AND u.oracle_maintained = 'N'
   AND l.owner = s.owner
   AND l.segment_name = s.segment_name
   AND l.table_name = COALESCE('&&specific_table.', l.table_name)
 GROUP BY
       s.owner,
       l.table_name
)
SELECT /*+ MONITOR GATHER_PLAN_STATISTICS */
       t.owner,
       t.table_name,
       NVL(d.tablespace_name, t.tablespace_name) AS tablespace_name,
       (NVL(t.bytes,0)+NVL(i.bytes,0)+NVL(l.bytes,0))/POWER(10,6) AS total_MB,
       NVL(t.bytes,0)/POWER(10,6) AS table_MB,
       NVL(l.bytes,0)/POWER(10,6) AS lobs_MB,
       NVL(i.bytes,0)/POWER(10,6) AS indexes_MB,
       1 AS tabs,
       NVL(l.cnt,0) AS lobs,
       NVL(i.cnt,0) AS idxs,
       NVL(d.num_rows,0) AS num_rows,
       NVL(d.avg_row_len,0) AS avg_row_len,
       NVL(d.num_rows*d.avg_row_len,0)/POWER(10,6) AS est_data_MB,
       d.last_analyzed
  FROM tables t,
       dtables d,
       indexes i,
       lobs l
 WHERE d.owner(+) = t.owner
   AND d.table_name(+) = t.table_name
   AND i.owner(+) = t.owner
   AND i.table_name(+) = t.table_name
   AND l.owner(+) = t.owner
   AND l.table_name(+) = t.table_name
 ORDER BY
       &&order_by.
 FETCH FIRST &&fetch_first_N_rows. ROWS ONLY
/