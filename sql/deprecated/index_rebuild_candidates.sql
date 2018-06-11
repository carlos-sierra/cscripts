SET SERVEROUT ON;

DEF 1 = 'c##iod';

DECLARE
  l_report_only VARCHAR2(1) := 'N';
  l_only_if_ref_by_full_scans VARCHAR2(1) := 'Y';
  l_min_size_mb NUMBER := 10;
  l_min_savings_perc NUMBER := 94;
  l_sleep_seconds NUMBER := 0;
  l_savings_percent NUMBER;
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows INTEGER;
  l_used_bytes NUMBER;
  l_alloc_bytes NUMBER;
  l_estimated_size_mbs_after NUMBER;
  l_blocks_after NUMBER;
  l_index_count NUMBER := 0;
  l_size_mbs_before NUMBER := 0;
  l_size_mbs_after NUMBER := 0;
  l_return NUMBER;
  l_index_rebuild_hist_rec &&1..index_rebuild_hist%ROWTYPE;
  --
  PROCEDURE insert_index_rebuild_hist 
  IS PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO &&1..index_rebuild_hist VALUES l_index_rebuild_hist_rec;
    COMMIT;
  END insert_index_rebuild_hist;
BEGIN
  FOR i IN (WITH
            indexes AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   i.con_id, 
                   i.owner,
                   i.index_name,
                   i.tablespace_name
              FROM cdb_indexes i
             WHERE i.owner <> 'SYS'
               AND i.index_type LIKE CHR(37)||'NORMAL'||CHR(37)
               AND i.table_owner <> 'SYS'
               AND i.table_name <> 'KIEVTRANSACTIONS' -- As long as KIEV application does a LOCK TABLE IN EXCLUSIVE MODE, exclude its indexes!
               AND i.tablespace_name NOT IN ('SYSTEM','SYSAUX')
               AND i.table_type = 'TABLE'
               AND i.compression = 'DISABLED'
               AND i.status = 'VALID'
               AND i.partitioned = 'NO'
               AND i.temporary = 'N'
               AND i.dropped = 'NO'
               AND i.visibility = 'VISIBLE'
               AND i.segment_created = 'YES'
            ),
            tablespaces AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   t.con_id,
                   t.tablespace_name,
                   t.block_size
              FROM cdb_tablespaces t
             WHERE t.status = 'ONLINE'
               AND t.contents = 'PERMANENT'
            ),
            users AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   u.con_id,
                   u.username
              FROM cdb_users u
             WHERE u.oracle_maintained = 'N'
            ),
            segments AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   s.con_id,
                   s.owner,
                   s.segment_name,
                   s.tablespace_name,
                   s.blocks
              FROM cdb_segments s
             WHERE s.segment_type = 'INDEX'
            ),
            containers AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   c.con_id,
                   c.name pdb_name
              FROM v$containers c
             WHERE c.open_mode = 'READ WRITE'
            ),
            rebuild_candidate AS (
            SELECT /*+ MATERIALIZE NO_MERGE ORDERED USE_HASH(i t u s c) */
                   i.con_id, 
                   c.pdb_name,
                   i.owner,
                   i.index_name,
                   i.tablespace_name,
                   t.block_size,
                   (s.blocks * t.block_size / POWER(2, 20)) size_mbs_seg
              FROM indexes i,
                   tablespaces t,
                   users u,
                   segments s,
                   containers c
             WHERE t.con_id = i.con_id
               AND t.tablespace_name = i.tablespace_name
               AND u.con_id = i.con_id
               AND u.username = i.owner
               AND s.con_id = i.con_id
               AND s.owner = i.owner
               AND s.segment_name = i.index_name
               AND s.tablespace_name = i.tablespace_name
               AND s.blocks * t.block_size / POWER(2, 20) > l_min_size_mb 
               AND c.con_id = i.con_id
            ),
            full_scan AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   p.con_id,
                   p.object_owner owner, 
                   p.object_name index_name,
                   'Y' full_scan
              FROM v$sql_plan p
             WHERE p.object_owner <> 'SYS'
               AND p.operation = 'INDEX'
               AND p.options IN ('FULL SCAN', 'FAST FULL SCAN')
             GROUP BY
                   p.con_id,
                   p.object_owner, 
                   p.object_name
            )
            SELECT rc.con_id, 
                   rc.pdb_name,
                   rc.owner,
                   rc.index_name,
                   rc.tablespace_name,
                   rc.block_size,
                   rc.size_mbs_seg,
                   NVL(fs.full_scan, 'N') full_scan
              FROM rebuild_candidate rc,
                   full_scan fs
             WHERE fs.con_id(+) = rc.con_id
               AND fs.owner(+) = rc.owner
               AND fs.index_name(+) = rc.index_name
             ORDER BY
                   MOD(rc.size_mbs_seg, 10)) -- randomize index selection
  LOOP
    l_index_rebuild_hist_rec := NULL;
    l_index_rebuild_hist_rec.pdb_name := i.pdb_name;
    l_index_rebuild_hist_rec.owner := i.owner;
    l_index_rebuild_hist_rec.index_name := i.index_name;
    l_index_rebuild_hist_rec.tablespace_name := i.tablespace_name;
    l_index_rebuild_hist_rec.full_scan := i.full_scan;
    l_index_rebuild_hist_rec.error_message := NULL;
    l_index_rebuild_hist_rec.size_mbs_before := i.size_mbs_seg;
    l_index_rebuild_hist_rec.size_mbs_after := NULL;
    l_index_rebuild_hist_rec.snap_time := SYSDATE;
    l_index_rebuild_hist_rec.con_id := i.con_id;  
    --
    IF l_index_rebuild_hist_rec.full_scan = 'Y' OR l_only_if_ref_by_full_scans = 'N' THEN
      DBMS_OUTPUT.PUT_LINE('pdb:'||l_index_rebuild_hist_rec.pdb_name||'('||l_index_rebuild_hist_rec.con_id||'). idx:'||l_index_rebuild_hist_rec.owner||'.'||l_index_rebuild_hist_rec.index_name||'. ifs:'||l_index_rebuild_hist_rec.full_scan||'.');
      --
      l_statement := 
      q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
      q'[DBMS_SPACE.CREATE_INDEX_COST(REPLACE(DBMS_METADATA.GET_DDL('INDEX',:index_name,:owner),CHR(10),CHR(32)),:used_bytes,:alloc_bytes); ]'||CHR(10)||
      q'[COMMIT; END;]';
      l_cursor_id := DBMS_SQL.OPEN_CURSOR;
      BEGIN
        DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_index_rebuild_hist_rec.pdb_name);
        DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':index_name', value => l_index_rebuild_hist_rec.index_name);
        DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':owner', value => l_index_rebuild_hist_rec.owner);
        DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':used_bytes', value => l_used_bytes);
        DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':alloc_bytes', value => l_alloc_bytes);
        l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
        DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':used_bytes', value => l_used_bytes);
        DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':alloc_bytes', value => l_alloc_bytes);
      EXCEPTION
        WHEN OTHERS THEN
          l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** DBMS_SPACE.CREATE_INDEX_COST';
          insert_index_rebuild_hist;
          DBMS_OUTPUT.PUT_LINE(l_index_rebuild_hist_rec.error_message);
          DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
          RAISE;
      END;
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      --
      l_estimated_size_mbs_after := l_alloc_bytes / POWER(2, 20);
      l_savings_percent := ROUND(100 * (l_index_rebuild_hist_rec.size_mbs_before - l_estimated_size_mbs_after) / l_index_rebuild_hist_rec.size_mbs_before);
      DBMS_OUTPUT.PUT_LINE('before:'||l_index_rebuild_hist_rec.size_mbs_before||'MBs. estimate:'||l_estimated_size_mbs_after||'MBs. savings:'||l_savings_percent||'%.');
      --
      IF l_savings_percent > l_min_savings_perc AND l_report_only = 'N' THEN
        IF l_index_count > 0 THEN
          DBMS_LOCK.SLEEP(l_sleep_seconds);
        END IF; -- l_index_count > 0
        -- 
        l_statement := 
        q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
        q'[:return := DBMS_LOCK.REQUEST(id=>666,lockmode=>DBMS_LOCK.X_MODE,timeout=>0,release_on_commit=>FALSE); ]'||CHR(10)||
        q'[COMMIT; END;]';
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        BEGIN
          DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_index_rebuild_hist_rec.pdb_name);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':return', value => l_return);
          l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
          DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':return', value => l_return);
        EXCEPTION
          WHEN OTHERS THEN
            l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** DBMS_LOCK.REQUEST';
            insert_index_rebuild_hist;
            DBMS_OUTPUT.PUT_LINE(l_index_rebuild_hist_rec.error_message);
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        IF l_return > 0 THEN -- time to kill
          l_index_rebuild_hist_rec.error_message := '*** KILLED ***';
          insert_index_rebuild_hist;
          DBMS_OUTPUT.PUT_LINE(l_index_rebuild_hist_rec.error_message);
          EXIT;
        END IF; -- l_return > 0
        -- 
        l_statement := 
        q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
        q'[:return := DBMS_LOCK.RELEASE(id=>666); ]'||CHR(10)||
        q'[COMMIT; END;]';
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        BEGIN
          DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_index_rebuild_hist_rec.pdb_name);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':return', value => l_return);
          l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
          DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':return', value => l_return);
        EXCEPTION
          WHEN OTHERS THEN
            l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** DBMS_LOCK.RELEASE';
            insert_index_rebuild_hist;
            DBMS_OUTPUT.PUT_LINE(l_index_rebuild_hist_rec.error_message);
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        IF l_return > 0 THEN -- time to kill
          l_index_rebuild_hist_rec.error_message := '*** KILLED ***';
          insert_index_rebuild_hist;
          DBMS_OUTPUT.PUT_LINE(l_index_rebuild_hist_rec.error_message);
          EXIT;
        END IF; -- l_return > 0
        --
        l_statement := 'ALTER INDEX '||LOWER(l_index_rebuild_hist_rec.owner)||'.'||LOWER(l_index_rebuild_hist_rec.index_name)||' REBUILD ONLINE';
        DBMS_OUTPUT.PUT_LINE(l_statement);
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        DECLARE
          maximum_key_length EXCEPTION;
          PRAGMA EXCEPTION_INIT(maximum_key_length, -01450); -- ORA-01450: maximum key length (string) exceeded
        BEGIN
          DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_index_rebuild_hist_rec.pdb_name);
        EXCEPTION
          WHEN maximum_key_length THEN
            l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** ALTER INDEX';
            insert_index_rebuild_hist;
            DBMS_OUTPUT.PUT_LINE(l_index_rebuild_hist_rec.error_message);
          WHEN OTHERS THEN
            l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** ALTER INDEX';
            insert_index_rebuild_hist;
            DBMS_OUTPUT.PUT_LINE(l_index_rebuild_hist_rec.error_message);
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        l_statement := 'SELECT blocks FROM dba_segments WHERE owner = :owner AND segment_name = :segment_name AND segment_type = ''INDEX''';
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        BEGIN
          DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_index_rebuild_hist_rec.pdb_name);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':owner', value => l_index_rebuild_hist_rec.owner);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':segment_name', value => l_index_rebuild_hist_rec.index_name);
          DBMS_SQL.DEFINE_COLUMN(c => l_cursor_id, position => 1, column => l_blocks_after);
          l_rows := DBMS_SQL.EXECUTE_AND_FETCH(c => l_cursor_id, exact => TRUE);
          DBMS_SQL.COLUMN_VALUE(c => l_cursor_id, position => 1, value => l_blocks_after);
        EXCEPTION
          WHEN OTHERS THEN
            l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** SELECT blocks FROM dba_segments';
            DBMS_OUTPUT.PUT_LINE(l_index_rebuild_hist_rec.error_message);
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        l_index_rebuild_hist_rec.size_mbs_after := l_blocks_after * i.block_size / POWER(2, 20);
        l_savings_percent := ROUND(100 * (l_index_rebuild_hist_rec.size_mbs_before - l_index_rebuild_hist_rec.size_mbs_after) / l_index_rebuild_hist_rec.size_mbs_before);
        DBMS_OUTPUT.PUT_LINE('before:'||l_index_rebuild_hist_rec.size_mbs_before||'MBs. after:'||l_index_rebuild_hist_rec.size_mbs_after||'MBs. savings:'||l_savings_percent||'%.');
        insert_index_rebuild_hist;
        --
        l_index_count := l_index_count + 1;
        l_size_mbs_before := l_size_mbs_before + l_index_rebuild_hist_rec.size_mbs_before;
        l_size_mbs_after := l_size_mbs_after + l_index_rebuild_hist_rec.size_mbs_after;
      END IF; -- l_savings_percent > l_min_savings_perc AND l_report_only = 'N'
    END IF; -- l_index_rebuild_hist_rec.full_scan = 'Y' OR l_only_if_ref_by_full_scans = 'N' 
  END LOOP;
  IF l_index_count > 0 THEN
    l_savings_percent := ROUND(100 * (l_size_mbs_before - l_size_mbs_after) / l_size_mbs_before);
    DBMS_OUTPUT.PUT_LINE('indexes:'||l_index_count||' before:'||l_size_mbs_before||'MBs. after:'||l_size_mbs_after||'MBs. savings:'||l_savings_percent||'%.');
  END IF;
END;
/


