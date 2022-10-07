SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
--
COL pdb_name FOR A30;
COL table_name FOR A30
COL num_rows FOR 999,999,999,990;
--
WITH
big_tables AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       con_id, table_name, num_rows
  FROM cdb_tables
 WHERE table_name IN ('STEPINSTANCES', 'HISTORICALASSIGNMENT', 'WORKFLOWIDEMPOTENCY', 'WORKFLOWINSTANCES', 'LEASES', 'LEASEDECORATORS', 'WORKFLOWINSTANCESINDEX', 'FUTUREWORK')
   AND num_rows > POWER(10, 6)
   AND ROWNUM >= 1
)
SELECT /*+ OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       '|' AS "|", t.num_rows, c.name AS pdb_name, t.table_name
  FROM big_tables t, v$containers c
 WHERE c.con_id = t.con_id
 ORDER BY t.num_rows DESC, c.name
/

