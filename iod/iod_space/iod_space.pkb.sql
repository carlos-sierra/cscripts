CREATE OR REPLACE PACKAGE BODY &&1..iod_space AS
/* $Header: iod_space.pkb.sql &&library_version. carlos.sierra $ */
/* ------------------------------------------------------------------------------------ */  
FUNCTION get_package_version
RETURN VARCHAR2
IS
BEGIN
  RETURN gk_package_version;
END get_package_version;
/* ------------------------------------------------------------------------------------ */  
PROCEDURE output (
  p_line       IN VARCHAR2,
  p_spool_file IN VARCHAR2 DEFAULT 'Y',
  p_alert_log  IN VARCHAR2 DEFAULT 'N'
) 
IS
BEGIN
  IF p_spool_file = 'Y' THEN
    SYS.DBMS_OUTPUT.PUT_LINE (a => p_line); -- write to spool file
  END IF;
  IF p_alert_log = 'Y' THEN
    SYS.DBMS_SYSTEM.KSDWRT(dest => 2, tst => p_line); -- write to alert log
  END IF;
END output;
/* ------------------------------------------------------------------------------------ */  
PROCEDURE table_stats_hist
IS
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_count NUMBER;
  l_max_last_analyzed DATE;
  l_high_value DATE;
BEGIN
  SELECT name, open_mode INTO l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output('*** to be executed only on DG primary ***');
    RETURN;
  END IF;
  --
  output('begin '||TO_CHAR(SYSDATE, gk_date_format));
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SPACE.table_stats_hist','TABLE_STATS_HIST');
  -- get starting point
  SELECT COUNT(*), NVL(TRUNC(MAX(last_analyzed) - (1/24), 'HH'), TRUNC(SYSDATE) - gk_table_stats_days)
    INTO l_count, l_max_last_analyzed
    FROM &&1..table_stats_hist;
  output('&&1..table_stats_hist begin count: '||l_count);
  output('start point at: '||TO_CHAR(l_max_last_analyzed, gk_date_format));
  -- main 
  MERGE /* &&1.iod_space.table_stats_hist */
  INTO &&1..table_stats_hist d
  USING (
    WITH
    s_v$containers AS (
    SELECT /*+ NO_MERGE */
           c.con_id,
           c.name pdb_name
      FROM v$containers c
     WHERE c.open_mode = 'READ WRITE'
    ),
    s_cdb_tables AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           t.owner,
           t.table_name,
           t.last_analyzed,
           t.blocks,
           t.num_rows,
           t.sample_size,
           t.avg_row_len,
           t.con_id,
           o.object_id
      FROM cdb_tables t,
           cdb_objects o
     WHERE t.last_analyzed IS NOT NULL -- partition key cannot contain nulls (redundant)
       AND t.last_analyzed > TRUNC(SYSDATE) - gk_table_stats_days -- collect up to this many days of history
       AND t.last_analyzed > l_max_last_analyzed -- no need to keep reading data that has been processed
       AND t.temporary = 'N'
       AND t.table_name NOT LIKE 'BIN$%'
       AND o.con_id = t.con_id
       AND o.owner = t.owner
       AND o.object_name = t.table_name
    ),
    s_cdb_tables_hist AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           o.owner,
           o.object_name table_name,
           h.analyzetime last_analyzed,
           h.blkcnt blocks,
           h.rowcnt num_rows,
           h.samplesize sample_size,
           h.avgrln avg_row_len,
           o.con_id,
           h.obj# object_id
      FROM CONTAINERS(sys.wri$_optstat_tab_history) h,
           cdb_objects o
     WHERE h.analyzetime IS NOT NULL -- partition key cannot contain nulls (redundant)
       AND h.analyzetime > TRUNC(SYSDATE) - gk_table_stats_days -- collect up to this many days of history
       AND h.analyzetime > l_max_last_analyzed -- no need to keep reading data that has been processed
       AND h.flags > 0
       AND o.object_name NOT LIKE 'BIN$%'
       -- AND o.con_id = h.con_id -- there is no h.con_id!
       AND o.object_id = h.obj#
       AND o.object_type = 'TABLE'
    )
    SELECT /*+ USE_HASH(t c) */
           c.pdb_name,
           t.owner,
           t.table_name,
           t.last_analyzed,
           t.blocks,
           t.num_rows,
           t.sample_size,
           t.avg_row_len,
           t.con_id,
           t.object_id
      FROM s_cdb_tables t,
           s_v$containers c
     WHERE c.con_id = t.con_id
     UNION ALL
    SELECT /*+ USE_HASH(h c) */
           c.pdb_name,
           h.owner,
           h.table_name,
           h.last_analyzed,
           h.blocks,
           h.num_rows,
           h.sample_size,
           h.avg_row_len,
           h.con_id,
           h.object_id
      FROM s_cdb_tables_hist h,
           s_v$containers c
     WHERE c.con_id = h.con_id
  ) s
  ON 
  ( d.pdb_name      = s.pdb_name      AND 
    d.owner         = s.owner         AND
    d.table_name    = s.table_name    AND
    d.last_analyzed = s.last_analyzed AND
    --d.object_id     = s.object_id     AND -- intentionally left-out, since object_id changes after a table redefinition
    d.con_id        = s.con_id -- redundant
  )
  WHEN NOT MATCHED THEN
  INSERT (
    pdb_name     ,
    owner        ,
    table_name   ,
    last_analyzed,
    blocks       ,
    num_rows     ,
    sample_size  ,
    avg_row_len  ,
    con_id       ,
    object_id    
  ) VALUES (
    s.pdb_name     ,
    s.owner        ,
    s.table_name   ,
    s.last_analyzed,
    s.blocks       ,
    s.num_rows     ,
    s.sample_size  ,
    s.avg_row_len  ,
    s.con_id       ,
    s.object_id    
  );
  --
  COMMIT;
  -- drop partitions with data older than 12 months (i.e. preserve between 12 and 13 months of history)
  FOR i IN (
    SELECT partition_name, high_value, blocks
      FROM dba_tab_partitions
     WHERE table_owner = UPPER('&&1.')
       AND table_name = 'TABLE_STATS_HIST'
     ORDER BY
           partition_name
  )
  LOOP
    EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
    output('PARTITION:'||RPAD(SUBSTR(i.partition_name, 1, 30), 32)||'HIGH_VALUE:'||TO_CHAR(l_high_value, gk_date_format)||'  BLOCKS:'||i.blocks);
    IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -12) THEN
      output('&&1..IOD_SPACE.table_stats_hist: ALTER TABLE &&1..table_stats_hist DROP PARTITION '||i.partition_name, p_alert_log => 'Y');
      EXECUTE IMMEDIATE q'[ALTER TABLE &&1..table_stats_hist SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
      EXECUTE IMMEDIATE 'ALTER TABLE &&1..table_stats_hist DROP PARTITION '||i.partition_name;
    END IF;
  END LOOP;
  -- count
  SELECT COUNT(*)
    INTO l_count
    FROM &&1..table_stats_hist;
  output('&&1..table_stats_hist end count: '||l_count);
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
  output('end '||TO_CHAR(SYSDATE, gk_date_format));
END table_stats_hist;
/* ------------------------------------------------------------------------------------ */
PROCEDURE tab_modifications_hist
IS
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_count NUMBER;
  l_max_last_analyzed DATE;
  l_high_value DATE;
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows  INTEGER;
  l_identifier_must_be_declared EXCEPTION;
  PRAGMA EXCEPTION_INIT(l_identifier_must_be_declared, -06550);
BEGIN
  SELECT name, open_mode INTO l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output('*** to be executed only on DG primary ***');
    RETURN;
  END IF;
  --
  output('begin '||TO_CHAR(SYSDATE, gk_date_format));
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SPACE.tab_modifications_hist','TAB_MODIFICATIONS_HIST');
  -- get starting point
  SELECT COUNT(*), NVL(TRUNC(MAX(last_analyzed) - (1/24), 'HH'), TRUNC(SYSDATE) - gk_table_stats_days)
    INTO l_count, l_max_last_analyzed
    FROM &&1..tab_modifications_hist;
  output('&&1..tab_modifications_hist begin count: '||l_count);
  output('start point: '||TO_CHAR(l_max_last_analyzed, gk_date_format));
  -- flush cdb_tab_modifications
  output('&&1..IOD_SPACE.tab_modifications_hist: DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO'||TO_CHAR(l_max_last_analyzed, gk_date_format), p_alert_log => 'Y');
  /* moved to calling OEM job due to ORA-06550: PLS-00201: identifier 'DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO' must be declared 
  l_statement := 'BEGIN DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO; END;';
  l_cursor_id := DBMS_SQL.OPEN_CURSOR;
  FOR i IN (SELECT name FROM v$containers WHERE open_mode = 'READ WRITE')
  LOOP
    BEGIN
      DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => i.name);
      l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    EXCEPTION
      WHEN l_identifier_must_be_declared THEN
        output(i.name||' '||SQLERRM);
    END;
  END LOOP;
  DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
  output('DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO end '||TO_CHAR(l_max_last_analyzed, gk_date_format));
  */
  -- main 
  MERGE /* &&1.iod_space.tab_modifications_hist */
  INTO &&1..tab_modifications_hist d
  USING (
    WITH
    s_v$containers AS (
    SELECT /*+ NO_MERGE */
           c.con_id,
           c.name pdb_name
      FROM v$containers c
     WHERE c.open_mode = 'READ WRITE'
    ),
    s_cdb_tables AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           t.owner,
           t.table_name,
           t.last_analyzed,
           t.num_rows,
           t.con_id
      FROM cdb_tables t
     WHERE t.last_analyzed IS NOT NULL -- partition key cannot contain nulls
       AND t.last_analyzed > TRUNC(SYSDATE) - gk_table_stats_days -- collect up to this many days of history
       AND t.last_analyzed > l_max_last_analyzed -- no need to keep reading data that has been processed
       AND t.temporary = 'N'
       AND t.table_name NOT LIKE 'BIN$%'
    ),
    s_cdb_tab_modifications AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           m.table_owner,
           m.table_name,
           m.timestamp,
           m.inserts,
           m.updates,
           m.deletes,
           m.truncated,
           m.drop_segments,
           m.con_id
      FROM cdb_tab_modifications m
     WHERE m.table_name NOT LIKE 'BIN$%'
       AND m.timestamp IS NOT NULL
       AND m.timestamp > TRUNC(SYSDATE) - gk_table_stats_days -- collect up to this many days of history
       AND m.timestamp > l_max_last_analyzed -- no need to keep reading data that has been processed
       AND m.partition_name IS NULL
    )
    SELECT /*+ ORDERED USE_HASH(t m c) */
           c.pdb_name,
           t.owner,
           t.table_name,
           t.last_analyzed,
           t.num_rows,
           m.timestamp,
           m.inserts,
           m.updates,
           m.deletes,
           m.truncated,
           m.drop_segments,
           t.con_id
      FROM s_cdb_tables t,
           s_cdb_tab_modifications m,
           s_v$containers c
     WHERE m.con_id = t.con_id
       AND m.table_owner = t.owner
       AND m.table_name = t.table_name
       AND m.timestamp > t.last_analyzed
       AND c.con_id = t.con_id
       AND c.con_id = m.con_id -- manual transitivity
  ) s
  ON
  ( d.pdb_name      = s.pdb_name      AND 
    d.owner         = s.owner         AND
    d.table_name    = s.table_name    AND
    d.last_analyzed = s.last_analyzed AND
    d.timestamp     = s.timestamp     AND
    d.con_id        = s.con_id -- redundant
  )
  WHEN NOT MATCHED THEN
  INSERT (
    pdb_name       ,
    owner          ,
    table_name     ,
    last_analyzed  ,
    num_rows       ,
    timestamp      ,
    inserts        ,
    updates        ,
    deletes        ,
    truncated      ,
    drop_segments  ,
    con_id         
  ) VALUES (
    s.pdb_name       ,
    s.owner          ,
    s.table_name     ,
    s.last_analyzed  ,
    s.num_rows       ,
    s.timestamp      ,
    s.inserts        ,
    s.updates        ,
    s.deletes        ,
    s.truncated      ,
    s.drop_segments  ,
    s.con_id         
  );
  --
  COMMIT;
  -- drop partitions with data older than 12 months (i.e. preserve between 12 and 13 months of history)
  FOR i IN (
    SELECT partition_name, high_value, blocks
      FROM dba_tab_partitions
     WHERE table_owner = UPPER('&&1.')
       AND table_name = 'TAB_MODIFICATIONS_HIST'
     ORDER BY
           partition_name
  )
  LOOP
    EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
    output('PARTITION:'||RPAD(SUBSTR(i.partition_name, 1, 30), 32)||'HIGH_VALUE:'||TO_CHAR(l_high_value, gk_date_format)||'  BLOCKS:'||i.blocks);
    IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -12) THEN
      output('&&1..IOD_SPACE.tab_modifications_hist: ALTER TABLE &&1..tab_modifications_hist DROP PARTITION '||i.partition_name, p_alert_log => 'Y');
      EXECUTE IMMEDIATE q'[ALTER TABLE &&1..tab_modifications_hist SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
      EXECUTE IMMEDIATE 'ALTER TABLE &&1..tab_modifications_hist DROP PARTITION '||i.partition_name;
    END IF;
  END LOOP;
  -- count
  SELECT COUNT(*)
    INTO l_count
    FROM &&1..tab_modifications_hist;
  output('&&1..tab_modifications_hist end count: '||l_count);
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
  output('end '||TO_CHAR(SYSDATE, gk_date_format));
END tab_modifications_hist;
/* ------------------------------------------------------------------------------------ */
PROCEDURE segments_hist
IS
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_count NUMBER;
  l_high_value DATE;
