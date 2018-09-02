CREATE OR REPLACE PACKAGE BODY &&1..iod_sqlstats AS
/* $Header: iod_sqlstats.pkb.sql &&library_version. carlos.sierra $ */
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
PROCEDURE snapshot (
  p_regression_threshold        IN NUMBER   DEFAULT gk_regression_threshold,
  p_db_aas_threshold            IN NUMBER   DEFAULT gk_db_aas_threshold,
  p_db_us_exe_threshold         IN NUMBER   DEFAULT gk_db_us_exe_threshold,
  p_last_active_time_age_secs   IN NUMBER   DEFAULT gk_last_active_time_age_secs,
  p_last_awr_snapshot_age_secs  IN NUMBER   DEFAULT gk_last_awr_snapshot_age_secs,
  p_instance_startup_age_secs   IN NUMBER   DEFAULT gk_instance_startup_age_secs,
  p_capture_ash_secs            IN NUMBER   DEFAULT gk_capture_ash_secs
)
IS
  l_snap_id NUMBER;
  l_snap_time DATE := SYSDATE;
  l_instance_startup_age_secs NUMBER;
  l_last_awr_snapshot_age_secs NUMBER;
  l_rows_count NUMBER;
  l_high_value DATE;
BEGIN
  output('begin '||TO_CHAR(SYSDATE, gk_date_format));
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SQLSTATS.snapshot','SNAPSHOT');
  --
  SELECT NVL(MAX(snap_id), 0) + 1
    INTO l_snap_id
    FROM &&1..sqlstats_snapshot;
  --
  SELECT /*+ MO_MERGE */
         (l_snap_time - i.startup_time) * 24 * 60 * 60
    INTO l_instance_startup_age_secs
    FROM v$instance i;
  --
  SELECT /*+ MO_MERGE */
         (l_snap_time - CAST(MAX(end_interval_time) AS DATE)) * 24 * 60 * 60
    INTO l_last_awr_snapshot_age_secs
    FROM dba_hist_snapshot
   WHERE dbid = (SELECT dbid FROM v$database)
     AND instance_number = (SELECT instance_number FROM v$instance)
     AND end_interval_time < SYSTIMESTAMP;
  --
  IF l_instance_startup_age_secs < p_instance_startup_age_secs OR l_last_awr_snapshot_age_secs < p_last_awr_snapshot_age_secs THEN
    INSERT INTO &&1..sqlstats_snapshot 
    (snap_id, snap_time, instance_startup_age_secs, last_awr_snapshot_age_secs, rows_count) 
    VALUES 
    (l_snap_id, l_snap_time, l_instance_startup_age_secs, l_last_awr_snapshot_age_secs, 0);
  ELSE
    -- 
    INSERT INTO &&1..sqlstats_hist (
      -- soft pk
      con_id                         ,
      sql_id                         ,
      snap_id                        ,
      snap_time                      ,
      -- columns
      last_active_time               ,
      plan_hash_value                ,
      disk_reads                     ,
      buffer_gets                    ,
      rows_processed                 ,
      fetches                        ,
      executions                     ,
      end_of_fetch_count             ,
      loads                          ,
      version_count                  ,
      invalidations                  ,
      cpu_time                       ,
      elapsed_time                   ,
      application_wait_time          ,
      concurrency_wait_time          ,
      user_io_wait_time              ,
      sharable_mem                   ,
      exact_matching_signature       ,
      delta_disk_reads               ,
      delta_buffer_gets              ,
      delta_rows_processed           ,
      delta_fetch_count              ,
      delta_execution_count          ,
      delta_end_of_fetch_count       ,
      delta_cpu_time                 ,
      delta_elapsed_time             ,
      delta_application_wait_time    ,
      delta_concurrency_time         ,
      delta_user_io_wait_time        ,
      delta_loads                    ,
      delta_invalidations            ,
      -- extension
      pdb_name                       ,
      parsing_schema_name            ,
      instance_startup_age_secs      ,
      last_awr_snapshot_age_secs     
    )
    WITH 
    regressed_sql AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           s.con_id                         ,
           s.sql_id                         ,
           s.last_active_time               ,
           s.plan_hash_value                ,
           s.disk_reads                     ,
           s.buffer_gets                    ,
           s.rows_processed                 ,
           s.fetches                        ,
           s.executions                     ,
           s.end_of_fetch_count             ,
           s.loads                          ,
           s.version_count                  ,
           s.invalidations                  ,
           s.cpu_time                       ,
           s.elapsed_time                   ,
           s.application_wait_time          ,
           s.concurrency_wait_time          ,
           s.user_io_wait_time              ,
           s.sharable_mem                   ,
           s.exact_matching_signature       ,
           s.delta_disk_reads               ,
           s.delta_buffer_gets              ,
           s.delta_rows_processed           ,
           s.delta_fetch_count              ,
           s.delta_execution_count          ,
           s.delta_end_of_fetch_count       ,
           s.delta_cpu_time                 ,
           s.delta_elapsed_time             ,
           s.delta_application_wait_time    ,
           s.delta_concurrency_time         ,
           s.delta_user_io_wait_time        ,
           s.delta_loads                    ,
           s.delta_invalidations            ,
           -- extension
           c.name pdb_name,
           ( SELECT /*+ MO_MERGE */
                    q.parsing_schema_name 
               FROM v$sql q,
                    audit_actions a
              WHERE q.con_id = s.con_id 
                AND q.sql_id = s.sql_id 
                AND q.plan_hash_value = s.plan_hash_value 
                --AND q.parsing_schema_name NOT LIKE 'C##%'
                AND q.parsing_schema_id > 0
                AND q.parsing_user_id > 0
                AND q.object_status = 'VALID'
                AND q.is_obsolete = 'N'
                AND q.is_shareable = 'Y'
                AND q.last_active_time > l_snap_time - 15/24/60 -- active during last 15 mins
                AND a.action = q.command_type
                AND a.name NOT IN ('PL/SQL EXECUTE', 'EXECUTE PROCEDURE')
              ORDER BY 
                    q.elapsed_time DESC 
              FETCH FIRST 1 ROW ONLY
           ) parsing_schema_name
      FROM v$sqlstats s,
           v$containers c
     WHERE s.executions > 0 -- since instance starup
       AND s.delta_elapsed_time / GREATEST(s.delta_execution_count, 1) > p_db_us_exe_threshold -- minimum microseconds of database time per execution from last awr to capture sql (1000 us = 1 ms)
       AND s.last_active_time > l_snap_time - (p_last_active_time_age_secs / 24 / 60 / 60) -- active during last N seconds
       AND s.sql_text NOT LIKE '/* SQL Analyze(%' -- sys sql
       AND UPPER(s.sql_text) NOT LIKE 'BEGIN%' -- anonymous pl/sql blocks
       AND (    (s.delta_elapsed_time / GREATEST(s.delta_execution_count, 1) > p_regression_threshold * s.elapsed_time / GREATEST(s.executions, 1))
             OR (s.delta_cpu_time     / GREATEST(s.delta_execution_count, 1) > p_regression_threshold * s.cpu_time     / GREATEST(s.executions, 1))
             OR (s.delta_buffer_gets  / GREATEST(s.delta_execution_count, 1) > p_regression_threshold * s.buffer_gets  / GREATEST(s.executions, 1))
             --
             OR (s.delta_elapsed_time / GREATEST(s.delta_rows_processed, 1)  > p_regression_threshold * s.elapsed_time / GREATEST(s.rows_processed, 1) AND s.rows_processed >= s.executions AND s.delta_rows_processed >= s.delta_execution_count)
             OR (s.delta_cpu_time     / GREATEST(s.delta_rows_processed, 1)  > p_regression_threshold * s.cpu_time     / GREATEST(s.rows_processed, 1) AND s.rows_processed >= s.executions AND s.delta_rows_processed >= s.delta_execution_count)
             OR (s.delta_buffer_gets  / GREATEST(s.delta_rows_processed, 1)  > p_regression_threshold * s.buffer_gets  / GREATEST(s.rows_processed, 1) AND s.rows_processed >= s.executions AND s.delta_rows_processed >= s.delta_execution_count)
           )
       AND c.con_id = s.con_id
       AND c.open_mode = 'READ WRITE'
    ),
    appl_users AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           con_id,
           username
      FROM cdb_users
     WHERE oracle_maintained = 'N'
    )
    SELECT -- soft pk
           s.con_id                         ,
           s.sql_id                         ,
           l_snap_id                        , -- snap_id
           l_snap_time                      , -- snap_time
           -- columns
           s.last_active_time               ,
           s.plan_hash_value                ,
           s.disk_reads                     ,
           s.buffer_gets                    ,
           s.rows_processed                 ,
           s.fetches                        ,
           s.executions                     ,
           s.end_of_fetch_count             ,
           s.loads                          ,
           s.version_count                  ,
           s.invalidations                  ,
           s.cpu_time                       ,
           s.elapsed_time                   ,
           s.application_wait_time          ,
           s.concurrency_wait_time          ,
           s.user_io_wait_time              ,
           s.sharable_mem                   ,
           s.exact_matching_signature       ,
           s.delta_disk_reads               ,
           s.delta_buffer_gets              ,
           s.delta_rows_processed           ,
           s.delta_fetch_count              ,
           s.delta_execution_count          ,
           s.delta_end_of_fetch_count       ,
           s.delta_cpu_time                 ,
           s.delta_elapsed_time             ,
           s.delta_application_wait_time    ,
           s.delta_concurrency_time         ,
           s.delta_user_io_wait_time        ,
           s.delta_loads                    ,
           s.delta_invalidations            ,
           -- extension
           s.pdb_name                       ,
           s.parsing_schema_name            ,
           l_instance_startup_age_secs      , -- instance_startup_age_secs,
           l_last_awr_snapshot_age_secs       -- last_awr_snapshot_age_secs
      FROM regressed_sql s,
           appl_users u
     WHERE s.delta_elapsed_time / 1e6 / l_last_awr_snapshot_age_secs > p_db_aas_threshold -- minimum average active sessions as per elapsed time from last awr to capture sql (0.002 DB AAS) 
       AND l_instance_startup_age_secs > p_instance_startup_age_secs
       AND l_last_awr_snapshot_age_secs > p_last_awr_snapshot_age_secs
       AND u.con_id = s.con_id
       AND u.username = s.parsing_schema_name;
  --
    l_rows_count := SQL%ROWCOUNT;
    INSERT INTO &&1..sqlstats_snapshot 
    (snap_id, snap_time, instance_startup_age_secs, last_awr_snapshot_age_secs, rows_count) 
    VALUES 
    (l_snap_id, l_snap_time, l_instance_startup_age_secs, l_last_awr_snapshot_age_secs, l_rows_count);
  --
  END IF;
  --
  INSERT INTO &&1..active_session_hist (
    -- soft pk
    con_id                         ,
    sql_id                         ,
    snap_id                        ,
    snap_time                      ,
    -- columns
    aas_total                      , 
    aas_on_cpu                     ,
    aas_user_io                    ,
    aas_system_io                  ,
    aas_cluster                    ,
    aas_commit                     ,
    aas_concurrency                ,
    aas_application                ,
    aas_administrative             ,
    aas_configuration              ,
    aas_network                    ,
    aas_queueing                   ,
    aas_scheduler                  ,
    aas_other                      ,
    -- extension
    pdb_name                       ,
    username
  )
  WITH
  ash_by_sql_id AS (
  SELECT /*+ MATERIALIZE NO_MERGE */
         h.con_id,
         h.sql_id,
         ROUND(COUNT(*)/p_capture_ash_secs,3) aas_total, -- average active sessions on the database (on cpu or waiting)
         ROUND(SUM(CASE h.session_state WHEN 'ON CPU'         THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_on_cpu,
         ROUND(SUM(CASE h.wait_class    WHEN 'User I/O'       THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_user_io,
         ROUND(SUM(CASE h.wait_class    WHEN 'System I/O'     THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_system_io,
         ROUND(SUM(CASE h.wait_class    WHEN 'Cluster'        THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_cluster,
         ROUND(SUM(CASE h.wait_class    WHEN 'Commit'         THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_commit,
         ROUND(SUM(CASE h.wait_class    WHEN 'Concurrency'    THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_concurrency,
         ROUND(SUM(CASE h.wait_class    WHEN 'Application'    THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_application,
         ROUND(SUM(CASE h.wait_class    WHEN 'Administrative' THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_administrative,
         ROUND(SUM(CASE h.wait_class    WHEN 'Configuration'  THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_configuration,
         ROUND(SUM(CASE h.wait_class    WHEN 'Network'        THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_network,
         ROUND(SUM(CASE h.wait_class    WHEN 'Queueing'       THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_queueing,
         ROUND(SUM(CASE h.wait_class    WHEN 'Scheduler'      THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_scheduler,
         ROUND(SUM(CASE h.wait_class    WHEN 'Other'          THEN 1 ELSE 0 END)/p_capture_ash_secs,3) aas_other,
         c.name pdb_name,
         h.user_id
    FROM v$active_session_history h,
         v$containers c
   WHERE h.sql_id IS NOT NULL
     AND h.session_type = 'FOREGROUND'
     AND h.user_id <> 0
     AND h.sample_time > CAST(l_snap_time - (p_capture_ash_secs/24/60/60) AS TIMESTAMP) 
     AND h.sample_time <= CAST(l_snap_time AS TIMESTAMP)
     AND c.con_id = h.con_id
     AND c.open_mode = 'READ WRITE'
   GROUP BY
         h.con_id,
         h.sql_id,
         c.name,
         h.user_id
  ),
  appl_users AS (
  SELECT /*+ MATERIALIZE NO_MERGE */
         con_id,
         user_id,
         username
    FROM cdb_users
   WHERE oracle_maintained = 'N'
  )
  SELECT -- soft pk
         h.con_id                         ,
         h.sql_id                         ,
         l_snap_id                        , -- snap_id
         l_snap_time                      , -- snap_time
         -- columns
         h.aas_total                      , -- average active sessions on the database (on cpu or waiting)
         h.aas_on_cpu                     ,
         h.aas_user_io                    ,
         h.aas_system_io                  ,
         h.aas_cluster                    ,
         h.aas_commit                     ,
         h.aas_concurrency                ,
         h.aas_application                ,
         h.aas_administrative             ,
         h.aas_configuration              ,
         h.aas_network                    ,
         h.aas_queueing                   ,
         h.aas_scheduler                  ,
         h.aas_other                      ,
         -- extension
         h.pdb_name                       ,
         u.username
    FROM ash_by_sql_id h,
         appl_users u
   WHERE h.aas_total >= p_db_aas_threshold
     AND u.con_id = h.con_id
     AND u.user_id = h.user_id;
  --     
  COMMIT;
  --
  -- drop partitions with data older than 2 months (i.e. preserve between 2 and 3 months of history)
  FOR i IN (
    SELECT partition_name, high_value, blocks
      FROM dba_tab_partitions
     WHERE table_owner = UPPER('&&1.')
       AND table_name = 'SQLSTATS_SNAPSHOT'
     ORDER BY
           partition_name
  )
  LOOP
    EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
    output('PARTITION:'||RPAD(SUBSTR(i.partition_name, 1, 30), 32)||'HIGH_VALUE:'||TO_CHAR(l_high_value, gk_date_format)||'  BLOCKS:'||i.blocks);
    IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2) THEN
      output('&&1..IOD_SQLSTATS.sqlstats_snapshot: ALTER TABLE &&1..sqlstats_snapshot DROP PARTITION '||i.partition_name, p_alert_log => 'Y');
      EXECUTE IMMEDIATE q'[ALTER TABLE &&1..sqlstats_snapshot SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
      EXECUTE IMMEDIATE 'ALTER TABLE &&1..sqlstats_snapshot DROP PARTITION '||i.partition_name;
    END IF;
  END LOOP;
  -- drop partitions with data older than 2 months (i.e. preserve between 2 and 3 months of history)
  FOR i IN (
    SELECT partition_name, high_value, blocks
      FROM dba_tab_partitions
     WHERE table_owner = UPPER('&&1.')
       AND table_name = 'ACTIVE_SESSION_HIST'
     ORDER BY
           partition_name
  )
  LOOP
    EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
    output('PARTITION:'||RPAD(SUBSTR(i.partition_name, 1, 30), 32)||'HIGH_VALUE:'||TO_CHAR(l_high_value, gk_date_format)||'  BLOCKS:'||i.blocks);
    IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2) THEN
      output('&&1..IOD_SQLSTATS.active_session_hist: ALTER TABLE &&1..active_session_hist DROP PARTITION '||i.partition_name, p_alert_log => 'Y');
      EXECUTE IMMEDIATE q'[ALTER TABLE &&1..active_session_hist SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
      EXECUTE IMMEDIATE 'ALTER TABLE &&1..active_session_hist DROP PARTITION '||i.partition_name;
    END IF;
  END LOOP;
  --
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
  output('end '||TO_CHAR(SYSDATE, gk_date_format));
END snapshot;
/* ------------------------------------------------------------------------------------ */
END iod_sqlstats;
/
