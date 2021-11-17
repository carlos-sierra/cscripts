SET HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS'; 
--
COL pdb_name FOR A30 TRUNC;
COL owner FOR A30 TRUNC;
COL table_name FOR A30 TRUNC;
COL list_of_pdbs FOR A200 TRUNC;
--
-- consider only tables with more than these many rows
DEF n_rows = '500';
-- horizon where the analysis of gc is done
DEF as_of = 'SYSDATE';
-- if there has not been gc for these many hours ending on "as of" 
DEF hrs_window = '6';
-- percent of tables with gc over total tables to declare gc is happening
DEF perc_tables_gc = '95';
--
WITH
kiev AS (
SELECT /*+ MATERIALIZE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */ DISTINCT c.name AS pdb_name FROM cdb_tables t, v$containers c WHERE t.table_name = 'KIEVDATASTOREMETADATA' AND c.con_id = t.con_id
),
tables AS ( -- superset of application tables having more than n_rows
SELECT /*+ MATERIALIZE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       c.name AS pdb_name,
       t.owner,
       t.table_name,
       t.num_rows,
       t.last_analyzed
  FROM cdb_users u,
       cdb_tables t,
       v$containers c
 WHERE u.oracle_maintained = 'N'
   AND u.username NOT LIKE 'C##%'
   AND u.con_id > 2
   AND t.con_id = u.con_id
   AND t.owner = u.username
   AND t.partitioned = 'NO'
   AND t.num_rows > &&n_rows.
   AND c.con_id = u.con_id
),
modifications_hist AS ( -- modifications history for superset of application tables that have had activity
SELECT /*+ MATERIALIZE NO_MERGE */
       pdb_name,
       owner,
       table_name,
       last_analyzed,
       num_rows,
       timestamp,
       inserts,
       deletes,
       ROW_NUMBER() OVER (PARTITION BY pdb_name, owner, table_name ORDER BY CASE WHEN inserts > 0 THEN timestamp END DESC NULLS LAST) inserts_row_number,
       ROW_NUMBER() OVER (PARTITION BY pdb_name, owner, table_name ORDER BY CASE WHEN deletes > 0 THEN timestamp END DESC NULLS LAST) deletes_row_number
  FROM c##iod.dbc_tab_modifications
 WHERE truncated = 'NO'
   AND owner <> 'SYS'
   AND owner NOT LIKE 'C##%'
   AND table_name NOT LIKE 'KIEV%'
   AND updates = 0
   AND timestamp BETWEEN (&&as_of.) - ((&&hrs_window.) / 24) AND (&&as_of.)
   AND pdb_name IN (SELECT pdb_name FROM kiev)
),
modifications AS ( -- most recent inserts and most recent deletes per active application table
SELECT /*+ MATERIALIZE NO_MERGE */
       pdb_name,
       owner,
       table_name,
       MAX(CASE inserts_row_number WHEN 1 THEN timestamp END) AS inserts_timestamp,
       MAX(CASE inserts_row_number WHEN 1 THEN inserts END) AS inserts,
       MAX(CASE deletes_row_number WHEN 1 THEN timestamp END) AS deletes_timestamp,
       MAX(CASE deletes_row_number WHEN 1 THEN deletes END) AS deletes
  FROM modifications_hist
 WHERE (inserts_row_number = 1 AND inserts > 0) OR (deletes_row_number = 1 AND deletes > 0)
 GROUP BY
       pdb_name,
       owner,
       table_name
),
tables_mod AS ( -- superset of application tables having more than n_rows, including last inserts and deletes and their timestamp
SELECT /*+ MATERIALIZE NO_MERGE */
       t.pdb_name,
       t.owner,
       t.table_name,
       t.num_rows,
       t.last_analyzed,
       NULLIF(m.inserts, 0) AS inserts,
       CASE WHEN m.inserts > 0 THEN m.inserts_timestamp END AS inserts_timestamp,
       NULLIF(m.deletes, 0) AS deletes,
       CASE WHEN m.deletes > 0 THEN m.deletes_timestamp END AS deletes_timestamp
  FROM tables t,
       modifications m
 WHERE m.pdb_name(+) = t.pdb_name
   AND m.owner(+) = t.owner
   AND m.table_name(+) = t.table_name
),
active_tables_within_window AS ( -- tables with inserts or deletes within the last 6 hours
SELECT /*+ MATERIALIZE NO_MERGE */
       pdb_name,
       owner,
       table_name,
       num_rows,
       last_analyzed,
       inserts,
       CASE WHEN inserts_timestamp > (&&as_of.) - ((&&hrs_window.) / 24) THEN 1 ELSE 0 END AS inserted_in_window,
       inserts_timestamp,
       deletes,
       CASE WHEN deletes_timestamp > (&&as_of.) - ((&&hrs_window.) / 24) THEN 1 ELSE 0 END AS deleted_in_window,
       deletes_timestamp
  FROM tables_mod
 WHERE inserts_timestamp > (&&as_of.) - ((&&hrs_window.) / 24)
    OR deletes_timestamp > (&&as_of.) - ((&&hrs_window.) / 24)
)
/*****************************************************************************************************************/
SELECT pdb_name,
       owner,
       table_name,
       num_rows,
       last_analyzed,
       inserts,
       inserts_timestamp
  FROM active_tables_within_window
 WHERE inserted_in_window > 0
   AND deleted_in_window = 0
 ORDER BY
       pdb_name,
       owner,
       table_name
/