BEGIN
  SELECT name, open_mode INTO l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output('*** to be executed only on DG primary ***');
    RETURN;
  END IF;
  --
  output('begin '||TO_CHAR(SYSDATE, gk_date_format));
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SPACE.segments_hist','SEGMENTS_HIST');
  -- count
  SELECT COUNT(*)
    INTO l_count
    FROM &&1..segments_hist;
  output('&&1..segments_hist begin count: '||l_count);
  -- main 
  INSERT /* &&1.iod_space.segments_hist */
  INTO &&1..segments_hist (
    pdb_name       ,
    owner          ,
    segment_name   ,
    partition_name ,
    segment_type   ,
    tablespace_name,
    bytes          ,
    blocks         ,
    extents        ,
    snap_time      ,
    con_id         
  )
  WITH
  s_v$containers AS (
  SELECT /*+ NO_MERGE */
         c.con_id,
         c.name pdb_name
    FROM v$containers c
   WHERE c.open_mode = 'READ WRITE'
  ),
  s_cdb_segments AS (
  SELECT /*+ MATERIALIZE NO_MERGE */
         s.owner          ,
         s.segment_name   ,
         s.partition_name ,
         s.segment_type   ,
         s.tablespace_name,
         s.bytes          ,
         s.blocks         ,
         s.extents        ,
         s.con_id         
    FROM cdb_segments s
  )
  SELECT /*+ USE_HASH(s c) */
         c.pdb_name       ,
         s.owner          ,
         s.segment_name   ,
         s.partition_name ,
         s.segment_type   ,
         s.tablespace_name,
         s.bytes          ,
         s.blocks         ,
         s.extents        ,
         SYSDATE snap_time,
         s.con_id         
    FROM s_cdb_segments s,
         s_v$containers c
   WHERE c.con_id = s.con_id;
  --
  COMMIT;
  -- drop partitions with data older than 12 months (i.e. preserve between 12 and 13 months of history)
  FOR i IN (
    SELECT partition_name, high_value, blocks
      FROM dba_tab_partitions
     WHERE table_owner = UPPER('&&1.')
       AND table_name = 'SEGMENTS_HIST'
     ORDER BY
           partition_name
  )
  LOOP
    EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
    output('PARTITION:'||RPAD(SUBSTR(i.partition_name, 1, 30), 32)||'HIGH_VALUE:'||TO_CHAR(l_high_value, gk_date_format)||'  BLOCKS:'||i.blocks);
    IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -12) THEN
      output('&&1..IOD_SPACE.segments_hist: ALTER TABLE &&1..segments_hist DROP PARTITION '||i.partition_name, p_alert_log => 'Y');
      EXECUTE IMMEDIATE q'[ALTER TABLE &&1..segments_hist SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
      EXECUTE IMMEDIATE 'ALTER TABLE &&1..segments_hist DROP PARTITION '||i.partition_name;
    END IF;
  END LOOP;
  -- count
  SELECT COUNT(*)
    INTO l_count
    FROM &&1..segments_hist;
  output('&&1..segments_hist end count: '||l_count);
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
  output('end '||TO_CHAR(SYSDATE, gk_date_format));
END segments_hist;
/* ------------------------------------------------------------------------------------ */
PROCEDURE tablespaces_hist
IS
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_count NUMBER;
  l_high_value DATE;
BEGIN
  SELECT name, open_mode INTO l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output('*** to be executed only on DG primary ***');
    RETURN;
  END IF;
  --
  output('begin '||TO_CHAR(SYSDATE, gk_date_format));
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SPACE.tablespaces_hist','TABLESPACES_HIST');
  -- count
  SELECT COUNT(*)
    INTO l_count
    FROM &&1..tablespaces_hist;
  output('&&1..tablespaces_hist begin count: '||l_count);
  -- main 
  INSERT /* &&1.iod_space.tablespaces_hist */
  INTO &&1..tablespaces_hist (
    pdb_name               ,
    tablespace_name        ,
    contents               ,
    oem_allocated_space_mbs,
    oem_used_space_mbs     ,
    oem_used_percent       ,
    met_max_size_mbs       ,
    met_used_space_mbs     ,
    met_used_percent       ,
    snap_time              ,
    con_id                 
  )
  WITH
  t AS (
  SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(cdb_data_files) */
         con_id,
         tablespace_name,
         SUM(NVL(bytes, 0)) bytes
    FROM cdb_data_files
   GROUP BY 
         con_id,
         tablespace_name
   UNION ALL
  SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(cdb_temp_files) */
         con_id,
         tablespace_name,
         SUM(NVL(bytes, 0)) bytes
    FROM cdb_temp_files
   GROUP BY 
         con_id,
         tablespace_name
  ),
  u AS (
  SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(cdb_free_space) */
         con_id,
         tablespace_name,
         SUM(bytes) bytes
    FROM cdb_free_space
   GROUP BY 
          con_id,
          tablespace_name
   UNION ALL
  SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(temp_extent_pool) */
         con_id,
         tablespace_name,
         NVL(SUM(bytes_used), 0) bytes
    FROM gv$temp_extent_pool
   GROUP BY 
         con_id,
         tablespace_name
  ),
  un AS (
  SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(usage_metrics) */
         ts.con_id,
         ts.tablespace_name,
         NVL(um.used_space * ts.block_size, 0) bytes
    FROM cdb_tablespaces              ts,
         cdb_tablespace_usage_metrics um
   WHERE ts.contents           = 'UNDO'
     AND um.tablespace_name(+) = ts.tablespace_name
     AND um.con_id(+)          = ts.con_id
  ),
  oem AS (
  SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(oem) */
         ts.con_id,
         pdb.name pdb_name,
         ts.tablespace_name,
         ts.contents,
         ts.block_size,
         NVL(t.bytes / POWER(2,20), 0) allocated_space, -- MBs
         NVL(
         CASE ts.contents
         WHEN 'UNDO'         THEN un.bytes
         WHEN 'PERMANENT'    THEN t.bytes - NVL(u.bytes, 0)
         WHEN 'TEMPORARY'    THEN
           CASE ts.extent_management
           WHEN 'LOCAL'      THEN u.bytes
           WHEN 'DICTIONARY' THEN t.bytes - NVL(u.bytes, 0)
           END
         END 
         / POWER(2,20), 0) used_space -- MBs
    FROM cdb_tablespaces ts,
         v$containers    pdb,
         t,
         u,
         un
   WHERE pdb.con_id            = ts.con_id
     AND pdb.open_mode         = 'READ WRITE'
     AND t.tablespace_name(+)  = ts.tablespace_name
     AND t.con_id(+)           = ts.con_id
     AND u.tablespace_name(+)  = ts.tablespace_name
     AND u.con_id(+)           = ts.con_id
     AND un.tablespace_name(+) = ts.tablespace_name
     AND un.con_id(+)          = ts.con_id
  )
  SELECT o.pdb_name,
         o.tablespace_name,
         o.contents,
         ROUND(o.allocated_space, 3) oem_allocated_space_mbs,
         ROUND(o.used_space, 3) oem_used_space_mbs,
         ROUND(100 * o.used_space / o.allocated_space, 3) oem_used_percent, -- as per allocated space
         ROUND(m.tablespace_size * o.block_size / POWER(2,20), 3) met_max_size_mbs,
         ROUND(m.used_space * o.block_size / POWER(2,20), 3) met_used_space_mbs,
         ROUND(m.used_percent, 3) met_used_percent, -- as per maximum size (considering auto extend)
         SYSDATE snap_time,
         o.con_id
    FROM oem                          o,
         cdb_tablespace_usage_metrics m
   WHERE m.tablespace_name(+) = o.tablespace_name
     AND m.con_id(+)          = o.con_id;
  --
  COMMIT;
  -- drop partitions with data older than 12 months (i.e. preserve between 12 and 13 months of history)
  FOR i IN (
    SELECT partition_name, high_value, blocks
      FROM dba_tab_partitions
     WHERE table_owner = UPPER('&&1.')
       AND table_name = 'TABLESPACES_HIST'
     ORDER BY
           partition_name
  )
  LOOP
    EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
    output('PARTITION:'||RPAD(SUBSTR(i.partition_name, 1, 30), 32)||'HIGH_VALUE:'||TO_CHAR(l_high_value, gk_date_format)||'  BLOCKS:'||i.blocks);
    IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -12) THEN
      output('&&1..IOD_SPACE.tablespaces_hist: ALTER TABLE &&1..tablespaces_hist DROP PARTITION '||i.partition_name, p_alert_log => 'Y');
      EXECUTE IMMEDIATE q'[ALTER TABLE &&1..tablespaces_hist SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
      EXECUTE IMMEDIATE 'ALTER TABLE &&1..tablespaces_hist DROP PARTITION '||i.partition_name;
    END IF;
  END LOOP;
  -- count
  SELECT COUNT(*)
    INTO l_count
    FROM &&1..tablespaces_hist;
  output('&&1..tablespaces_hist end count: '||l_count);
  --
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
  output('end '||TO_CHAR(SYSDATE, gk_date_format));
END tablespaces_hist;
/* ------------------------------------------------------------------------------------ */
PROCEDURE index_rebuild (
  p_report_only               IN VARCHAR2 DEFAULT gk_report_only,
  p_only_if_ref_by_full_scans IN VARCHAR2 DEFAULT gk_only_if_ref_by_full_scans,
  p_min_size_mb               IN NUMBER   DEFAULT gk_min_size_mb,
  p_min_savings_perc          IN NUMBER   DEFAULT gk_min_savings_perc,
  p_min_obj_age_days          IN NUMBER   DEFAULT gk_min_obj_age_days,
  p_sleep_seconds             IN NUMBER   DEFAULT gk_sleep_seconds,
  p_timeout                   IN DATE     DEFAULT SYSDATE + (gk_timeout_hours/24),
  p_pdb_name                  IN VARCHAR2 DEFAULT NULL
)
IS
  l_report_only VARCHAR2(1) := NVL(UPPER(TRIM(p_report_only)),gk_report_only);
  l_only_if_ref_by_full_scans VARCHAR2(1) := NVL(UPPER(TRIM(p_only_if_ref_by_full_scans)),gk_only_if_ref_by_full_scans);
  l_min_size_mb NUMBER := NVL(p_min_size_mb,gk_min_size_mb);
  l_min_savings_perc NUMBER := NVL(p_min_savings_perc,gk_min_savings_perc);
  l_min_obj_age_days NUMBER := NVL(p_min_obj_age_days,gk_min_obj_age_days);
  l_timeout DATE := NVL(p_timeout,(SYSDATE + (gk_timeout_hours/24)));
  l_sleep_seconds NUMBER :=  NVL(p_sleep_seconds,gk_sleep_seconds);
  l_pdb_name VARCHAR2(128) := UPPER(TRIM(p_pdb_name));
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_dbid NUMBER;
  l_count NUMBER;
  l_high_value DATE;
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
  l_retry BOOLEAN;
  l_snap_time DATE := SYSDATE;
  l_index_rebuild_hist_rec &&1..index_rebuild_hist%ROWTYPE;
  --
  PROCEDURE insert_index_rebuild_hist 
  IS PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO &&1..index_rebuild_hist VALUES l_index_rebuild_hist_rec;
    COMMIT;
  END insert_index_rebuild_hist;
