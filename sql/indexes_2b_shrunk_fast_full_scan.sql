----------------------------------------------------------------------------------------
--
-- File name:   indexes_2b_shrunk_fast_full_scan.sql
--
--              *** Requires Oracle Diagnostics Pack License ***
--
-- Purpose:     List of candidate indexes to be shrunk (rebuild online), if:
--              1. they are larger than a certain MB threshold; and
--              2. space savings is larger than a certain % threshold; and
--              3. they have been recently referenced by an index full scan operation
--
-- Author:      Carlos Sierra
--
-- Version:     2017/07/14
--
-- Usage:       Execute on PDB
--
-- Example:     @indexes_2b_shrunk_fast_full_scan.sql
--
-- Notes:       Execute connected into a PDB.
--              Consider then:
--              ALTER INDEX [schema.]index REBUILD ONLINE;
--
--              *** Requires Oracle Diagnostics Pack License ***
--
---------------------------------------------------------------------------------------

-- select only those indexes with current size (as per cbo stats) greater than 10MB
VAR minimum_size_mb NUMBER;
EXEC :minimum_size_mb := 10;
-- select only those indexes with an estimated space saving percent greater than 25%
VAR savings_percent NUMBER;
EXEC :savings_percent := 25;
-- select only those indexes if recently referenced by an INDEX FULL SCAN operation
VAR only_if_on_recent_full_scans CHAR(1);
EXEC :only_if_on_recent_full_scans := 'Y';
-- have Oracle Diagnostics Pack License
VAR diagnostics_pack_license CHAR(1);
EXEC :diagnostics_pack_license := 'Y';

SET SERVEROUT ON ECHO OFF FEED OFF VER OFF TAB OFF LINES 300;

COL report_date NEW_V report_date;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24-MI-SS') report_date FROM DUAL;
SPO /tmp/indexes_2b_shrunk_fast_full_scan_&&report_date..txt;

