----------------------------------------------------------------------------------------
--
-- File name:   iod_indexes_rebuild_online.sql
--
--              *** Requires Oracle Diagnostics Pack License ***
--
-- Purpose:     Perform index rebuild online for application indexes which:
--              1. are larger than a 10 MB threshold; and
--              2. expected space savings is larger than 25 percent threshold; and
--              3. have been recently referenced by an index full scan operation
--
-- Author:      Carlos Sierra
--
-- Version:     2017/07/25
--
-- Usage:       Execute on CDB$ROOT. OEM ready.
--
-- Example:     @iod_indexes_rebuild_online.sql
--
--              *** Requires Oracle Diagnostics Pack License ***
--
---------------------------------------------------------------------------------------
WHENEVER SQLERROR EXIT SUCCESS;
PRO
PRO Error "ORA-01476: divisor is equal to zero" just means v$database.open_mode is not "READ WRITE"
SELECT CASE open_mode WHEN 'READ WRITE' THEN open_mode ELSE TO_CHAR(1/0) END open_mode FROM v$database;

WHENEVER SQLERROR EXIT FAILURE;
SET SERVEROUT ON ECHO OFF FEED OFF VER OFF TAB OFF LINES 300;

-- select only those indexes with current size (as per cbo stats) greater than 10MB
VAR minimum_size_mb NUMBER;
EXEC :minimum_size_mb := 10;
-- select only those indexes with an estimated space saving percent greater than 25 perc
VAR savings_percent NUMBER;
EXEC :savings_percent := 25;
-- select only those indexes if recently referenced by an INDEX FULL SCAN operation
VAR referenced_by_full_scans CHAR(1);
EXEC :referenced_by_full_scans := 'Y';
-- have Oracle Diagnostics Pack License
VAR diagnostics_pack_license CHAR(1);
EXEC :diagnostics_pack_license := 'Y';

COL report_filename NEW_V report_filename;
SELECT '/tmp/iod_indexes_rebuild_online_'||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24-MI-SS') report_filename FROM DUAL;
VAR report_filename VARCHAR2(128);
EXEC :report_filename := '&&report_filename..txt';
SPO &&report_filename..txt;

VAR v_cursor CLOB;

-- PL/SQL block to be executed on each PDB
BEGIN
  :v_cursor := q'[
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
  maximum_key_length EXCEPTION;
  PRAGMA EXCEPTION_INIT(maximum_key_length, -01450);
  l_used_bytes  NUMBER;
  l_alloc_bytes NUMBER;
  l_percent_est NUMBER;
  l_percent_act NUMBER;
  l_percent_est_t NUMBER;
  l_percent_act_t NUMBER;
  l_index_size_after NUMBER;
  l_size_before_t NUMBER := 0;
  l_size_after_t NUMBER := 0;
  l_size_est_t NUMBER := 0;
  l_indexes_count_t NUMBER := 0;
  PROCEDURE put_line (p_line IN VARCHAR2)
  IS
  BEGIN
    DBMS_SYSTEM.KSDWRT(1,p_line); -- trace
    --DBMS_OUTPUT.PUT_LINE(p_line);
  END put_line;