BEGIN
  SELECT dbid, name, open_mode INTO l_dbid, l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output('-- *** to be executed only on DG primary ***');
    RETURN;
  END IF;
  --
  IF SYSDATE > l_timeout THEN
    output('-- *** timeout ***');
    RETURN;
  END IF;
  --
  output('-- begin &&1..IOD_SPACE.index_rebuild '||TO_CHAR(SYSDATE, gk_date_format));
  output('-- timeout:'||TO_CHAR(l_timeout, gk_date_format));
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SPACE.index_rebuild','INDEX_REBUILD');
  -- count
  SELECT COUNT(*)
    INTO l_count
    FROM &&1..index_rebuild_hist;
  output('-- &&1..index_rebuild_hist begin count: '||l_count);
  -- main 
  FOR i IN (WITH /*+ iod_space.index_rebuild */
            indexes AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(indexes) */
                   i.con_id, 
                   i.owner,
                   i.index_name,
                   i.tablespace_name
              FROM cdb_indexes i
             WHERE i.owner <> 'SYS'
               AND i.index_type LIKE '%NORMAL%'
               AND i.table_owner <> 'SYS'
               AND i.table_name <> 'KIEVTRANSACTIONS' -- For as long as KIEV application does a LOCK TABLE IN EXCLUSIVE MODE, exclude its indexes!
               AND i.tablespace_name NOT IN ('SYSTEM','SYSAUX')
               AND i.table_type = 'TABLE'
               AND i.status = 'VALID'
               AND i.partitioned = 'NO'
               AND i.temporary = 'N'
               AND i.dropped = 'NO'
               AND i.visibility = 'VISIBLE'
               AND i.segment_created = 'YES'
            ),
            tablespaces AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(tablespaces) */
                   t.con_id,
                   t.tablespace_name,
                   t.block_size
              FROM cdb_tablespaces t
             WHERE t.status = 'ONLINE'
               AND t.contents = 'PERMANENT'
            ),
            users AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(users) */
                   u.con_id,
                   u.username
              FROM cdb_users u
             WHERE u.oracle_maintained = 'N'
            ),
            segments AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(segments) */
                   s.con_id,
                   s.owner,
                   s.segment_name,
                   s.tablespace_name,
                   s.blocks
              FROM cdb_segments s
             WHERE s.segment_type = 'INDEX'
            ),
            objects AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(objects) */
                   o.con_id,
                   o.owner,
                   o.object_name,
                   o.last_ddl_time
              FROM cdb_objects o
             WHERE o.owner <> 'SYS'
               AND o.object_type = 'INDEX'
               AND o.last_ddl_time < SYSDATE - l_min_obj_age_days
            ),
            containers AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(containers) */
                   c.con_id,
                   c.name pdb_name
              FROM v$containers c
             WHERE c.open_mode = 'READ WRITE'
               AND (l_pdb_name IS NULL OR c.name = l_pdb_name)
            ),
            rebuild_candidate AS (
            SELECT /*+ MATERIALIZE NO_MERGE ORDERED USE_HASH(i t u s o c) GATHER_PLAN_STATISTICS QB_NAME(rebuild_candidate) */
                   i.con_id, 
                   c.pdb_name,
                   i.owner,
                   i.index_name,
                   i.tablespace_name,
                   t.block_size,
                   (s.blocks * t.block_size / POWER(2,20)) size_mbs_seg,
                   o.last_ddl_time
              FROM indexes i,
                   tablespaces t,
                   users u,
                   segments s,
                   objects o,
                   containers c
             WHERE t.con_id = i.con_id
               AND t.tablespace_name = i.tablespace_name
               AND u.con_id = i.con_id
               AND u.username = i.owner
               AND s.con_id = i.con_id
               AND s.owner = i.owner
               AND s.segment_name = i.index_name
               AND s.tablespace_name = i.tablespace_name
               AND s.blocks * t.block_size / POWER(2,20) > l_min_size_mb 
               AND o.con_id = i.con_id
               AND o.owner = i.owner
               AND o.object_name = i.index_name
               AND c.con_id = i.con_id
            ),
            -- replace v$sql_plan with dba_hist_sql_plan since former causes a scan on X$KQLFXPL to hang (ref: 2201867.1 22655916 19875836)
            full_scan AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(full_scan) */
                   p.con_id,
                   p.object_owner owner, 
                   p.object_name index_name,
                   'Y' full_scan
              FROM dba_hist_sql_plan p -- v$sql_plan p
             WHERE p.object_owner <> 'SYS'
               AND p.operation = 'INDEX'
               AND p.options IN ('FULL SCAN', 'FAST FULL SCAN')
               AND p.dbid = l_dbid
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
                   NVL(fs.full_scan, 'N') full_scan,
                   rc.last_ddl_time
              FROM rebuild_candidate rc,
                   full_scan fs
             WHERE fs.con_id(+) = rc.con_id
               AND fs.owner(+) = rc.owner
               AND fs.index_name(+) = rc.index_name
             ORDER BY
                   MOD(rc.size_mbs_seg, 10)) -- randomize index selection
  LOOP
    l_retry := FALSE;
    l_index_rebuild_hist_rec := NULL;
    l_index_rebuild_hist_rec.pdb_name := i.pdb_name;
    l_index_rebuild_hist_rec.owner := i.owner;
    l_index_rebuild_hist_rec.index_name := i.index_name;
    l_index_rebuild_hist_rec.tablespace_name := i.tablespace_name;
    l_index_rebuild_hist_rec.full_scan := i.full_scan;
    l_index_rebuild_hist_rec.ddl_statement := NULL;
    l_index_rebuild_hist_rec.error_message := NULL;
    l_index_rebuild_hist_rec.size_mbs_before := ROUND(i.size_mbs_seg, 3);
    l_index_rebuild_hist_rec.size_mbs_after := NULL;
    l_index_rebuild_hist_rec.ddl_begin_time := NULL;
    l_index_rebuild_hist_rec.ddl_end_time := NULL;
    l_index_rebuild_hist_rec.snap_time := l_snap_time; -- all rows get the same date so we can easily aggregate for reporting
    l_index_rebuild_hist_rec.con_id := i.con_id;  
    --
    IF l_index_rebuild_hist_rec.full_scan = 'Y' OR 
       l_only_if_ref_by_full_scans = 'N' 
    THEN
      output('-- ');
      output('-- '||TO_CHAR(SYSDATE, gk_date_format));
      output('-- pdb:'||l_index_rebuild_hist_rec.pdb_name||'('||l_index_rebuild_hist_rec.con_id||'). idx:'||l_index_rebuild_hist_rec.owner||'.'||l_index_rebuild_hist_rec.index_name||'. last_ddl_time:'||TO_CHAR(i.last_ddl_time,gk_date_format)||'. fs:'||l_index_rebuild_hist_rec.full_scan||'.');
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
          l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** DBMS_SPACE.CREATE_INDEX_COST by &&1..IOD_SPACE.index_rebuild';
          insert_index_rebuild_hist;
          output('-- '||l_index_rebuild_hist_rec.error_message, p_alert_log => 'Y');
          DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
          RAISE;
      END;
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      --
      l_estimated_size_mbs_after := ROUND(l_alloc_bytes / POWER(2,20), 3);
      l_savings_percent := ROUND(100 * (l_index_rebuild_hist_rec.size_mbs_before - l_estimated_size_mbs_after) / l_index_rebuild_hist_rec.size_mbs_before, 1);
      output('-- before:'||l_index_rebuild_hist_rec.size_mbs_before||'MBs. estimate:'||l_estimated_size_mbs_after||'MBs. diff:'||(l_index_rebuild_hist_rec.size_mbs_before - l_estimated_size_mbs_after)||'MBs. savings:'||l_savings_percent||'%.');
      --
      IF l_savings_percent > l_min_savings_perc AND l_report_only = 'Y' THEN
        l_index_count := l_index_count + 1;
        l_size_mbs_before := ROUND(l_size_mbs_before + l_index_rebuild_hist_rec.size_mbs_before, 3);
        l_size_mbs_after := ROUND(l_size_mbs_after + l_estimated_size_mbs_after, 3);
      END IF;
      -- 
      IF l_savings_percent > l_min_savings_perc AND l_report_only = 'N' THEN
        IF l_index_count > 0 AND l_sleep_seconds > 0 THEN
          DBMS_APPLICATION_INFO.SET_ACTION('NEXT->'||l_index_rebuild_hist_rec.index_name||'('||l_index_rebuild_hist_rec.con_id||')');
          output('-- sleep '||l_sleep_seconds||'s');
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
            l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** DBMS_LOCK.REQUEST by &&1..IOD_SPACE.index_rebuild';
            insert_index_rebuild_hist;
            output('-- '||l_index_rebuild_hist_rec.error_message, p_alert_log => 'Y');
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        IF l_return > 0 THEN -- time to kill
          l_index_rebuild_hist_rec.error_message := '*** KILLED ***';
          insert_index_rebuild_hist;
          output('-- '||l_index_rebuild_hist_rec.error_message);
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
            l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** DBMS_LOCK.RELEASE by &&1..IOD_SPACE.index_rebuild';
            insert_index_rebuild_hist;
            output('-- '||l_index_rebuild_hist_rec.error_message, p_alert_log => 'Y');
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        IF l_return > 0 THEN -- time to kill
          l_index_rebuild_hist_rec.error_message := '*** KILLED ***';
          insert_index_rebuild_hist;
          output('-- '||l_index_rebuild_hist_rec.error_message||' by &&1..IOD_SPACE.index_rebuild', p_alert_log => 'Y');
          EXIT;
        END IF; -- l_return > 0
        --
        DBMS_APPLICATION_INFO.SET_ACTION('ON->'||l_index_rebuild_hist_rec.index_name||'('||l_index_rebuild_hist_rec.con_id||')');
        l_index_rebuild_hist_rec.ddl_statement := 'ALTER INDEX '||LOWER(l_index_rebuild_hist_rec.owner)||'.'||LOWER(l_index_rebuild_hist_rec.index_name)||' REBUILD ONLINE';
        output('-- '||TO_CHAR(SYSDATE, gk_date_format)||' &&1..IOD_SPACE.index_rebuild', p_alert_log => 'Y');
        output('ALTER SESSION SET CONTAINER = '||l_index_rebuild_hist_rec.pdb_name||';', p_alert_log => 'Y');
        output(l_index_rebuild_hist_rec.ddl_statement||';', p_alert_log => 'Y');
        --
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        DECLARE
          maximum_key_length EXCEPTION;
          PRAGMA EXCEPTION_INIT(maximum_key_length, -01450); -- ORA-01450: maximum key length (string) exceeded
        BEGIN
          l_retry := FALSE;
          l_index_rebuild_hist_rec.ddl_begin_time := SYSDATE;
          DBMS_SQL.PARSE(c => l_cursor_id, statement => l_index_rebuild_hist_rec.ddl_statement, language_flag => DBMS_SQL.NATIVE, container => l_index_rebuild_hist_rec.pdb_name);
          l_index_rebuild_hist_rec.ddl_end_time := SYSDATE;
        EXCEPTION
          WHEN maximum_key_length THEN -- ref: https://blog.pythian.com/ora-01450-during-online-index-rebuild/
            l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** ALTER INDEX by &&1..IOD_SPACE.index_rebuild';
            l_index_rebuild_hist_rec.ddl_end_time := SYSDATE;
            insert_index_rebuild_hist;
            output('-- '||l_index_rebuild_hist_rec.error_message, p_alert_log => 'Y');
            l_retry := TRUE;
          WHEN OTHERS THEN
            l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** ALTER INDEX by &&1..IOD_SPACE.index_rebuild';
            l_index_rebuild_hist_rec.ddl_end_time := SYSDATE;
            insert_index_rebuild_hist;
            output('-- '||l_index_rebuild_hist_rec.error_message, p_alert_log => 'Y');
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        output('-- '||TO_CHAR(SYSDATE, gk_date_format));
        IF l_retry THEN
          DBMS_APPLICATION_INFO.SET_ACTION('ON->'||l_index_rebuild_hist_rec.index_name||'('||l_index_rebuild_hist_rec.con_id||')');
          l_index_rebuild_hist_rec.error_message := NULL;
          l_index_rebuild_hist_rec.ddl_statement := 'ALTER INDEX '||LOWER(l_index_rebuild_hist_rec.owner)||'.'||LOWER(l_index_rebuild_hist_rec.index_name)||' REBUILD ';
          output('-- '||TO_CHAR(SYSDATE, gk_date_format)||' &&1..IOD_SPACE.index_rebuild begin', p_alert_log => 'Y');
          output('ALTER SESSION SET CONTAINER = '||l_index_rebuild_hist_rec.pdb_name||';', p_alert_log => 'Y');
          output(l_index_rebuild_hist_rec.ddl_statement||';', p_alert_log => 'Y');
          --
          l_cursor_id := DBMS_SQL.OPEN_CURSOR;
          DECLARE
            resource_busy EXCEPTION;
            PRAGMA EXCEPTION_INIT(resource_busy, -00054); -- ORA-00054: resource busy and acquire with NOWAIT specified or timeout expired
          BEGIN
            l_index_rebuild_hist_rec.ddl_begin_time := SYSDATE;
            DBMS_SQL.PARSE(c => l_cursor_id, statement => l_index_rebuild_hist_rec.ddl_statement, language_flag => DBMS_SQL.NATIVE, container => l_index_rebuild_hist_rec.pdb_name);
            l_index_rebuild_hist_rec.ddl_end_time := SYSDATE;
          EXCEPTION
            WHEN resource_busy THEN -- ignore error!
              l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** ALTER INDEX by &&1..IOD_SPACE.index_rebuild';
              l_index_rebuild_hist_rec.ddl_end_time := SYSDATE;
              insert_index_rebuild_hist;
              output('-- '||l_index_rebuild_hist_rec.error_message, p_alert_log => 'Y');
              --DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
              --RAISE;
            WHEN OTHERS THEN
              l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** ALTER INDEX by &&1..IOD_SPACE.index_rebuild';
              l_index_rebuild_hist_rec.ddl_end_time := SYSDATE;
              insert_index_rebuild_hist;
              output('-- '||l_index_rebuild_hist_rec.error_message, p_alert_log => 'Y');
              DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
              RAISE;
          END;
          DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
          --
          output('-- '||TO_CHAR(SYSDATE, gk_date_format)||' &&1..IOD_SPACE.index_rebuild end', p_alert_log => 'Y');
        END IF; -- l_retry
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
            l_index_rebuild_hist_rec.error_message := '*** '||SQLERRM||' *** SELECT blocks FROM dba_segments by &&1..IOD_SPACE.index_rebuild';
            output('-- '||l_index_rebuild_hist_rec.error_message, p_alert_log => 'Y');
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        l_index_rebuild_hist_rec.size_mbs_after := ROUND(l_blocks_after * i.block_size / POWER(2,20), 3);
        l_savings_percent := ROUND(100 * (l_index_rebuild_hist_rec.size_mbs_before - l_index_rebuild_hist_rec.size_mbs_after) / l_index_rebuild_hist_rec.size_mbs_before, 1);
        output('-- before:'||l_index_rebuild_hist_rec.size_mbs_before||'MBs. after:'||l_index_rebuild_hist_rec.size_mbs_after||'MBs. diff:'||(l_index_rebuild_hist_rec.size_mbs_before - l_index_rebuild_hist_rec.size_mbs_after)||'MBs. savings:'||l_savings_percent||'%.');
        insert_index_rebuild_hist;
        --
        l_index_count := l_index_count + 1;
        l_size_mbs_before := ROUND(l_size_mbs_before + l_index_rebuild_hist_rec.size_mbs_before, 3);
        l_size_mbs_after := ROUND(l_size_mbs_after + l_index_rebuild_hist_rec.size_mbs_after, 3);
      END IF; -- l_savings_percent > l_min_savings_perc AND l_report_only = 'N'
    END IF; -- l_index_rebuild_hist_rec.full_scan = 'Y' OR l_only_if_ref_by_full_scans = 'N' 
    --
    IF SYSDATE > l_timeout THEN
      output('-- *** timeout ***');
      EXIT;
    END IF;
    --
  END LOOP;
  output('-- ');
  --
  IF l_index_count > 0 AND l_size_mbs_before > 0 THEN
    l_savings_percent := ROUND(100 * (l_size_mbs_before - l_size_mbs_after) / l_size_mbs_before, 1);
    output('-- ~~~ indexes:'||l_index_count||'. before:'||l_size_mbs_before||'MBs. after:'||l_size_mbs_after||'MBs. diff:'||(l_size_mbs_before - l_size_mbs_after)||'MBs. savings:'||l_savings_percent||'%. ~~~');
  END IF;
  IF l_index_count = 0 THEN
    output('-- ~~~ nothing to do! ~~~');
  END IF;
  output('-- ');
  -- drop partitions with data older than 12 months (i.e. preserve between 12 and 13 months of history)
  IF l_report_only = 'N' THEN
    FOR i IN (
      SELECT partition_name, high_value, blocks
        FROM dba_tab_partitions
       WHERE table_owner = UPPER('&&1.')
         AND table_name = 'INDEX_REBUILD_HIST'
       ORDER BY
             partition_name
    )
    LOOP
      EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
      output('-- PARTITION:'||RPAD(SUBSTR(i.partition_name, 1, 30), 32)||'HIGH_VALUE:'||TO_CHAR(l_high_value, gk_date_format)||'  BLOCKS:'||i.blocks);
      IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -12) THEN
        output('-- &&1..IOD_SPACE.index_rebuild: ALTER TABLE &&1..index_rebuild_hist DROP PARTITION '||i.partition_name, p_alert_log => 'Y');
        EXECUTE IMMEDIATE q'[ALTER TABLE &&1..index_rebuild_hist SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
        EXECUTE IMMEDIATE 'ALTER TABLE &&1..index_rebuild_hist DROP PARTITION '||i.partition_name;
      END IF;
    END LOOP;
  END IF;
  -- count
  SELECT COUNT(*)
    INTO l_count
    FROM &&1..index_rebuild_hist;
  output('-- &&1..index_rebuild_hist end count: '||l_count);
  --
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
  output('-- end &&1..IOD_SPACE.index_rebuild '||TO_CHAR(SYSDATE, gk_date_format));