DECLARE
  l_used_bytes  NUMBER;
  l_alloc_bytes NUMBER;
  l_percent     NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('PDB: '||SYS_CONTEXT('USERENV', 'CON_NAME'));
  DBMS_OUTPUT.PUT_LINE('---');
  DBMS_OUTPUT.PUT_LINE(
    RPAD('TABLE_NAME', 30)||' '||
    RPAD('OWNER.INDEX_NAME', 35)||' '||
    LPAD('SAVING %', 10)||' '||
    LPAD('CURRENT SIZE', 20)||' '||
    LPAD('ESTIMATED SIZE', 20)||'  '||
    RPAD('COMMAND', 75));
  DBMS_OUTPUT.PUT_LINE(
    RPAD('-', 30, '-')||' '||
    RPAD('-', 35, '-')||' '||
    LPAD('-', 10, '-')||' '||
    LPAD('-', 20, '-')||' '||
    LPAD('-', 20, '-')||'  '||
    RPAD('-', 75, '-'));
  FOR i IN (WITH 
            candidates_as_per_stats AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   x.table_name, x.owner, x.index_name, 
                   SUM(s.leaf_blocks) * TO_NUMBER(p.value) index_size
              FROM dba_ind_statistics s, dba_indexes x, dba_users u, v$parameter p
             WHERE u.oracle_maintained = 'N'
               AND x.owner = u.username
               AND x.tablespace_name NOT IN ('SYSTEM','SYSAUX')
               AND x.index_type LIKE '%NORMAL%'
               AND x.table_type = 'TABLE'
               AND x.status = 'VALID'
               AND x.temporary = 'N'
               AND x.dropped = 'NO'
               AND x.visibility = 'VISIBLE'
               AND x.segment_created = 'YES'
               AND x.orphaned_entries = 'NO'
               AND p.name = 'db_block_size'
               AND s.owner = x.owner
               AND s.index_name = x.index_name
             GROUP BY
                   x.table_name, x.owner, x.index_name, p.value
             HAVING
                   SUM(s.leaf_blocks) * TO_NUMBER(p.value) > :minimum_size_mb * POWER(2,20)
             ),
             snap AS (
             SELECT /*+ MATERIALIZE NO_MERGE */
                    dbid, MIN(snap_id) min_snap_id
               FROM dba_hist_snapshot
              WHERE :diagnostics_pack_license = 'Y'
                AND :only_if_on_recent_full_scans = 'Y'
                AND dbid = (SELECT dbid FROM v$database)
                AND end_interval_time > SYSDATE - 7 /* only last 7 days */
              GROUP BY
                    dbid
             ),
             awr_plans AS (
             SELECT /*+ MATERIALIZE NO_MERGE */
                    UNIQUE hist.dbid, hist.sql_id, hist.plan_hash_value
               FROM snap, dba_hist_sqlstat hist
              WHERE :diagnostics_pack_license = 'Y'
                AND :only_if_on_recent_full_scans = 'Y'
                AND hist.dbid = snap.dbid
                AND hist.snap_id >= snap.min_snap_id
             ),
             referenced_by_fast_full_scan AS (
             SELECT /*+ MATERIALIZE NO_MERGE */
                    object_owner, object_name
               FROM v$sql_plan
              WHERE :only_if_on_recent_full_scans = 'Y'
                AND operation = 'INDEX'
                AND options IN ('FULL SCAN', 'FAST FULL SCAN', 'SAMPLE FAST FULL SCAN')
                AND object_owner <> 'SYS'
              GROUP BY
                    object_owner, object_name
              UNION
             SELECT /*+ MATERIALIZE NO_MERGE */
                    p.object_owner, p.object_name
               FROM awr_plans h, dba_hist_sql_plan p
              WHERE :diagnostics_pack_license = 'Y'
                AND :only_if_on_recent_full_scans = 'Y'
                AND p.dbid = h.dbid
                AND p.sql_id = h.sql_id
                AND p.plan_hash_value = h.plan_hash_value
                AND p.operation = 'INDEX'
                AND p.options IN ('FULL SCAN', 'FAST FULL SCAN', 'SAMPLE FAST FULL SCAN')
                AND p.object_owner <> 'SYS'
              GROUP BY
                    p.object_owner, p.object_name
             )
             SELECT c.table_name, c.owner, c.index_name, c.index_size, 
                    REPLACE(DBMS_METADATA.GET_DDL('INDEX',c.index_name,c.owner),CHR(10),CHR(32)) index_ddl
               FROM candidates_as_per_stats c
              WHERE :only_if_on_recent_full_scans <> 'Y' 
                 OR (c.owner, c.index_name) IN (SELECT r.object_owner, r.object_name FROM referenced_by_fast_full_scan r)         
             ORDER BY
                   c.index_size DESC)
  LOOP
    DBMS_SPACE.CREATE_INDEX_COST(i.index_ddl,l_used_bytes,l_alloc_bytes);
    IF i.index_size * (100 - :savings_percent) / 100 > l_alloc_bytes THEN 
      l_percent := 100 * (i.index_size - l_alloc_bytes) / i.index_size;
      DBMS_OUTPUT.PUT_LINE(
        RPAD(i.table_name, 30)||' '||
        RPAD(i.owner||'.'||i.index_name, 35)||' '||
        LPAD(TO_CHAR(ROUND(l_percent, 1), '990.0')||' % ', 10)||' '||
        LPAD(TO_CHAR(ROUND(i.index_size / POWER(2,20), 1), '999,999,990.0')||' MB', 20)||' '||
        LPAD(TO_CHAR(ROUND(l_alloc_bytes / POWER(2,20), 1), '999,999,990.0')||' MB', 20)||'  '||
        RPAD('ALTER INDEX '||LOWER(i.owner||'.'||i.index_name)||' REBUILD ONLINE;', 75));
    END IF;
  END LOOP;
END;
/

SPO OFF;