BEGIN
  put_line(RPAD('-', 240, '-'));
  put_line('CON_NAME:'||SYS_CONTEXT('USERENV', 'CON_NAME')||' '||
           'CON_ID:'||SYS_CONTEXT('USERENV', 'CON_ID')||' '||
           'DB_NAME:'||SYS_CONTEXT('USERENV', 'DB_NAME')||' '||
           'DB_UNIQUE_NAME:'||SYS_CONTEXT('USERENV', 'DB_UNIQUE_NAME')||' '||
           'SERVER_HOST:'||SYS_CONTEXT('USERENV', 'SERVER_HOST')||' '||
           'TIME:'||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'));
  put_line(RPAD('-', 240, '-'));
  put_line(
    RPAD('TABLE_NAME', 30)||' '||
    RPAD('OWNER.INDEX_NAME', 35)||' '||
    LPAD('SIZE BEFORE REBUILD', 20)||' '||
    LPAD('ESTIMATED SIZE', 20)||'  '||
    LPAD('EST SAVING', 10)||' '||
    LPAD('SIZE AFTER REBUILD', 20)||'  '||
    LPAD('ACT SAVING', 10));
  put_line(
    RPAD('-', 30, '-')||' '||
    RPAD('-', 35, '-')||' '||
    LPAD('-', 20, '-')||' '||
    LPAD('-', 20, '-')||'  '||
    LPAD('-', 10, '-')||' '||
    LPAD('-', 20, '-')||'  '||
    LPAD('-', 10, '-'));
  FOR i IN (WITH 
            candidates_as_per_stats AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   x.table_name, x.owner, x.index_name, 
                   SUM(s.leaf_blocks) * TO_NUMBER(p.value) index_size_before
              FROM dba_ind_statistics s, dba_indexes x, dba_users u, v$parameter p
             WHERE u.oracle_maintained = 'N'
               AND x.owner = u.username
               AND x.tablespace_name NOT IN ('SYSTEM','SYSAUX')
               AND x.index_type LIKE CHR(37)||'NORMAL'||CHR(37)
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
               AND s.table_name <> 'KIEVTRANSACTIONS' -- application does LOCK TABLE IN EXCLUSIVE MODE
             GROUP BY
                   x.table_name, x.owner, x.index_name, p.value
             HAVING
                   SUM(s.leaf_blocks) * TO_NUMBER(p.value) > :b_minimum_size_mb * POWER(2,20)
             ),
             snap AS (
             SELECT /*+ MATERIALIZE NO_MERGE */
                    dbid, MIN(snap_id) min_snap_id
               FROM dba_hist_snapshot
              WHERE :b_diagnostics_pack_license = 'Y'
                AND :b_referenced_by_full_scans = 'Y'
                AND dbid = (SELECT dbid FROM v$database)
                AND end_interval_time > SYSDATE - 7 /* only last 7 days */
              GROUP BY
                    dbid
             ),
             awr_plans AS (
             SELECT /*+ MATERIALIZE NO_MERGE */
                    UNIQUE hist.dbid, hist.sql_id, hist.plan_hash_value
               FROM snap, dba_hist_sqlstat hist
              WHERE :b_diagnostics_pack_license = 'Y'
                AND :b_referenced_by_full_scans = 'Y'
                AND hist.dbid = snap.dbid
                AND hist.snap_id >= snap.min_snap_id
             ),
             referenced_by_fast_full_scan AS (
             SELECT /*+ MATERIALIZE NO_MERGE */
                    object_owner, object_name
               FROM v$sql_plan
              WHERE :b_referenced_by_full_scans = 'Y'
                AND operation = 'INDEX'
                AND options IN ('FULL SCAN', 'FAST FULL SCAN'/*, 'SAMPLE FAST FULL SCAN'*/)
                AND object_owner <> 'SYS'
              GROUP BY
                    object_owner, object_name
              UNION
             SELECT /*+ MATERIALIZE NO_MERGE */
                    p.object_owner, p.object_name
               FROM awr_plans h, dba_hist_sql_plan p
              WHERE :b_diagnostics_pack_license = 'Y'
                AND :b_referenced_by_full_scans = 'Y'
                AND p.dbid = h.dbid
                AND p.sql_id = h.sql_id
                AND p.plan_hash_value = h.plan_hash_value
                AND p.operation = 'INDEX'
                AND p.options IN ('FULL SCAN', 'FAST FULL SCAN'/*, 'SAMPLE FAST FULL SCAN'*/)
                AND p.object_owner <> 'SYS'
              GROUP BY
                    p.object_owner, p.object_name
             )
             SELECT c.table_name, c.owner, c.index_name, c.index_size_before, 
                    REPLACE(DBMS_METADATA.GET_DDL('INDEX',c.index_name,c.owner),CHR(10),CHR(32)) index_ddl
               FROM candidates_as_per_stats c
              WHERE :b_referenced_by_full_scans <> 'Y' 
                 OR (c.owner, c.index_name) IN (SELECT r.object_owner, r.object_name FROM referenced_by_fast_full_scan r)         
             ORDER BY
                   MOD(c.index_size_before, 1e4))
  LOOP
    DBMS_SPACE.CREATE_INDEX_COST(i.index_ddl,l_used_bytes,l_alloc_bytes);
    IF i.index_size_before * (100 - :b_savings_percent) / 100 > l_alloc_bytes THEN 
      l_percent_est := 100 * (i.index_size_before - l_alloc_bytes) / GREATEST(1, i.index_size_before);
      put_line(
        RPAD(i.table_name, 30)||' '||
        RPAD(i.owner||'.'||i.index_name, 35)||' '||
        LPAD(TO_CHAR(ROUND(i.index_size_before / POWER(2,20), 1), '999,999,990.0')||' MB', 20)||' '||
        LPAD(TO_CHAR(ROUND(l_alloc_bytes / POWER(2,20), 1), '999,999,990.0')||' MB', 20)||'  '||
        LPAD(TO_CHAR(ROUND(l_percent_est, 1), '990.0')||' '||CHR(37), 10));
      BEGIN
        EXECUTE IMMEDIATE('ALTER INDEX '||LOWER(i.owner||'.'||i.index_name)||' REBUILD ONLINE');
      EXCEPTION 
        WHEN maximum_key_length THEN
          put_line('*** '||SQLERRM);
          put_line('*** ALTER INDEX '||LOWER(i.owner||'.'||i.index_name)||' REBUILD ONLINE');
          put_line('*** Ref: MOS Doc ID 236329.1');
          put_line('*** Ref: https://www.pythian.com/blog/ora-01450-during-online-index-rebuild/');
          :b_x_errors_count := :b_x_errors_count + 1;
          :b_x_indexes_skipped := :b_x_indexes_skipped||LOWER(i.owner||'.'||i.index_name)||' ';
      END;
      SELECT SUM(s.leaf_blocks * TO_NUMBER(p.value))
        INTO l_index_size_after
        FROM dba_ind_statistics s, v$parameter p
       WHERE p.name = 'db_block_size'
         AND s.owner = i.owner
         AND s.index_name = i.index_name;
      l_size_before_t := l_size_before_t + i.index_size_before;
      l_size_after_t := l_size_after_t + l_index_size_after;
      l_size_est_t := l_size_est_t + l_alloc_bytes;
      l_indexes_count_t := l_indexes_count_t + 1;
      l_percent_act := 100 * (i.index_size_before - l_index_size_after) / GREATEST(1, i.index_size_before);
      :b_x_size_before := :b_x_size_before + i.index_size_before;
      :b_x_size_after := :b_x_size_after + l_index_size_after;
      :b_x_indexes_count := :b_x_indexes_count + 1;
      put_line(
        RPAD(i.table_name, 30)||' '||
        RPAD(i.owner||'.'||i.index_name, 35)||' '||
        LPAD(TO_CHAR(ROUND(i.index_size_before / POWER(2,20), 1), '999,999,990.0')||' MB', 20)||' '||
        LPAD(TO_CHAR(ROUND(l_alloc_bytes / POWER(2,20), 1), '999,999,990.0')||' MB', 20)||'  '||
        LPAD(TO_CHAR(ROUND(l_percent_est, 1), '990.0')||' '||CHR(37), 10)||' '||
        LPAD(TO_CHAR(ROUND(l_index_size_after / POWER(2,20), 1), '999,999,990.0')||' MB', 20)||'  '||
        LPAD(TO_CHAR(ROUND(l_percent_act, 1), '990.0')||' '||CHR(37), 10));
    END IF;
  END LOOP;
  l_percent_est_t := 100 * (l_size_before_t - l_size_est_t) / GREATEST(1, l_size_before_t);
  l_percent_act_t := 100 * (l_size_before_t - l_size_after_t) / GREATEST(1, l_size_before_t);
  put_line(RPAD('-', 240, '-'));
  put_line(
    RPAD('TOTAL', 30)||' '||
    RPAD(SYS_CONTEXT('USERENV', 'CON_NAME'), 35)||' '||
    LPAD(TO_CHAR(ROUND(l_size_before_t / POWER(2,20), 1), '999,999,990.0')||' MB', 20)||' '||
    LPAD(TO_CHAR(ROUND(l_size_est_t / POWER(2,20), 1), '999,999,990.0')||' MB', 20)||'  '||
    LPAD(TO_CHAR(ROUND(l_percent_est_t, 1), '990.0')||' '||CHR(37), 10)||' '||
    LPAD(TO_CHAR(ROUND(l_size_after_t / POWER(2,20), 1), '999,999,990.0')||' MB', 20)||'  '||
    LPAD(TO_CHAR(ROUND(l_percent_act_t, 1), '990.0')||' '||CHR(37), 10));
  put_line(RPAD('-', 240, '-'));
  COMMIT;