END index_rebuild;
/* ------------------------------------------------------------------------------------ */
PROCEDURE table_redefinition (
  p_report_only               IN VARCHAR2 DEFAULT gk_report_only,
  p_only_if_ref_by_full_scans IN VARCHAR2 DEFAULT gk_only_if_ref_by_full_scans,
  p_min_size_mb               IN NUMBER   DEFAULT gk_min_size_mb,
  p_min_savings_perc          IN NUMBER   DEFAULT gk_min_savings_perc,
  p_min_ts_used_percent       IN NUMBER   DEFAULT gk_min_ts_used_percent,
  p_min_obj_age_days          IN NUMBER   DEFAULT gk_min_obj_age_days,
  p_sleep_seconds             IN NUMBER   DEFAULT gk_sleep_seconds,
  p_timeout                   IN DATE     DEFAULT SYSDATE + (gk_timeout_hours/24),
  p_pdb_name                  IN VARCHAR2 DEFAULT NULL
)
IS
  l_report_only VARCHAR2(1) := NVL(UPPER(TRIM(p_report_only)),gk_report_only);
  l_only_if_ref_by_full_scans VARCHAR2(1) := NVL(UPPER(TRIM(p_only_if_ref_by_full_scans)),gk_only_if_ref_by_full_scans);
  l_min_size_mb NUMBER := NVL(p_min_size_mb,gk_min_size_mb);
  l_min_savings_perc NUMBER := NVL(p_min_savings_perc,gk_min_savings_perc);
  l_min_ts_used_percent NUMBER := NVL(p_min_ts_used_percent,gk_min_ts_used_percent);
  l_min_obj_age_days NUMBER := NVL(p_min_obj_age_days,gk_min_obj_age_days);
  l_sleep_seconds NUMBER :=  NVL(p_sleep_seconds,gk_sleep_seconds);
  l_timeout DATE := NVL(p_timeout,(SYSDATE + (gk_timeout_hours/24)));
  l_pdb_name VARCHAR2(128) := UPPER(TRIM(p_pdb_name));
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_dbid NUMBER;
  l_count NUMBER;
  l_high_value DATE;
  l_savings_percent NUMBER;
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows INTEGER;
  l_used_bytes NUMBER;
  l_alloc_bytes NUMBER;
  l_estimated_size_mbs_after NUMBER;
  l_bytes_after NUMBER;
  l_table_count NUMBER := 0;
  l_size_mbs_before NUMBER := 0;
  l_size_mbs_after NUMBER := 0;
  l_size_all_mbs_before NUMBER := 0;
  l_size_all_mbs_after NUMBER := 0;
  l_sum_bytes_after NUMBER := 0;
  l_max_bytes_after NUMBER := 0;
  l_return NUMBER;
  l_snap_time DATE := SYSDATE;
  l_table_redefinition_hist_rec &&1..table_redefinition_hist%ROWTYPE;
  --
  PROCEDURE insert_table_redefinition_hist 
  IS PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO &&1..table_redefinition_hist VALUES l_table_redefinition_hist_rec;
    COMMIT;
  END insert_table_redefinition_hist;
BEGIN
  SELECT dbid, name, open_mode INTO l_dbid, l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output('-- *** to be executed only on DG primary ***');
    RETURN;
  END IF;
  --
  IF SYSDATE > l_timeout THEN
    output('-- *** timeout ***');
    RETURN;
  END IF;
  --
  output('-- begin &&1..IOD_SPACE.table_redefinition '||TO_CHAR(SYSDATE, gk_date_format));
  output('-- timeout:'||TO_CHAR(l_timeout, gk_date_format));
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SPACE.table_redefinition','TABLE_REDEFINITION');
  --
  -- Bug 11834459 : DBMS_REDEFINITION.FINISH_REDEF_TABLE MAY FLUSH THE SHARED POOL
  --EXECUTE IMMEDIATE q'[ALTER SESSION SET EVENT = '10995 TRACE NAME CONTEXT FOREVER, LEVEL 2']';
  EXECUTE IMMEDIATE q'[ALTER SESSION SET EVENTS = '10995 TRACE NAME CONTEXT FOREVER, LEVEL 2']';
  --
  -- count
  SELECT COUNT(*)
    INTO l_count
    FROM &&1..table_redefinition_hist;
  output('-- &&1..table_redefinition_hist begin count: '||l_count);
  -- main 
  FOR i IN (WITH /*+ iod_space.table_redefinition */
            tables AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(tables) */
                   t.con_id,
                   t.owner,
                   t.table_name,
                   t.tablespace_name,
                   t.num_rows,
                   t.avg_row_len,
                   t.pct_free,
                   t.blocks,
                   t.compression,
                   t.compress_for
              FROM cdb_tables t
             WHERE t.owner <> 'SYS'
               AND t.table_name NOT IN ('KIEVTRANSACTIONS', 'KIEVTRANSACTIONKEYS') -- For as long as GC is not aware of Table Redefinition.
               AND t.table_name <> 'TIMERS' -- Until we get ORA-600 from IOD-9949 fixed
               AND t.tablespace_name NOT IN ('SYSTEM','SYSAUX')
               AND t.cluster_name IS NULL
               AND t.iot_name IS NULL
               AND t.status = 'VALID'
               AND t.partitioned = 'NO'
               AND t.temporary = 'N'
               AND t.nested = 'NO'
               AND t.dropped = 'NO'
               AND t.read_only = 'NO'
               AND t.segment_created = 'YES'
               AND t.num_rows > 0
               AND t.avg_row_len > 0
               AND t.pct_free >= 0
            ),
            identity_columns AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(identity1) */
                   c.con_id,
                   c.owner,
                   c.table_name,
                   c.column_name
              FROM cdb_tab_columns c
             WHERE c.owner <> 'SYS'
               AND c.identity_column = 'YES'
            ),              
            ind AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(ind) */
                   i.con_id, 
                   i.table_owner,
                   i.table_name,
                   i.owner,
                   i.index_name,
                   i.uniqueness
              FROM cdb_indexes i
             WHERE (i.index_type LIKE '%NORMAL%' OR i.index_type = 'LOB')
               AND i.table_owner <> 'SYS'
               AND i.tablespace_name NOT IN ('SYSTEM','SYSAUX')
               AND i.table_type = 'TABLE'
               AND i.status = 'VALID'
               AND i.partitioned = 'NO'
               AND i.temporary = 'N'
               AND i.dropped = 'NO'
               AND i.visibility = 'VISIBLE'
               AND i.segment_created = 'YES'
            ),
            ind_segments AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(ind_segments) */
                   s.con_id, 
                   s.owner,
                   s.segment_name,
                   s.bytes
              FROM cdb_segments s
             WHERE s.owner <> 'SYS'
               AND s.segment_type IN ('INDEX', 'LOBINDEX')
               AND tablespace_name NOT IN ('SYSTEM','SYSAUX')
            ),
            indexes AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(indexes) */
                   i.con_id, 
                   i.table_owner,
                   i.table_name,
                   COUNT(*) index_count,
                   SUM(CASE i.uniqueness WHEN 'UNIQUE' THEN 1 ELSE 0 END) unique_indexes,
                   SUM(s.bytes) sum_bytes,
                   MAX(s.bytes) max_bytes
              FROM ind i,
                   ind_segments s
             WHERE s.con_id = i.con_id
               AND s.owner = i.owner
               AND s.segment_name = i.index_name
             GROUP BY
                   i.con_id, 
                   i.table_owner,
                   i.table_name
            ),
            tablespaces1 AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(tablespaces1) */
                   t.con_id,
                   t.tablespace_name,
                   t.block_size
              FROM cdb_tablespaces t
             WHERE t.status = 'ONLINE'
               AND t.contents = 'PERMANENT'
               AND t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
            ),
            tablespaces2 AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(tablespaces2) */
                   m.con_id,
                   m.tablespace_name,
                   m.used_space,
                   m.tablespace_size,
                   m.used_percent                  
              FROM cdb_tablespace_usage_metrics m
             WHERE m.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
               AND m.used_percent < l_min_ts_used_percent
            ),
            tablespaces AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(tablespaces) */
                   t.con_id,
                   t.tablespace_name,
                   t.block_size,
                   ROUND(m.used_space * t.block_size / POWER(2,30), 3) used_space_gbs,
                   ROUND(m.tablespace_size * t.block_size / POWER(2,30), 3) max_size_gbs,
                   ROUND(m.used_percent, 3) used_percent -- as per maximum size (considering auto extend)                   
              FROM tablespaces1 t,
                   tablespaces2 m
             WHERE m.con_id = t.con_id
               AND m.tablespace_name = t.tablespace_name
            ),
            users AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(users) */
                   u.con_id,
                   u.username
              FROM cdb_users u
             WHERE u.oracle_maintained = 'N'
            ),
            segments AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(segments) */
                   s.con_id,
                   s.owner,
                   s.segment_name,
                   s.tablespace_name,
                   s.bytes
              FROM cdb_segments s
             WHERE s.owner <> 'SYS'
               AND s.segment_type = 'TABLE'
               AND s.bytes / POWER(2,20) > l_min_size_mb
            ),
            lobs AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(lobs) */
                   l.con_id,
                   l.owner,
                   l.table_name,
                   l.tablespace_name,
                   COUNT(*) lobs,
                   SUM(s.bytes) bytes
              FROM cdb_lobs l,
                   cdb_segments s
             WHERE l.owner <> 'SYS'
               AND s.con_id = l.con_id
               AND s.owner = l.owner
               AND s.segment_name = l.segment_name
               AND s.tablespace_name = l.tablespace_name
               AND s.segment_type = 'LOBSEGMENT'
             GROUP BY
                   l.con_id,
                   l.owner,
                   l.table_name,
                   l.tablespace_name
            ),
            objects AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(objects) */
                   o.con_id,
                   o.owner,
                   o.object_name,
                   o.created
              FROM cdb_objects o
             WHERE o.owner <> 'SYS'
               AND o.object_type = 'TABLE'
               AND o.created < SYSDATE - l_min_obj_age_days
            ),
            containers AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(containers) */
                   c.con_id,
                   c.name pdb_name
              FROM v$containers c
             WHERE c.open_mode = 'READ WRITE'
               AND (l_pdb_name IS NULL OR c.name = l_pdb_name)
            ),
            redef_log AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(redef_log) */
                   con_id, COUNT(*) cnt
              FROM cdb_mview_logs
             WHERE log_table LIKE 'MLOG$\_'||CHR(37) ESCAPE '\'
             GROUP BY
                   con_id
            ),
            redef_mv AS (            
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(redef_mv) */
                   con_id, COUNT(*) cnt
              FROM cdb_mviews
             WHERE mview_name LIKE 'REDEF$\_T'||CHR(37) ESCAPE '\'
             GROUP BY
                   con_id
            ),
            redef_tbl AS (            
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(redef_tbl) */
                   con_id, COUNT(*) cnt
              FROM cdb_tables
             WHERE table_name LIKE 'REDEF$\_T'||CHR(37) ESCAPE '\'
             GROUP BY
                   con_id
            ),
            rebuild_candidate AS (
            SELECT /*+ MATERIALIZE NO_MERGE ORDERED USE_HASH(t i ts u s l o c lg mv tb) GATHER_PLAN_STATISTICS QB_NAME(rebuild_candidate) */
                   t.con_id, 
                   c.pdb_name,
                   t.owner,
                   t.table_name,
                   t.tablespace_name,
                   t.num_rows,
                   t.avg_row_len,
                   t.pct_free,
                   ts.block_size,
                   t.compression,
                   t.compress_for,
                   NVL(ROUND(s.bytes / POWER(2,20), 3), 0) table_size_mbs,
                   NVL(i.index_count, 0) index_count,
                   NVL(i.unique_indexes, 0) unique_indexes,
                   NVL(ROUND(i.sum_bytes / POWER(2,20), 3), 0) all_index_size_mbs,
                   NVL(ROUND(i.max_bytes / POWER(2,20), 3), 0) top_index_size_mbs,
                   NVL(l.lobs, 0) lobs_count,
                   NVL(ROUND(l.bytes / POWER(2,20), 3), 0) all_lobs_size_mbs,
                   ts.used_space_gbs ts_used_space_gbs,
                   ts.max_size_gbs ts_max_size_gbs,
                   ts.used_percent ts_used_percent,
                   o.created,
                   NVL(lg.cnt, 0) redef_log_cnt,
                   NVL(mv.cnt, 0) redef_mv_cnt,
                   NVL(tb.cnt, 0) redef_tbl_cnt
              FROM tables t,
                   indexes i,
                   tablespaces ts,
                   users u,
                   segments s,
                   lobs l,
                   objects o,
                   containers c,
                   redef_log lg,
                   redef_mv mv,
                   redef_tbl tb
             WHERE i.con_id(+) = t.con_id
               AND i.table_owner(+) = t.owner
               AND i.table_name(+) = t.table_name
               AND ts.con_id = t.con_id
               AND ts.tablespace_name = t.tablespace_name
               AND u.con_id = t.con_id
               AND u.username = t.owner
               AND s.con_id = t.con_id
               AND s.owner = t.owner
               AND s.segment_name = t.table_name
               AND s.tablespace_name = t.tablespace_name 
               AND l.con_id(+) = t.con_id
               AND l.owner(+) = t.owner
               AND l.table_name(+) = t.table_name
               AND l.tablespace_name(+) = t.tablespace_name 
               -- table + indexes + lobs < tablespace available
               --AND (s.bytes + NVL(i.sum_bytes, 0))/POWER(2,30) < ts.max_size_gbs - ts.used_space_gbs
               AND (s.bytes + NVL(i.sum_bytes, 0) + NVL(l.bytes, 0))/POWER(2,30) < ts.max_size_gbs - ts.used_space_gbs
               -- used_space + table + indexes + lobs < tablespace threshold
               -- this predicate is needed so a table redef does not push the hwm on ts beyond utilization threshold causing then an alert
               AND 100 * (ts.used_space_gbs + (s.bytes + NVL(i.sum_bytes, 0) + NVL(l.bytes, 0))/POWER(2,30)) / ts.max_size_gbs < l_min_ts_used_percent
               AND o.con_id = t.con_id
               AND o.owner = t.owner
               AND o.object_name = t.table_name
               AND c.con_id = t.con_id
               AND lg.con_id(+) = i.con_id
               AND mv.con_id(+) = i.con_id
               AND tb.con_id(+) = i.con_id
               -- ORA-32792: prebuilt table managed column cannot be an identity column
               AND NOT EXISTS ( SELECT /*+ NO_MERGE QB_NAME(identity2) */ NULL 
                                  FROM identity_columns ic
                                 WHERE ic.con_id = t.con_id
                                   AND ic.owner = t.owner
                                   AND ic.table_name = t.table_name
                              )
            ),
            -- replace v$sql_plan with dba_hist_sql_plan since former causes a scan on X$KQLFXPL to hang (ref: 2201867.1 22655916 19875836)
            full_scan AS (
            SELECT /*+ MATERIALIZE NO_MERGE GATHER_PLAN_STATISTICS QB_NAME(full_scan) */
                   p.con_id,
                   p.object_owner owner, 
                   p.object_name table_name,
                   'Y' full_scan
              FROM dba_hist_sql_plan p -- v$sql_plan p
             WHERE p.object_owner <> 'SYS'
               AND p.operation = 'TABLE ACCESS'
               AND p.options = 'FULL'
               AND p.dbid = l_dbid
             GROUP BY
                   p.con_id,
                   p.object_owner, 
                   p.object_name
            )
            SELECT rc.con_id, 
                   rc.pdb_name,
                   rc.owner,
                   rc.table_name,
                   rc.tablespace_name,
                   rc.num_rows,
                   rc.avg_row_len,
                   rc.pct_free,
                   rc.block_size,
                   rc.compression,
                   rc.compress_for,
                   rc.table_size_mbs,
                   rc.index_count,
                   rc.unique_indexes,
                   rc.all_index_size_mbs,
                   rc.top_index_size_mbs,
                   rc.lobs_count,
                   rc.all_lobs_size_mbs,
                   rc.ts_used_space_gbs,
                   rc.ts_max_size_gbs,
                   rc.ts_used_percent,
                   NVL(fs.full_scan, 'N') full_scan,
                   rc.created
              FROM rebuild_candidate rc,
                   full_scan fs
             WHERE (rc.index_count = 0 OR rc.unique_indexes > 0) -- skip tables with indexes but with no unique indexes, to workaround ORA-00600: internal error code, arguments: [kkzumcoval: Primary Key not found] bug 19529868
               AND rc.redef_log_cnt = 0 -- skip candiadates from pdb that has table redefinition materialized view logs
               AND rc.redef_mv_cnt = 0 -- skip candiadates from pdb that has table redefinition materialized views
               AND rc.redef_tbl_cnt = 0 -- skip candiadates from pdb that has table redefinition materialized view tables
               AND fs.con_id(+) = rc.con_id
               AND fs.owner(+) = rc.owner
               AND fs.table_name(+) = rc.table_name
             ORDER BY
                   MOD(rc.table_size_mbs, 10), -- randomize table selection
                   MOD(rc.all_index_size_mbs, 10)) -- randomize table selection
  LOOP
    l_table_redefinition_hist_rec := NULL;
    l_table_redefinition_hist_rec.pdb_name := i.pdb_name;
    l_table_redefinition_hist_rec.owner := i.owner;
    l_table_redefinition_hist_rec.table_name := i.table_name;
    l_table_redefinition_hist_rec.tablespace_name := i.tablespace_name;
    l_table_redefinition_hist_rec.full_scan := i.full_scan;
    l_table_redefinition_hist_rec.ddl_statement := NULL;
    l_table_redefinition_hist_rec.error_message := NULL;
    l_table_redefinition_hist_rec.table_size_mbs_before := ROUND(i.table_size_mbs, 3);
    l_table_redefinition_hist_rec.table_size_mbs_after := NULL;
    l_table_redefinition_hist_rec.index_count := i.index_count;
    l_table_redefinition_hist_rec.all_index_size_mbs_before := ROUND(i.all_index_size_mbs, 3);
    l_table_redefinition_hist_rec.all_index_size_mbs_after := NULL;
    l_table_redefinition_hist_rec.top_index_size_mbs_before := ROUND(i.top_index_size_mbs, 3);
    l_table_redefinition_hist_rec.top_index_size_mbs_after := NULL;
    l_table_redefinition_hist_rec.lobs_count := i.lobs_count;
    l_table_redefinition_hist_rec.all_lobs_size_mbs_before := ROUND(i.all_lobs_size_mbs, 3);
    l_table_redefinition_hist_rec.all_lobs_size_mbs_after := NULL;
    l_table_redefinition_hist_rec.ddl_begin_time := NULL;
    l_table_redefinition_hist_rec.ddl_end_time := NULL;
    l_table_redefinition_hist_rec.snap_time := l_snap_time; -- all rows get the same date so we can easily aggregate for reporting
    l_table_redefinition_hist_rec.con_id := i.con_id;  
    --
    IF l_table_redefinition_hist_rec.full_scan = 'Y' OR 
       l_only_if_ref_by_full_scans = 'N' OR 
       l_table_redefinition_hist_rec.top_index_size_mbs_before > l_table_redefinition_hist_rec.table_size_mbs_before -- bloated index such as KT
    THEN
      output('-- ');
      output('-- '||TO_CHAR(SYSDATE, gk_date_format));
      output('-- pdb:'||l_table_redefinition_hist_rec.pdb_name||'('||l_table_redefinition_hist_rec.con_id||'). tbl:'||l_table_redefinition_hist_rec.owner||'.'||l_table_redefinition_hist_rec.table_name||'. created:'||TO_CHAR(i.created,gk_date_format)||'. fs:'||l_table_redefinition_hist_rec.full_scan||
             '. lobs:'||NVL(l_table_redefinition_hist_rec.lobs_count,0)||'. all_lobs:'||NVL(l_table_redefinition_hist_rec.all_lobs_size_mbs_before,0)||'MBs. idx:'||l_table_redefinition_hist_rec.index_count||'. all_idx:'||l_table_redefinition_hist_rec.all_index_size_mbs_before||'MBs. top_idx:'||l_table_redefinition_hist_rec.top_index_size_mbs_before||'MBs.');
      IF i.compression = 'ENABLED' THEN
        output('-- compression:'||i.compress_for);
      END IF;
      --
      l_statement := 
      q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
      q'[DBMS_SPACE.CREATE_TABLE_COST(:tablespace_name,:avg_row_size,:row_count,:pct_free,:used_bytes,:alloc_bytes); ]'||CHR(10)||
      q'[COMMIT; END;]';
      l_cursor_id := DBMS_SQL.OPEN_CURSOR;
      BEGIN
        DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_table_redefinition_hist_rec.pdb_name);
        DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':tablespace_name', value => l_table_redefinition_hist_rec.tablespace_name);
        DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':avg_row_size', value => i.avg_row_len);
        DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':row_count', value => i.num_rows);
        DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':pct_free', value => i.pct_free);
        DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':used_bytes', value => l_used_bytes);
        DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':alloc_bytes', value => l_alloc_bytes);
        l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
        DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':used_bytes', value => l_used_bytes);
        DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':alloc_bytes', value => l_alloc_bytes);
      EXCEPTION
        WHEN OTHERS THEN
          l_table_redefinition_hist_rec.error_message := '*** '||SQLERRM||' *** DBMS_SPACE.CREATE_TABLE_COST by &&1..IOD_SPACE.table_redefinition';
          insert_table_redefinition_hist;
          output('-- '||l_table_redefinition_hist_rec.error_message, p_alert_log => 'Y');
          DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
          RAISE;
      END;
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
      --
      l_estimated_size_mbs_after := NVL(ROUND(l_alloc_bytes / POWER(2,20), 3), 0);
      l_savings_percent := ROUND(100 * (l_table_redefinition_hist_rec.table_size_mbs_before - l_estimated_size_mbs_after) / l_table_redefinition_hist_rec.table_size_mbs_before, 1);
      output('-- table before:'||l_table_redefinition_hist_rec.table_size_mbs_before||'MBs. estimate:'||l_estimated_size_mbs_after||'MBs. diff:'||(l_table_redefinition_hist_rec.table_size_mbs_before - l_estimated_size_mbs_after)||'MBs. savings:'||l_savings_percent||'%.');
      --
      IF (l_savings_percent > l_min_savings_perc OR l_table_redefinition_hist_rec.top_index_size_mbs_before > l_table_redefinition_hist_rec.table_size_mbs_before) AND l_report_only = 'Y' THEN
        l_table_count := l_table_count + 1;
        l_size_mbs_before := ROUND(l_size_mbs_before + l_table_redefinition_hist_rec.table_size_mbs_before, 3);
        l_size_mbs_after := ROUND(l_size_mbs_after + l_estimated_size_mbs_after, 3);
      END IF;
      -- 
      IF (l_savings_percent > l_min_savings_perc OR l_table_redefinition_hist_rec.top_index_size_mbs_before > l_table_redefinition_hist_rec.table_size_mbs_before) AND l_report_only = 'N' THEN
        IF l_table_count > 0 AND l_sleep_seconds > 0 THEN
          DBMS_APPLICATION_INFO.SET_ACTION('NEXT->'||l_table_redefinition_hist_rec.table_name||'('||l_table_redefinition_hist_rec.con_id||')');
          output('-- sleep '||l_sleep_seconds||'s');
          DBMS_LOCK.SLEEP(l_sleep_seconds);
        END IF; -- l_table_count > 0
        -- 
        l_statement := 
        q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
        q'[:return := DBMS_LOCK.REQUEST(id=>666,lockmode=>DBMS_LOCK.X_MODE,timeout=>0,release_on_commit=>FALSE); ]'||CHR(10)||
        q'[COMMIT; END;]';
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        BEGIN
          DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_table_redefinition_hist_rec.pdb_name);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':return', value => l_return);
          l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
          DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':return', value => l_return);
        EXCEPTION
          WHEN OTHERS THEN
            l_table_redefinition_hist_rec.error_message := '*** '||SQLERRM||' *** DBMS_LOCK.REQUEST by &&1..IOD_SPACE.table_redefinition';
            insert_table_redefinition_hist;
            output('-- '||l_table_redefinition_hist_rec.error_message, p_alert_log => 'Y');
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        IF l_return > 0 THEN -- time to kill
          l_table_redefinition_hist_rec.error_message := '*** KILLED ***';
          insert_table_redefinition_hist;
          output('-- '||l_table_redefinition_hist_rec.error_message);
          EXIT;
        END IF; -- l_return > 0
        -- 
        l_statement := 
        q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
        q'[:return := DBMS_LOCK.RELEASE(id=>666); ]'||CHR(10)||
        q'[COMMIT; END;]';
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        BEGIN
          DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_table_redefinition_hist_rec.pdb_name);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':return', value => l_return);
          l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
          DBMS_SQL.VARIABLE_VALUE(c => l_cursor_id, name => ':return', value => l_return);
        EXCEPTION
          WHEN OTHERS THEN
            l_table_redefinition_hist_rec.error_message := '*** '||SQLERRM||' *** DBMS_LOCK.RELEASE by &&1..IOD_SPACE.table_redefinition';
            insert_table_redefinition_hist;
            output('-- '||l_table_redefinition_hist_rec.error_message, p_alert_log => 'Y');
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        IF l_return > 0 THEN -- time to kill
          l_table_redefinition_hist_rec.error_message := '*** KILLED ***';
          insert_table_redefinition_hist;
          output('-- '||l_table_redefinition_hist_rec.error_message||' by &&1..IOD_SPACE.table_redefinition', p_alert_log => 'Y');
          EXIT;
        END IF; -- l_return > 0
        --
        DBMS_APPLICATION_INFO.SET_ACTION('ON->'||l_table_redefinition_hist_rec.table_name||'('||l_table_redefinition_hist_rec.con_id||')');
        l_table_redefinition_hist_rec.ddl_statement := q'[DBMS_REDEFINITION.REDEF_TABLE(uname => :uname, tname => :tname, table_part_tablespace => :table_part_tablespace); ]';
        l_statement := 
        q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
        l_table_redefinition_hist_rec.ddl_statement||CHR(10)||
        q'[COMMIT; END;]';
        l_table_redefinition_hist_rec.ddl_statement := REPLACE(l_table_redefinition_hist_rec.ddl_statement, ':uname', ''''||l_table_redefinition_hist_rec.owner||'''');
        l_table_redefinition_hist_rec.ddl_statement := REPLACE(l_table_redefinition_hist_rec.ddl_statement, ':tname', ''''||l_table_redefinition_hist_rec.table_name||'''');
        l_table_redefinition_hist_rec.ddl_statement := REPLACE(l_table_redefinition_hist_rec.ddl_statement, ':table_part_tablespace', ''''||l_table_redefinition_hist_rec.tablespace_name||'''');
        l_table_redefinition_hist_rec.ddl_statement := 'EXEC '||l_table_redefinition_hist_rec.ddl_statement;
        output('-- '||TO_CHAR(SYSDATE, gk_date_format)||' &&1..IOD_SPACE.table_redefinition begin', p_alert_log => 'Y');
        output('ALTER SESSION SET CONTAINER = '||l_table_redefinition_hist_rec.pdb_name||';', p_alert_log => 'Y');
        output(l_table_redefinition_hist_rec.ddl_statement, p_alert_log => 'Y');
        --
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        BEGIN
          l_table_redefinition_hist_rec.ddl_begin_time := SYSDATE;
          DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_table_redefinition_hist_rec.pdb_name);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':uname', value => l_table_redefinition_hist_rec.owner);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':tname', value => l_table_redefinition_hist_rec.table_name);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':table_part_tablespace', value => l_table_redefinition_hist_rec.tablespace_name);
          l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
          l_table_redefinition_hist_rec.ddl_end_time := SYSDATE;
        EXCEPTION
          WHEN OTHERS THEN
            -- with any error you want to drop MV log, MV and REDEF table
            -- example: ORA-12083: must use DROP MATERIALIZED VIEW to drop "user"."REDEF$_Tnnnnn", or ORA-00060: deadlock detected while waiting for resource
            --l_table_redefinition_hist_rec.error_message := '***'||CHR(10)||'*** ORA-20000: must use DROP MATERIALIZED VIEW LOG ON to drop first "'||l_table_redefinition_hist_rec.owner||'"."'||l_table_redefinition_hist_rec.table_name||'"'||CHR(10)||'*** '||SQLERRM||CHR(10)||'*** And must use last DROP TABLE to drop staging REDEF$_Tnnnnn table.'||CHR(10)||'***';
            l_table_redefinition_hist_rec.error_message := SQLERRM;
            l_table_redefinition_hist_rec.ddl_end_time := SYSDATE;
            insert_table_redefinition_hist;
            output('*** &&1..IOD_SPACE.table_redefinition DBMS_REDEFINITION.REDEF_TABLE failed', p_alert_log => 'Y');
            output(l_table_redefinition_hist_rec.error_message, p_alert_log => 'Y');
            output('---', p_alert_log => 'Y');
            output('--- Remediation steps (replace "nnnnn"):', p_alert_log => 'Y');
            output('--- 1. ALTER SESSION SET CONTAINER = '||l_table_redefinition_hist_rec.pdb_name||';', p_alert_log => 'Y');
            output('--- 2. DROP MATERIALIZED VIEW LOG ON '||l_table_redefinition_hist_rec.owner||'.'||l_table_redefinition_hist_rec.table_name||';', p_alert_log => 'Y');
            output('--- 3. SELECT mview_name FROM dba_mviews WHERE owner = '''||l_table_redefinition_hist_rec.owner||''';', p_alert_log => 'Y');
            output('--- 4. DROP MATERIALIZED VIEW '||l_table_redefinition_hist_rec.owner||'.REDEF$_Tnnnnn;', p_alert_log => 'Y');
            output('--- 5. DROP TABLE '||l_table_redefinition_hist_rec.owner||'.REDEF$_Tnnnnn;', p_alert_log => 'Y');
            output('---', p_alert_log => 'Y');
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        output('-- '||TO_CHAR(SYSDATE, gk_date_format)||' &&1..IOD_SPACE.table_redefinition end', p_alert_log => 'Y');
        l_statement := 'SELECT bytes FROM dba_segments WHERE owner = :owner AND segment_name = :segment_name AND segment_type = ''TABLE''';
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        BEGIN
          DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_table_redefinition_hist_rec.pdb_name);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':owner', value => l_table_redefinition_hist_rec.owner);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':segment_name', value => l_table_redefinition_hist_rec.table_name);
          DBMS_SQL.DEFINE_COLUMN(c => l_cursor_id, position => 1, column => l_bytes_after);
          l_rows := DBMS_SQL.EXECUTE_AND_FETCH(c => l_cursor_id, exact => TRUE);
          DBMS_SQL.COLUMN_VALUE(c => l_cursor_id, position => 1, value => l_bytes_after);
        EXCEPTION
          WHEN OTHERS THEN
            l_table_redefinition_hist_rec.error_message := '*** '||SQLERRM||' *** SELECT blocks FROM dba_segments by &&1..IOD_SPACE.table_redefinition';
            output('-- '||l_table_redefinition_hist_rec.error_message, p_alert_log => 'Y');
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        l_table_redefinition_hist_rec.table_size_mbs_after := NVL(ROUND(l_bytes_after / POWER(2,20), 3), 0);
        l_savings_percent := ROUND(100 * (l_table_redefinition_hist_rec.table_size_mbs_before - l_table_redefinition_hist_rec.table_size_mbs_after) / l_table_redefinition_hist_rec.table_size_mbs_before, 1);
        output('-- table before:'||l_table_redefinition_hist_rec.table_size_mbs_before||'MBs. after:'||l_table_redefinition_hist_rec.table_size_mbs_after||'MBs. diff:'||(l_table_redefinition_hist_rec.table_size_mbs_before - l_table_redefinition_hist_rec.table_size_mbs_after)||'MBs. savings:'||l_savings_percent||'%.');
        --
        l_statement := 
        q'[DECLARE PRAGMA AUTONOMOUS_TRANSACTION; BEGIN ]'||CHR(10)||
        q'[DBMS_STATS.GATHER_TABLE_STATS(:ownname,:tabname); ]'||CHR(10)||
        q'[COMMIT; END;]';
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        BEGIN
          DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_table_redefinition_hist_rec.pdb_name);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':ownname', value => l_table_redefinition_hist_rec.owner);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':tabname', value => l_table_redefinition_hist_rec.table_name);
          l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
        EXCEPTION
          WHEN OTHERS THEN
            l_table_redefinition_hist_rec.error_message := '*** '||SQLERRM||' *** DBMS_STATS.GATHER_TABLE_STATS by &&1..IOD_SPACE.table_redefinition';
            insert_table_redefinition_hist;
            output('-- '||l_table_redefinition_hist_rec.error_message, p_alert_log => 'Y');
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        -- 
        l_statement := 
        q'[SELECT /*+ iod_space.table_redefinition */ ]'||CHR(10)||
        q'[       SUM(s.bytes) bytes ]'||CHR(10)||
        q'[  FROM dba_lobs l, ]'||CHR(10)||
        q'[       dba_segments s ]'||CHR(10)||
        q'[ WHERE l.owner <> 'SYS' ]'||CHR(10)||
        q'[   AND l.owner = :owner ]'||CHR(10)||
        q'[   AND l.table_name = :table_name ]'||CHR(10)||
        q'[   AND s.owner = l.owner ]'||CHR(10)||
        q'[   AND s.segment_name = l.segment_name ]'||CHR(10)||
        q'[   AND s.tablespace_name = l.tablespace_name ]'||CHR(10)||
        q'[   AND s.segment_type = 'LOBSEGMENT' ]';
        --
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        BEGIN
          l_sum_bytes_after := 0;
          DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_table_redefinition_hist_rec.pdb_name);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':owner', value => l_table_redefinition_hist_rec.owner);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':table_name', value => l_table_redefinition_hist_rec.table_name);
          DBMS_SQL.DEFINE_COLUMN(c => l_cursor_id, position => 1, column => l_sum_bytes_after);
          l_rows := DBMS_SQL.EXECUTE_AND_FETCH(c => l_cursor_id, exact => TRUE);
          DBMS_SQL.COLUMN_VALUE(c => l_cursor_id, position => 1, value => l_sum_bytes_after);
          l_sum_bytes_after := NVL(l_sum_bytes_after, 0);
        EXCEPTION
          WHEN OTHERS THEN
            l_table_redefinition_hist_rec.error_message := '*** '||SQLERRM||' *** SELECT SUM(s.bytes) bytes FROM dba_lobs l, dba_segments s... by &&1..IOD_SPACE.table_redefinition';
            output('-- '||l_table_redefinition_hist_rec.error_message, p_alert_log => 'Y');
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        l_table_redefinition_hist_rec.all_lobs_size_mbs_after := NVL(ROUND(l_sum_bytes_after / POWER(2,20), 3), 0);
        --
        l_statement := 
        q'[SELECT /*+ iod_space.table_redefinition */ ]'||CHR(10)||
        q'[       SUM(s.bytes), MAX(s.bytes) ]'||CHR(10)||
        q'[  FROM dba_indexes i, dba_segments s ]'||CHR(10)||
        q'[ WHERE i.table_owner = :owner ]'||CHR(10)||
        q'[   AND i.table_name = :table_name ]'||CHR(10)||
        q'[   AND (i.index_type LIKE '%NORMAL%' OR i.index_type = 'LOB') ]'||CHR(10)||
        q'[   AND i.table_owner <> 'SYS' ]'||CHR(10)||
        q'[   AND i.tablespace_name NOT IN ('SYSTEM','SYSAUX') ]'||CHR(10)||
        q'[   AND i.table_type = 'TABLE' ]'||CHR(10)||
        q'[   AND i.status = 'VALID' ]'||CHR(10)||
        q'[   AND i.partitioned = 'NO' ]'||CHR(10)||
        q'[   AND i.temporary = 'N' ]'||CHR(10)||
        q'[   AND i.dropped = 'NO' ]'||CHR(10)||
        q'[   AND i.visibility = 'VISIBLE' ]'||CHR(10)||
        q'[   AND i.segment_created = 'YES' ]'||CHR(10)||
        q'[   AND s.owner = i.owner ]'||CHR(10)||
        q'[   AND s.segment_name = i.index_name ]'||CHR(10)||
        q'[   AND s.segment_type IN ('INDEX', 'LOBINDEX') ]';
        --
        l_cursor_id := DBMS_SQL.OPEN_CURSOR;
        BEGIN
          l_sum_bytes_after := 0;
          l_max_bytes_after := 0;
          DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => l_table_redefinition_hist_rec.pdb_name);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':owner', value => l_table_redefinition_hist_rec.owner);
          DBMS_SQL.BIND_VARIABLE(c => l_cursor_id, name => ':table_name', value => l_table_redefinition_hist_rec.table_name);
          DBMS_SQL.DEFINE_COLUMN(c => l_cursor_id, position => 1, column => l_sum_bytes_after);
          DBMS_SQL.DEFINE_COLUMN(c => l_cursor_id, position => 2, column => l_max_bytes_after);
          l_rows := DBMS_SQL.EXECUTE_AND_FETCH(c => l_cursor_id, exact => TRUE);
          DBMS_SQL.COLUMN_VALUE(c => l_cursor_id, position => 1, value => l_sum_bytes_after);
          DBMS_SQL.COLUMN_VALUE(c => l_cursor_id, position => 2, value => l_max_bytes_after);
          l_sum_bytes_after := NVL(l_sum_bytes_after, 0);
          l_max_bytes_after := NVL(l_max_bytes_after, 0);
        EXCEPTION
          WHEN OTHERS THEN
            l_table_redefinition_hist_rec.error_message := '*** '||SQLERRM||' *** SELECT SUM(s.bytes), MAX(s.bytes) FROM dba_indexes i, dba_segments s... by &&1..IOD_SPACE.table_redefinition';
            output('-- '||l_table_redefinition_hist_rec.error_message, p_alert_log => 'Y');
            DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
            RAISE;
        END;
        DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
        --
        l_table_redefinition_hist_rec.all_index_size_mbs_after := NVL(ROUND(l_sum_bytes_after / POWER(2,20), 3), 0);
        l_table_redefinition_hist_rec.top_index_size_mbs_after := NVL(ROUND(l_max_bytes_after / POWER(2,20), 3), 0);
        --
        IF l_table_redefinition_hist_rec.all_index_size_mbs_before > 0 THEN
          l_savings_percent := ROUND(100 * (l_table_redefinition_hist_rec.all_index_size_mbs_before - l_table_redefinition_hist_rec.all_index_size_mbs_after) / l_table_redefinition_hist_rec.all_index_size_mbs_before, 1);
        ELSE
          l_savings_percent := 0;
        END IF;
        output('-- indexes before:'||l_table_redefinition_hist_rec.all_index_size_mbs_before||'MBs. after:'||l_table_redefinition_hist_rec.all_index_size_mbs_after||'MBs. diff:'||(l_table_redefinition_hist_rec.all_index_size_mbs_before - l_table_redefinition_hist_rec.all_index_size_mbs_after)||'MBs. savings:'||l_savings_percent||'%.');
        --
        IF l_table_redefinition_hist_rec.all_lobs_size_mbs_before > 0 THEN
          l_savings_percent := ROUND(100 * (l_table_redefinition_hist_rec.all_lobs_size_mbs_before - l_table_redefinition_hist_rec.all_lobs_size_mbs_after) / l_table_redefinition_hist_rec.all_lobs_size_mbs_before, 1);
        ELSE
          l_savings_percent := 0;
        END IF;
        output('-- lobs before:'||NVL(l_table_redefinition_hist_rec.all_lobs_size_mbs_before,0)||'MBs. after:'||NVL(l_table_redefinition_hist_rec.all_lobs_size_mbs_after,0)||'MBs. diff:'||NVL((l_table_redefinition_hist_rec.all_lobs_size_mbs_before - l_table_redefinition_hist_rec.all_lobs_size_mbs_after),0)||'MBs. savings:'||NVL(l_savings_percent,0)||'%.');
        --
        IF (l_table_redefinition_hist_rec.table_size_mbs_before + l_table_redefinition_hist_rec.all_index_size_mbs_before) > 0 THEN
          l_savings_percent := ROUND(100 * ((l_table_redefinition_hist_rec.table_size_mbs_before + l_table_redefinition_hist_rec.all_index_size_mbs_before) - (l_table_redefinition_hist_rec.table_size_mbs_after + l_table_redefinition_hist_rec.all_index_size_mbs_after)) / (l_table_redefinition_hist_rec.table_size_mbs_before + l_table_redefinition_hist_rec.all_index_size_mbs_before), 1);
        ELSE
          l_savings_percent := 0;
        END IF;
        output('-- table+indexes+lobs before:'||NVL((l_table_redefinition_hist_rec.table_size_mbs_before + l_table_redefinition_hist_rec.all_index_size_mbs_before + l_table_redefinition_hist_rec.all_lobs_size_mbs_before),0)||'MBs. after:'||NVL((l_table_redefinition_hist_rec.table_size_mbs_after + l_table_redefinition_hist_rec.all_index_size_mbs_after + l_table_redefinition_hist_rec.all_lobs_size_mbs_after),0)||'MBs. diff:'||NVL(((l_table_redefinition_hist_rec.table_size_mbs_before + l_table_redefinition_hist_rec.all_index_size_mbs_before + l_table_redefinition_hist_rec.all_lobs_size_mbs_before) - (l_table_redefinition_hist_rec.table_size_mbs_after + l_table_redefinition_hist_rec.all_index_size_mbs_after + l_table_redefinition_hist_rec.all_lobs_size_mbs_after)),0)||'MBs. savings:'||NVL(l_savings_percent,0)||'%.');
        --         
        insert_table_redefinition_hist;
        --
        l_table_count := l_table_count + 1;
        l_size_mbs_before := NVL(ROUND(l_size_mbs_before + l_table_redefinition_hist_rec.table_size_mbs_before, 3), 0);
        l_size_mbs_after := NVL(ROUND(l_size_mbs_after + l_table_redefinition_hist_rec.table_size_mbs_after, 3), 0);
        l_size_all_mbs_before := NVL(ROUND(l_size_all_mbs_before + (l_table_redefinition_hist_rec.table_size_mbs_before + l_table_redefinition_hist_rec.all_index_size_mbs_before + l_table_redefinition_hist_rec.all_lobs_size_mbs_before), 3), 0);
        l_size_all_mbs_after := NVL(ROUND(l_size_all_mbs_after + (l_table_redefinition_hist_rec.table_size_mbs_after + l_table_redefinition_hist_rec.all_index_size_mbs_after + l_table_redefinition_hist_rec.all_lobs_size_mbs_after), 3), 0);
      END IF; -- l_savings_percent > l_min_savings_perc ... l_report_only = 'N'
    END IF; -- l_table_redefinition_hist_rec.full_scan = 'Y' OR l_only_if_ref_by_full_scans = 'N' OR ...
    --
    IF SYSDATE > l_timeout THEN
      output('-- *** timeout ***');
      EXIT;
    END IF;
    --
  END LOOP;
  output('-- ');
  --
  IF l_table_count > 0 AND l_size_mbs_before > 0 THEN
    l_savings_percent := ROUND(100 * (l_size_mbs_before - l_size_mbs_after) / l_size_mbs_before, 1);
    output('-- ~~~ tables:'||l_table_count||'. before:'||l_size_mbs_before||'MBs. after:'||l_size_mbs_after||'MBs. diff:'||(l_size_mbs_before - l_size_mbs_after)||'MBs. savings:'||l_savings_percent||'%. ~~~');
    IF l_size_all_mbs_before > 0 THEN
      l_savings_percent := ROUND(100 * (l_size_all_mbs_before - l_size_all_mbs_after) / l_size_all_mbs_before, 1);
      output('-- ~~~ tables+indexes:. before:'||l_size_all_mbs_before||'MBs. after:'||l_size_all_mbs_after||'MBs. diff:'||(l_size_all_mbs_before - l_size_all_mbs_after)||'MBs. savings:'||l_savings_percent||'%. ~~~');
    END IF;
  END IF;
  IF l_table_count = 0 THEN
    output('-- ~~~ nothing to do! ~~~');
  END IF;
  output('-- ');
  -- validate there are no table redefinition materialized view logs
  l_count := 0;
  output('-- cdb_mview_logs validation (table redefinition materialized view logs)');
  FOR i IN (SELECT c.name pdb_name,
                   c.con_id,
                   lg.log_owner,
                   lg.master
              FROM cdb_mview_logs lg,
                   v$containers c
             WHERE lg.log_table LIKE 'MLOG$\_'||CHR(37) ESCAPE '\'
               AND c.con_id = lg.con_id
               AND c.open_mode = 'READ WRITE'
               AND (l_pdb_name IS NULL OR c.name = l_pdb_name)
             ORDER BY
                   c.name,
                   lg.log_owner,
                   lg.master)
  LOOP
    l_count := l_count + 1;
    output('pdb:'||i.pdb_name||'('||i.con_id||') log_owner:'||i.log_owner||' master:'||i.master);
  END LOOP;
  --
  -- validate there are no table redefinition materialized views
  output('-- cdb_mviews validation (table redefinition materialized views)');
  FOR i IN (SELECT c.name pdb_name,
                   c.con_id,
                   mv.owner,
                   mv.mview_name
              FROM cdb_mviews mv,
                   v$containers c
             WHERE mv.mview_name LIKE 'REDEF$\_T'||CHR(37) ESCAPE '\'
               AND c.con_id = mv.con_id
               AND c.open_mode = 'READ WRITE'
               AND (l_pdb_name IS NULL OR c.name = l_pdb_name)
             ORDER BY
                   c.name,
                   mv.owner,
                   mv.mview_name)
  LOOP
    l_count := l_count + 1;
    output('pdb:'||i.pdb_name||'('||i.con_id||') owner:'||i.owner||' mview_name:'||i.mview_name);
  END LOOP;
  -- validate there are no table redefinition materialized view tables
  output('-- cdb_tables validation (table redefinition materialized view tables)');
  FOR i IN (SELECT c.name pdb_name,
                   c.con_id,
                   tb.owner,
                   tb.table_name
              FROM cdb_tables tb,
                   v$containers c
             WHERE tb.table_name LIKE 'REDEF$\_T'||CHR(37) ESCAPE '\'
               AND c.con_id = tb.con_id
               AND c.open_mode = 'READ WRITE'
               AND (l_pdb_name IS NULL OR c.name = l_pdb_name)
             ORDER BY
                   c.name,
                   tb.owner,
                   tb.table_name)
  LOOP
    l_count := l_count + 1;
    output('pdb:'||i.pdb_name||'('||i.con_id||') owner:'||i.owner||' table_name:'||i.table_name);
  END LOOP;
  output('-- ');
  -- exit if there are unexpected objects from a failed or inflight table redefinition
  IF l_count > 0 THEN
    output('*** &&1..IOD_SPACE.table_redefinition failed. There are '||l_count||' unexpected schema objects from a failed or inflight table redefinition.', p_alert_log => 'Y');
    raise_application_error(-20000, 'There are '||l_count||' unexpected schema objects from a failed or inflight table redefinition.');
  END IF;
  --  
  -- drop partitions with data older than 12 months (i.e. preserve between 12 and 13 months of history)
  IF l_report_only = 'N' THEN
    FOR i IN (
      SELECT partition_name, high_value, blocks
        FROM dba_tab_partitions
       WHERE table_owner = UPPER('&&1.')
         AND table_name = 'TABLE_REDEFINITION_HIST'
       ORDER BY
             partition_name
    )
    LOOP
      EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
      output('-- PARTITION:'||RPAD(SUBSTR(i.partition_name, 1, 30), 32)||'HIGH_VALUE:'||TO_CHAR(l_high_value, gk_date_format)||'  BLOCKS:'||i.blocks);
      IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -12) THEN
        output('-- &&1..IOD_SPACE.table_redefinition: ALTER TABLE &&1..table_redefinition_hist DROP PARTITION '||i.partition_name, p_alert_log => 'Y');
        EXECUTE IMMEDIATE q'[ALTER TABLE &&1..table_redefinition_hist SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
        EXECUTE IMMEDIATE 'ALTER TABLE &&1..table_redefinition_hist DROP PARTITION '||i.partition_name;
      END IF;
    END LOOP;
  END IF;
  -- count
  SELECT COUNT(*)
    INTO l_count
    FROM &&1..table_redefinition_hist;
  output('-- &&1..table_redefinition_hist end count: '||l_count);
  --
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
  output('-- end &&1..IOD_SPACE.table_redefinition '||TO_CHAR(SYSDATE, gk_date_format));