END;
]';
END;
/

-- disable messages such as "WARNING: kcbz_log_block_read - failed to record BRR for 14/4257 (0x4010a1) SCN 0x0.73aee SEQ 2" produced as per bug 18105512
ALTER SESSION SET EVENTS '10741 trace name context forever, level 1';

-- write into a session trace output of this script
ALTER SESSION SET tracefile_identifier = 'iod_indexes_rebuild_online';

-- execute connected into CDB$ROOT as SYS
DECLARE
  l_cursor_id INTEGER;
  l_rows_processed INTEGER;
  l_size_before NUMBER;
  l_size_after NUMBER;
  l_indexes_count NUMBER;
  l_errors_count NUMBER;
  l_indexes_skipped VARCHAR2(32767);
  l_size_before_t NUMBER := 0;
  l_size_after_t NUMBER := 0;
  l_indexes_count_t NUMBER := 0;
  l_tracefile_name VARCHAR2(512);
  l_open_mode VARCHAR2(20);
  PROCEDURE put_line (p_line IN VARCHAR2)
  IS
  BEGIN
    DBMS_SYSTEM.KSDWRT(3,p_line); -- alert log
    DBMS_OUTPUT.PUT_LINE(p_line); -- spool
  END put_line;
BEGIN
  put_line('dbe script iod_indexes_rebuild_online.sql begin');
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode = 'READ WRITE' THEN
    SELECT SUBSTR(value, 1, 512) INTO l_tracefile_name FROM v$diag_info WHERE name = 'Default Trace File';
    put_line('trace: '||l_tracefile_name);
    put_line('report: '||:report_filename);
    DBMS_OUTPUT.PUT_LINE(RPAD('*', 240, '*'));
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    FOR i IN (SELECT c.con_id, c.name con_name, d.name db_name, d.db_unique_name, i.host_name server_host
                FROM v$containers c, v$database d, v$instance i
               WHERE c.con_id <> 2 
                 AND c.open_mode = 'READ WRITE'
               ORDER BY 1)
    LOOP
      DBMS_OUTPUT.PUT_LINE('-----');
      DBMS_OUTPUT.PUT_LINE(
        'CON_NAME:'||i.con_name||' '||
        'CON_ID:'||i.con_id||' '||
        'DB_NAME:'||i.db_name||' '||
        'DB_UNIQUE_NAME:'||i.db_unique_name||' '||
        'SERVER_HOST:'||i.server_host||' '||
        'TIME:'||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'));
      DBMS_SQL.PARSE(c => l_cursor_id, statement => :v_cursor, language_flag => DBMS_SQL.NATIVE, container => i.con_name);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_minimum_size_mb', value => :minimum_size_mb);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_savings_percent', value => :savings_percent);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_referenced_by_full_scans', value => :referenced_by_full_scans);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_diagnostics_pack_license', value => :diagnostics_pack_license);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_x_size_before', value => 0);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_x_size_after', value => 0);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_x_indexes_count', value => 0);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_x_errors_count', value => 0);
      DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':b_x_indexes_skipped', value => NULL, out_value_size => 32767);
      l_rows_processed := DBMS_SQL.EXECUTE(c => l_cursor_id);
      DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':b_x_size_before', value => l_size_before);
      DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':b_x_size_after', value => l_size_after);
      DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':b_x_indexes_count', value => l_indexes_count);
      DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':b_x_errors_count', value => l_errors_count);
      DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':b_x_indexes_skipped', value => l_indexes_skipped);
      l_size_before_t := l_size_before_t + l_size_before;
      l_size_after_t := l_size_after_t + l_size_after;
      l_indexes_count_t := l_indexes_count_t + l_indexes_count;
      DBMS_OUTPUT.PUT_LINE(
        'PDB_INDEXES:'||l_indexes_count||' '||
        'PDB_BEFORE:'||TRIM(TO_CHAR(ROUND(l_size_before / POWER(2,20), 1), '999,999,990.0'))||'MB '||
        'PDB_AFTER:'||TRIM(TO_CHAR(ROUND(l_size_after / POWER(2,20), 1), '999,999,990.0'))||'MB '||
        'PDB_SAVING:'||TRIM(TO_CHAR(ROUND(100 * (l_size_before - l_size_after) / GREATEST(1, l_size_before), 1), '990.0'))||CHR(37)||' '||
        'TIME:'||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'));
      IF l_errors_count > 0 THEN
        put_line('*** dbe script iod_indexes_rebuild_online.sql error');
        put_line('*** '||l_errors_count||' index(es) with "ORA-01450: maximum key length (3215) exceeded"');
        put_line('*** skipped: '||l_indexes_skipped);
      END IF;
      DBMS_OUTPUT.PUT_LINE(
        'SO_FAR_INDEXES:'||l_indexes_count_t||' '||
        'SO_FAR_BEFORE:'||TRIM(TO_CHAR(ROUND(l_size_before_t / POWER(2,20), 1), '999,999,990.0'))||'MB '||
        'SO_FAR_AFTER:'||TRIM(TO_CHAR(ROUND(l_size_after_t / POWER(2,20), 1), '999,999,990.0'))||'MB '||
        'SO_FAR_SAVING:'||TRIM(TO_CHAR(ROUND(100 * (l_size_before_t - l_size_after_t) / GREATEST(1, l_size_before_t), 1), '990.0'))||CHR(37)||' ');
    END LOOP;
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    DBMS_OUTPUT.PUT_LINE('=====');
    DBMS_OUTPUT.PUT_LINE(
      'DB_INDEXES:'||l_indexes_count_t||' '||
      'DB_BEFORE:'||TRIM(TO_CHAR(ROUND(l_size_before_t / POWER(2,20), 1), '999,999,990.0'))||'MB '||
      'DB_AFTER:'||TRIM(TO_CHAR(ROUND(l_size_after_t / POWER(2,20), 1), '999,999,990.0'))||'MB '||
      'DB_SAVING:'||TRIM(TO_CHAR(ROUND(100 * (l_size_before_t - l_size_after_t) / GREATEST(1, l_size_before_t), 1), '990.0'))||CHR(37)||' ');
    DBMS_OUTPUT.PUT_LINE(RPAD('*', 240, '*'));
    put_line('report: '||:report_filename);
    put_line('trace: '||l_tracefile_name);
  ELSE
    put_line('normal early exit since open_mode "'||l_open_mode||'" is not "READ WRITE"');
  END IF;
  put_line('dbe script iod_indexes_rebuild_online.sql end');
END;
/

SPO OFF;

PRO spool: &&report_filename..txt

EXIT;