END table_redefinition;
/* ------------------------------------------------------------------------------------ */
PROCEDURE purge_recyclebin (
  p_preserve_recyclebin_days  IN NUMBER   DEFAULT gk_preserve_recyclebin_days,
  p_timeout                   IN DATE     DEFAULT SYSDATE + (gk_timeout_hours/24),
  p_pdb_name                  IN VARCHAR2 DEFAULT NULL
)
IS
  l_preserve_recyclebin_days NUMBER := NVL(p_preserve_recyclebin_days, gk_preserve_recyclebin_days);
  l_timeout DATE := NVL(p_timeout,(SYSDATE + (gk_timeout_hours/24)));
  l_pdb_name VARCHAR2(128) := UPPER(TRIM(p_pdb_name));
  l_cursor_id INTEGER;
  l_statement CLOB;
  l_rows INTEGER;
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_dbid NUMBER;
  l_bin NUMBER;
  l_gbs NUMBER;
BEGIN
  SELECT dbid, name, open_mode INTO l_dbid, l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output('-- *** to be executed only on DG primary ***');
    RETURN;
  END IF;
  --
  IF SYSDATE > l_timeout THEN
    output('-- *** timeout ***');
    RETURN;
  END IF;
  --
  output('-- begin &&1..IOD_SPACE.purge_recyclebin '||TO_CHAR(SYSDATE, gk_date_format));
  output('-- timeout:'||TO_CHAR(l_timeout, gk_date_format));
  output('-- ');
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SPACE.purge_recyclebin','PURGE_RECYCLEBIN');
  --
  l_statement := q'[
  DECLARE 
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    /* non identity tables (and their indexes) */
    FOR i IN (SELECT DISTINCT rb.type, rb.owner, rb.original_name, rb.object_name
                FROM dba_recyclebin rb,
                     sys.obj$ o1
               WHERE TO_DATE(rb.droptime, 'YYYY-MM-DD:HH24:MI:SS') < SYSDATE - 8
                 AND rb.type = 'TABLE'
                 AND o1.name = rb.object_name
                 /* exclude identity */
                 AND NOT EXISTS (SELECT NULL FROM sys.idnseq$ id WHERE id.obj# = o1.obj#))
     LOOP
      DBMS_OUTPUT.PUT_LINE(i.type||' '||i.owner||'.'||i.original_name||' '||i.object_name);
      EXECUTE IMMEDIATE 'PURGE '||i.type||' '||i.owner||'.'||i.original_name;
    END LOOP;
    /* non identity (stand-alone indexes) */
    FOR i IN (SELECT DISTINCT rb.type, rb.owner, rb.original_name, rb.object_name
                FROM dba_recyclebin rb,
                     sys.obj$ o1
               WHERE TO_DATE(rb.droptime, 'YYYY-MM-DD:HH24:MI:SS') < SYSDATE - 8
                 AND rb.type = 'INDEX'
                 AND o1.name = rb.object_name
                 /* exclude identity */
                 AND NOT EXISTS (SELECT NULL FROM sys.idnseq$ id WHERE id.obj# = o1.obj#))
     LOOP
      DBMS_OUTPUT.PUT_LINE(i.type||' '||i.owner||'.'||i.original_name||' '||i.object_name);
      DECLARE
        l_unique_or_primary EXCEPTION;
        PRAGMA EXCEPTION_INIT(l_unique_or_primary, -02429); /* ORA-02429: cannot drop index used for enforcement of unique/primary key */
      BEGIN
        EXECUTE IMMEDIATE 'PURGE '||i.type||' '||i.owner||'.'||i.original_name;
      EXCEPTION
        WHEN l_unique_or_primary THEN
          DBMS_OUTPUT.PUT_LINE(SQLERRM);
      END;
    END LOOP;
    /* identity tables (and their indexes) */
    FOR i IN (SELECT DISTINCT rb.type, rb.owner, rb.original_name, rb.object_name
                FROM dba_recyclebin rb,
                     sys.obj$ o1, 
                     sys.idnseq$ id,
                     sys.obj$ o2
               WHERE TO_DATE(rb.droptime, 'YYYY-MM-DD:HH24:MI:SS') < SYSDATE - 8
                 AND rb.type = 'TABLE'
                 AND o1.name = rb.object_name
                 AND id.obj# = o1.obj#
                 AND o2.obj# = id.seqobj#) /* ORA-00600: internal error code, arguments: [12811], [91945] -- bug 19949998 */
    LOOP
      DBMS_OUTPUT.PUT_LINE(i.type||' '||i.owner||'.'||i.original_name||' '||i.object_name);
      EXECUTE IMMEDIATE 'PURGE '||i.type||' '||i.owner||'.'||i.original_name;
    END LOOP;
    /* identity tables (and their indexes) ORA-00600 */
    FOR i IN (SELECT DISTINCT rb.type, rb.owner, rb.original_name, rb.object_name
                FROM dba_recyclebin rb,
                     sys.obj$ o1, 
                     sys.idnseq$ id,
                     sys.obj$ o2
               WHERE TO_DATE(rb.droptime, 'YYYY-MM-DD:HH24:MI:SS') < SYSDATE - 8
                 AND rb.type = 'TABLE'
                 AND o1.name = rb.object_name
                 AND id.obj# = o1.obj#
                 AND o2.obj#(+) = id.seqobj#) /* ORA-00600: internal error code, arguments: [12811], [91945] -- bug 19949998 */
    LOOP
      DBMS_OUTPUT.PUT_LINE(i.type||' '||i.owner||'.'||i.original_name||' '||i.object_name);
      DBMS_OUTPUT.PUT_LINE('ORA-00600: internal error code, arguments: [12811], [91945] -- bug 19949998');
      /*EXECUTE IMMEDIATE 'PURGE '||i.type||' '||i.owner||'.'||i.original_name;*/
    END LOOP;
    COMMIT;
  END;
  ]';
  l_statement := REPLACE(l_statement, '- 8', '- '||l_preserve_recyclebin_days);
  --
  SELECT COUNT(*), ROUND(SUM(bytes)/POWER(2,30),3) INTO l_bin, l_gbs FROM cdb_segments WHERE segment_name LIKE 'BIN$%';
  output('-- '||TO_CHAR(SYSDATE, gk_date_format)||' bin$ segments count:'||l_bin||'. space:'||l_gbs||'GBs.');
  --
  FOR i IN (SELECT c.con_id,
                   c.name pdb_name
              FROM v$containers c
             WHERE c.open_mode = 'READ WRITE'
               AND (l_pdb_name IS NULL OR c.name = l_pdb_name)
             ORDER BY
                   c.name)
  LOOP
    DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SPACE.purge_recyclebin',i.pdb_name||'('||i.con_id||')');
    output('-- '||TO_CHAR(SYSDATE, gk_date_format)||' '||i.pdb_name||'('||i.con_id||')');
    --
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => i.pdb_name);
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    --
    SELECT COUNT(*), ROUND(SUM(bytes)/POWER(2,30),3) INTO l_bin, l_gbs FROM cdb_segments WHERE segment_name LIKE 'BIN$%';
    output('-- '||TO_CHAR(SYSDATE, gk_date_format)||' bin$ segments count:'||l_bin||'. space:'||l_gbs||'GBs.');
    --
    IF SYSDATE > l_timeout THEN
      output('-- *** timeout ***');
      EXIT;
    END IF;
    --
  END LOOP;
  --
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
  output('-- ');
  output('-- end &&1..IOD_SPACE.purge_recyclebin '||TO_CHAR(SYSDATE, gk_date_format));
END purge_recyclebin;
/* ------------------------------------------------------------------------------------ */
PROCEDURE tablespaces_resize
IS
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_dbid NUMBER;
  l_cursor_id INTEGER;
  l_rows NUMBER;
  l_high_value DATE;
  l_tablespace_resize_hist_rec &&1..tablespace_resize_hist%ROWTYPE;
BEGIN
  SELECT dbid, name, open_mode INTO l_dbid, l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output('-- *** to be executed only on DG primary ***');
    RETURN;
  END IF;
  --
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SPACE.tablespaces_resize','TABLESPACES_RESIZE');
  --
  -- main 
  FOR i IN (WITH /*+ iod_space.tablespaces_resize */
            t AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   con_id,
                   tablespace_name,
                   SUM(NVL(bytes, 0)) bytes
              FROM cdb_data_files
             GROUP BY 
                   con_id,
                   tablespace_name
             UNION ALL
            SELECT /*+ MATERIALIZE NO_MERGE */
                   con_id,
                   tablespace_name,
                   SUM(NVL(bytes, 0)) bytes
              FROM cdb_temp_files
             GROUP BY 
                   con_id,
                   tablespace_name
            ),
            u AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   con_id,
                   tablespace_name,
                   SUM(bytes) bytes
              FROM cdb_free_space
             GROUP BY 
                    con_id,
                    tablespace_name
             UNION ALL
            SELECT /*+ MATERIALIZE NO_MERGE */
                   con_id,
                   tablespace_name,
                   NVL(SUM(bytes_used), 0) bytes
              FROM gv$temp_extent_pool
             GROUP BY 
                   con_id,
                   tablespace_name
            ),
            un AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   ts.con_id,
                   ts.tablespace_name,
                   NVL(um.used_space * ts.block_size, 0) bytes
              FROM cdb_tablespaces              ts,
                   cdb_tablespace_usage_metrics um
             WHERE ts.contents           = 'UNDO'
               AND um.tablespace_name(+) = ts.tablespace_name
               AND um.con_id(+)          = ts.con_id
            ),
            oem AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   ts.con_id,
                   pdb.name pdb_name,
                   ts.tablespace_name,
                   ts.contents,
                   ts.status,
                   ts.bigfile,
                   ts.block_size,
                   NVL(t.bytes / POWER(2,30), 0) allocated_space, -- GBs
                   NVL(
                   CASE ts.contents
                   WHEN 'UNDO'         THEN un.bytes
                   WHEN 'PERMANENT'    THEN t.bytes - NVL(u.bytes, 0)
                   WHEN 'TEMPORARY'    THEN
                     CASE ts.extent_management
                     WHEN 'LOCAL'      THEN u.bytes
                     WHEN 'DICTIONARY' THEN t.bytes - NVL(u.bytes, 0)
                     END
                   END 
                   / POWER(2,30), 0) used_space -- GBs
              FROM cdb_tablespaces ts,
                   v$containers    pdb,
                   t,
                   u,
                   un
             WHERE 1 = 1
               AND pdb.con_id            = ts.con_id
               AND pdb.open_mode         = 'READ WRITE'
               AND t.tablespace_name(+)  = ts.tablespace_name
               AND t.con_id(+)           = ts.con_id
               AND u.tablespace_name(+)  = ts.tablespace_name
               AND u.con_id(+)           = ts.con_id
               AND un.tablespace_name(+) = ts.tablespace_name
               AND un.con_id(+)          = ts.con_id
            ),
            candidate_tablespaces AS (
            SELECT o.pdb_name,
                   o.con_id,
                   o.tablespace_name,
                   o.allocated_space oem_allocated_gbs,
                   o.used_space oem_used_space_gbs,
                   100 * o.used_space / o.allocated_space oem_used_percent, -- as per allocated space
                   m.tablespace_size * o.block_size / POWER(2, 30) met_max_size_gbs,
                   m.used_space * o.block_size / POWER(2, 30) met_used_space_gbs,
                   m.used_percent met_used_percent -- as per maximum size (considering auto extend)
              FROM oem                          o,
                   cdb_tablespace_usage_metrics m
             WHERE 1 = 1
               AND o.contents = 'PERMANENT'
               AND o.status = 'ONLINE'
               AND o.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
               AND o.bigfile = 'YES'
               AND m.tablespace_name = o.tablespace_name
               AND m.con_id          = o.con_id
            )
            SELECT pdb_name,
                   con_id,
                   tablespace_name,
                   oem_allocated_gbs,
                   oem_used_space_gbs,
                   oem_used_percent, 
                   met_max_size_gbs,
                   met_used_space_gbs,
                   met_used_percent,
                   CASE
                   WHEN oem_allocated_gbs <    4 AND met_max_size_gbs >    8 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE   8G'
                   WHEN oem_allocated_gbs <    8 AND met_max_size_gbs >   16 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE  16G'
                   WHEN oem_allocated_gbs <   16 AND met_max_size_gbs >   32 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE  32G'
                   WHEN oem_allocated_gbs <   32 AND met_max_size_gbs >   64 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE  64G'
                   WHEN oem_allocated_gbs <   64 AND met_max_size_gbs >  128 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE 128G'
                   WHEN oem_allocated_gbs <  128 AND met_max_size_gbs >  256 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE 256G'
                   WHEN oem_allocated_gbs <  256 AND met_max_size_gbs >  512 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE 512G'
                   WHEN oem_allocated_gbs <  512 AND met_max_size_gbs > 1024 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE   1T'
                   WHEN oem_allocated_gbs < 1024 AND met_max_size_gbs > 2048 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE   2T'
                   WHEN                              met_max_size_gbs <    8 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE   8G'
                   WHEN met_max_size_gbs  >    8 AND met_max_size_gbs <   16 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE  16G'
                   WHEN met_max_size_gbs  >   16 AND met_max_size_gbs <   32 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE  32G'
                   WHEN met_max_size_gbs  >   32 AND met_max_size_gbs <   64 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE  64G'
                   WHEN met_max_size_gbs  >   64 AND met_max_size_gbs <  128 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE 128G'
                   WHEN met_max_size_gbs  >  128 AND met_max_size_gbs <  256 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE 256G'
                   WHEN met_max_size_gbs  >  256 AND met_max_size_gbs <  512 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE 512G'
                   WHEN met_max_size_gbs  >  512 AND met_max_size_gbs < 1024 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE   1T'
                   WHEN met_max_size_gbs  > 1024 AND met_max_size_gbs < 2048 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE   2T'
                   WHEN met_used_percent  >   75 AND met_max_size_gbs =    8 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE  16G'
                   WHEN met_used_percent  >   75 AND met_max_size_gbs =   16 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE  32G'
                   WHEN met_used_percent  >   75 AND met_max_size_gbs =   32 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE  64G'
                   WHEN met_used_percent  >   75 AND met_max_size_gbs =   64 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE 128G'
                   WHEN met_used_percent  >   75 AND met_max_size_gbs =  128 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE 256G'
                   WHEN met_used_percent  >   75 AND met_max_size_gbs =  256 THEN 'ALTER TABLESPACE '||tablespace_name||' AUTOEXTEND ON MAXSIZE 512G'
                   WHEN met_used_percent  >   75 AND met_max_size_gbs >= 512 THEN '*** '||met_max_size_gbs||'G MAX on '||tablespace_name||', and '||ROUND(met_used_percent, 1)||'% is USED ***'
                   END resize_command
              FROM candidate_tablespaces
             ORDER BY
                   pdb_name,
                   tablespace_name
  )
  LOOP
    l_tablespace_resize_hist_rec                      := NULL;
    --
    IF i.resize_command IS NOT NULL THEN
      l_tablespace_resize_hist_rec.pdb_name           := i.pdb_name;
      l_tablespace_resize_hist_rec.tablespace_name    := i.tablespace_name;
      l_tablespace_resize_hist_rec.oem_allocated_gbs  := ROUND(i.oem_allocated_gbs, 3);
      l_tablespace_resize_hist_rec.oem_used_space_gbs := ROUND(i.oem_used_space_gbs, 3);
      l_tablespace_resize_hist_rec.oem_used_percent   := ROUND(i.oem_used_percent, 1);
      l_tablespace_resize_hist_rec.met_max_size_gbs   := ROUND(i.met_max_size_gbs, 3);
      l_tablespace_resize_hist_rec.met_used_space_gbs := ROUND(i.met_used_space_gbs, 3);
      l_tablespace_resize_hist_rec.met_used_percent   := ROUND(i.met_used_percent, 1);
      IF i.resize_command LIKE '***%' THEN
        l_tablespace_resize_hist_rec.error_message    := i.resize_command;
      ELSE
        l_tablespace_resize_hist_rec.ddl_statement    := i.resize_command;
      END IF;
      l_tablespace_resize_hist_rec.snap_time          := SYSDATE;
      l_tablespace_resize_hist_rec.con_id             := i.con_id;
      INSERT INTO &&1..tablespace_resize_hist VALUES l_tablespace_resize_hist_rec;
      COMMIT;
    END IF;
    --
    IF l_tablespace_resize_hist_rec.ddl_statement IS NOT NULL THEN
      output('IOD_SPACE.tablespaces_resize '||l_tablespace_resize_hist_rec.pdb_name||' (was '||ROUND(i.met_max_size_gbs, 3)||' GBs): '||l_tablespace_resize_hist_rec.ddl_statement, p_alert_log => 'Y');
      --
      l_cursor_id := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(c => l_cursor_id, statement => l_tablespace_resize_hist_rec.ddl_statement, language_flag => DBMS_SQL.NATIVE, container => l_tablespace_resize_hist_rec.pdb_name);
      l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
      DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
    END IF;
    --
    IF l_tablespace_resize_hist_rec.error_message IS NOT NULL THEN
      output('IOD_SPACE.tablespaces_resize '||l_tablespace_resize_hist_rec.pdb_name||': '||l_tablespace_resize_hist_rec.error_message, p_alert_log => 'Y');
    END IF;
  END LOOP;
  --
  -- drop partitions with data older than 12 months (i.e. preserve between 12 and 13 months of history)
  FOR i IN (
    SELECT partition_name, high_value, blocks
      FROM dba_tab_partitions
     WHERE table_owner = UPPER('&&1.')
       AND table_name = 'TABLESPACE_RESIZE_HIST'
     ORDER BY
           partition_name
  )
  LOOP
    EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
    output('-- PARTITION:'||RPAD(SUBSTR(i.partition_name, 1, 30), 32)||'HIGH_VALUE:'||TO_CHAR(l_high_value, gk_date_format)||'  BLOCKS:'||i.blocks);
    IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -12) THEN
      output('-- &&1..IOD_SPACE.tablespaces_resize: ALTER TABLE &&1..tablespace_resize_hist DROP PARTITION '||i.partition_name, p_alert_log => 'Y');
      EXECUTE IMMEDIATE q'[ALTER TABLE &&1..tablespace_resize_hist SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
      EXECUTE IMMEDIATE 'ALTER TABLE &&1..tablespace_resize_hist DROP PARTITION '||i.partition_name;
    END IF;
  END LOOP;
  --
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
END tablespaces_resize;
/* ------------------------------------------------------------------------------------ */
PROCEDURE gather_table_stats
IS
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_dbid NUMBER;
  l_statement CLOB;
  l_cursor_id INTEGER;
  l_rows NUMBER;
BEGIN
  SELECT dbid, name, open_mode INTO l_dbid, l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output('-- *** to be executed only on DG primary ***');
    RETURN;
  END IF;
  --
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SPACE.gather_table_stats','GATHER_TABLE_STATS');
  --
  -- main 
  FOR i IN (WITH 
            t AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   con_id,
                   owner,
                   table_name,
                   last_analyzed,
                   num_rows
              FROM cdb_tab_statistics
             WHERE object_type = 'TABLE'
               AND owner <> 'SYS'
               AND owner NOT LIKE 'C##%'
               AND table_name NOT LIKE 'MLOG$%'
               AND table_name NOT LIKE 'BIN$%'
               AND stattype_locked IS NULL
               AND (last_analyzed IS NULL OR NVL(num_rows, 0) BETWEEN 0 AND 10000)
            ),
            m AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   con_id,
                   table_owner,
                   table_name,
                   inserts,
                   deletes
              FROM cdb_tab_modifications
             WHERE NVL(inserts, 0) - NVL(deletes, 0) > 0
            ),
            u AS (
            SELECT /*+ MATERIALIZE NO_MERGE */
                   con_id,
                   username
              FROM cdb_users
             WHERE oracle_maintained = 'N'
            )
            SELECT c.name pdb_name, t.con_id, t.owner, t.table_name,
                   t.last_analyzed, t.num_rows, m.inserts, m.deletes
              FROM t,
                   u,
                   m,
                   v$containers c
             WHERE 1 = 1
               AND u.con_id = t.con_id
               AND u.username = t.owner
               AND m.con_id = t.con_id
               AND m.table_owner = t.owner
               AND m.table_name = t.table_name
               AND (    t.last_analyzed IS NULL
                     OR (NVL(t.num_rows, 0) BETWEEN 0 AND 10000 AND (NVL(m.inserts, 0) - NVL(m.deletes, 0)) > GREATEST(t.num_rows, 1))
                   )
               AND c.con_id = t.con_id
               AND c.open_mode = 'READ WRITE'
             ORDER BY
                   c.name, t.owner, t.table_name)
  LOOP
    output(i.pdb_name||' '||i.owner||'.'||i.table_name||' rows:'||i.num_rows||' ins:'||i.inserts||' del:'||i.deletes||' anlz:'||TO_CHAR(i.last_analyzed, gk_date_format));
    --
    l_cursor_id := DBMS_SQL.OPEN_CURSOR;
    l_statement := 'BEGIN DBMS_STATS.gather_table_stats(ownname => '''||i.owner||''', tabname => '''||i.table_name||''', no_invalidate => FALSE); END;';
    DBMS_SQL.PARSE(c => l_cursor_id, statement => l_statement, language_flag => DBMS_SQL.NATIVE, container => i.pdb_name);
    l_rows := DBMS_SQL.EXECUTE(c => l_cursor_id);
    DBMS_SQL.CLOSE_CURSOR(c => l_cursor_id);
  END LOOP;
  --
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
END gather_table_stats;
/* ------------------------------------------------------------------------------------ */
END iod_space;
/
