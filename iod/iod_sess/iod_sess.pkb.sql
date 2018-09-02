CREATE OR REPLACE PACKAGE BODY &&1..iod_sess AS
/* $Header: iod_sess.pkb.sql &&library_version. carlos.sierra $ */
/* ------------------------------------------------------------------------------------ */  
FUNCTION get_package_version
RETURN VARCHAR2
IS
BEGIN
  RETURN gk_package_version;
END get_package_version;
/* ------------------------------------------------------------------------------------ */  
PROCEDURE audit_and_disconnect (
  p_table_name        IN VARCHAR2 DEFAULT gk_table_name, -- kill session holding TM and TX locks on this table
  p_lock_secs_thres   IN NUMBER   DEFAULT gk_lock_secs_thres, -- if the lock has been held for this many sconds
  p_inac_secs_thres   IN NUMBER   DEFAULT gk_inac_secs_thres, -- if the session has been inactive for this many sconds
  p_snip_secs_thres   IN NUMBER   DEFAULT gk_snip_secs_thres, -- snip candidate if inactive for this many sconds
  p_snip_idle_profile IN VARCHAR2 DEFAULT gk_snip_idle_profile, -- application user profile with idle_time set
  p_snip_candidates   IN VARCHAR2 DEFAULT gk_snip_candidates, -- optionally include or exclude snip candiates
  p_sniped_sessions   IN VARCHAR2 DEFAULT gk_sniped_sessions, -- optionally include or exclude user snipped sessions regardless of lock type or object
  p_tm_locks          IN VARCHAR2 DEFAULT gk_tm_locks, -- optionally include or exclude TM locks
  p_tx_locks          IN VARCHAR2 DEFAULT gk_tx_locks, -- optionally include or exclude TX locks
  p_kill_locked       IN VARCHAR2 DEFAULT gk_kill_locked, -- kill sessions holding TX/TM lock on p_table_name
  p_kill_idle         IN VARCHAR2 DEFAULT gk_kill_idle, -- kill sessions waiting long or sniped
  p_expire_date       IN DATE     DEFAULT gk_expire_date -- execute this api only if SYSDATE < p_expire_date
)
IS
  l_table_name VARCHAR2(30) := NVL(UPPER(SUBSTR(TRIM(p_table_name), 1, 30)), gk_table_name);
  l_lock_secs_thres NUMBER := NVL(p_lock_secs_thres, gk_lock_secs_thres);
  l_inac_secs_thres NUMBER := NVL(p_inac_secs_thres, gk_inac_secs_thres);
  l_snip_secs_thres NUMBER := NVL(p_snip_secs_thres, gk_snip_secs_thres);
  l_snip_idle_profile VARCHAR2(30) := NVL(UPPER(SUBSTR(TRIM(p_snip_idle_profile), 1, 30)), gk_snip_idle_profile);
  l_snip_candidates VARCHAR2(1) := NVL(UPPER(SUBSTR(TRIM(p_snip_candidates), 1, 1)), gk_snip_candidates);
  l_sniped_sessions VARCHAR2(1) := NVL(UPPER(SUBSTR(TRIM(p_sniped_sessions), 1, 1)), gk_sniped_sessions);
  l_tm_locks VARCHAR2(1) := NVL(UPPER(SUBSTR(TRIM(p_tm_locks), 1, 1)), gk_tm_locks);
  l_tx_locks VARCHAR2(1) := NVL(UPPER(SUBSTR(TRIM(p_tx_locks), 1, 1)), gk_tx_locks);
  l_kill_locked VARCHAR2(1) := NVL(UPPER(SUBSTR(TRIM(p_kill_locked), 1, 1)), gk_kill_locked);
  l_kill_idle VARCHAR2(1) := NVL(UPPER(SUBSTR(TRIM(p_kill_idle), 1, 1)), gk_kill_idle);
  l_expire_date DATE := NVL(p_expire_date, gk_expire_date);
  l_message VARCHAR2(4000);
  l_snap_time DATE := SYSDATE;
--
  l_open_mode VARCHAR2(20);
  l_db_name VARCHAR2(9);
  l_sql_statement VARCHAR2(32767);
  l_kill_session_requested VARCHAR2(1);
  l_killed VARCHAR2(1);
  l_high_value DATE;
  l_insert_count NUMBER := 0;
--  
  CURSOR candidate_sessions (
    c_table_name        VARCHAR2, 
    c_lock_secs_thres   NUMBER,
    c_inac_secs_thres   NUMBER,
    c_snip_secs_thres   NUMBER,
    c_snip_idle_profile VARCHAR2,
    c_snip_candidates   VARCHAR2,
    c_sniped_sessions   VARCHAR2, 
    c_tm_locks          VARCHAR2, 
    c_tx_locks          VARCHAR2
  )
  IS
    WITH /* &&1.iod_sess.audit_and_disconnect */
    s_v$session AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           s.sid,
           s.serial#,
           s.paddr,
           s.type,
           s.user#,
           s.status,
           s.logon_time,
           s.last_call_et,
           s.service_name,
           s.machine,
           s.osuser,
           s.program,
           s.module,
           s.client_info,
           s.sql_id,
           s.sql_exec_start,
           s.prev_sql_id,
           s.prev_exec_start,
           s.username,
           s.con_id,
           s.row_wait_obj#
      FROM v$session s
     WHERE s.type = 'USER'
       AND s.user# > 0 -- skip SYS
       --AND s.last_call_et >= LEAST(c_lock_secs_thres, c_inac_secs_thres, c_snip_secs_thres) -- removed so we can see them all, including s.last_call_et = 0
    ),
    s_v$process AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           p.addr,
           p.spid,
           p.con_id
      FROM v$process p
    ),
    s_cdb_users AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           u.username,
           u.oracle_maintained,
           u.profile,
           u.con_id
      FROM cdb_users u
     WHERE u.oracle_maintained = 'N'
       AND u.profile = c_snip_idle_profile
    ),
    s_v$containers AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           c.name,
           c.con_id,
           c.open_mode
      FROM v$containers c
     WHERE c.open_mode = 'READ WRITE'
    ),
    s_v$lock AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           l.type,
           l.ctime,
           l.block,
           l.sid,
           l.lmode,
           l.request,
           l.con_id,
           l.id1,
           l.id2
      FROM v$lock l
     WHERE l.type IN ('TM', 'TX')
       --AND l.ctime >= c_lock_secs_thres -- removed so we can see them all, including l.ctime = 0
    ),
    s_cdb_objects AS (
    SELECT /*+ MATERIALIZE NO_MERGE */
           o.object_name,
           o.object_type,
           o.temporary,
           o.oracle_maintained,
           o.object_id,
           o.con_id
      FROM cdb_objects o
     WHERE o.owner <> 'SYS'
       AND o.object_name = c_table_name
       AND o.object_type = 'TABLE'
       AND o.temporary = 'N'
       AND o.oracle_maintained = 'N'
    ),
    main_query AS (
    -- 
    -- Inactive sessions to be killed, similar SNIPPED sessions due to DBA_PROFILE IDLE_TIME (regardless of table)
    --
    SELECT /*+ ORDERED */
           CASE WHEN s.last_call_et >= c_inac_secs_thres THEN 'Y' ELSE 'N' END death_row,
           s.sid,
           s.serial#,
           p.spid,
           s.status,
           s.logon_time,
           --SYSDATE snap_time,
           s.last_call_et,
           TO_NUMBER(NULL) ctime,
           NULL type,
           TO_NUMBER(NULL) lmode,
           s.service_name,
           s.machine,
           s.osuser,
           s.program,
           s.module,
           s.client_info,
           s.sql_id,
           s.sql_exec_start,
           s.prev_sql_id,
           s.prev_exec_start,
           s.username,
           TO_NUMBER(NULL) object_id,
           s.con_id,
           c.name pdb_name,
           --'INACTIVE > '|| c_inac_secs_thres||'s' reason,
           'INACTIVE '|| s.last_call_et||'s' reason,
           3 pty
      FROM s_v$session    s,
           s_v$process    p,
           s_cdb_users    u,
           s_v$containers c
     WHERE c_snip_candidates IN ('Y', 'T') -- (Y)es or (T)rue
       AND s.status = 'INACTIVE'
       AND s.type = 'USER'
       AND s.user# > 0 -- skip SYS
       AND s.last_call_et >= c_inac_secs_thres -- seconds since became inactive
       AND p.con_id = s.con_id
       AND p.addr = s.paddr
       AND u.con_id = s.con_id
       AND u.username = s.username
       AND u.oracle_maintained = 'N'
       AND u.profile = c_snip_idle_profile
       AND c.con_id = s.con_id
       AND c.open_mode = 'READ WRITE'
       AND p.con_id = u.con_id -- adding transitive join predicate
       AND c.con_id = u.con_id -- adding transitive join predicate
       AND c.con_id = p.con_id -- adding transitive join predicate
     UNION ALL
    -- 
    -- Sniped sessions due to DBA_PROFILE IDLE_TIME (regardless of table)
    --
    SELECT /*+ ORDERED */
           CASE WHEN s.last_call_et >= c_snip_secs_thres THEN 'Y' ELSE 'N' END death_row,
           s.sid,
           s.serial#,
           p.spid,
           s.status,
           s.logon_time,
           --SYSDATE snap_time,
           s.last_call_et,
           TO_NUMBER(NULL) ctime,
           NULL type,
           TO_NUMBER(NULL) lmode,
           s.service_name,
           s.machine,
           s.osuser,
           s.program,
           s.module,
           s.client_info,
           s.sql_id,
           s.sql_exec_start,
           s.prev_sql_id,
           s.prev_exec_start,
           s.username,
           TO_NUMBER(NULL) object_id,
           s.con_id,
           c.name pdb_name,
           --'SNIPED' reason,
           'SNIPED '|| s.last_call_et||'s' reason,
           4 pty
      FROM s_v$session    s,
           s_v$process    p,
           s_v$containers c
     WHERE c_sniped_sessions IN ('Y', 'T') -- (Y)es or (T)rue
       AND s.status = 'SNIPED'
       AND s.type = 'USER'
       AND s.user# > 0 -- skip SYS
       AND s.last_call_et >= c_snip_secs_thres -- seconds since became inactive
       AND p.con_id = s.con_id
       AND p.addr = s.paddr
       AND c.con_id = s.con_id
       AND c.open_mode = 'READ WRITE'
       AND c.con_id = p.con_id -- adding transitive join predicate
     UNION ALL
    --
    -- TM DML enqueue locks on specific table (or table lock)
    --
    SELECT /*+ ORDERED */
           CASE WHEN s.status = 'INACTIVE' AND l.ctime >= c_lock_secs_thres AND s.last_call_et >= c_lock_secs_thres THEN 'Y' ELSE 'N' END death_row,
           s.sid,
           s.serial#,
           p.spid,
           s.status,
           s.logon_time,
           --SYSDATE snap_time,
           s.last_call_et,
           l.ctime,
           l.type,
           l.lmode,
           s.service_name,
           s.machine,
           s.osuser,
           s.program,
           s.module,
           s.client_info,
           s.sql_id,
           s.sql_exec_start,
           s.prev_sql_id,
           s.prev_exec_start,
           s.username,
           o.object_id,
           s.con_id,
           c.name pdb_name,
           --'TM LOCK AND INACTIVE > '|| c_lock_secs_thres||'s' reason,
           'TM LOCK AND INACTIVE '|| s.last_call_et||'s' reason,
           2 pty
      FROM s_v$lock       l,
           s_v$session    s,
           s_v$process    p,
           s_cdb_objects  o,
           s_v$containers c
     WHERE c_tm_locks IN ('Y', 'T') -- (Y)es or (T)rue
       AND l.type = 'TM' -- DML enqueue
       --AND l.ctime >= c_lock_secs_thres -- lock duration in seconds
       AND l.block = 1 -- blocking oher session(s) on this instance
       AND s.con_id = l.con_id -- <> 0
       AND s.sid = l.sid
       --AND s.status = 'INACTIVE' -- collect also ACTIVE or KILLED
       AND s.type = 'USER'
       AND s.user# > 0 -- skip SYS
       --AND s.last_call_et >= c_lock_secs_thres -- seconds since became inactive
       AND p.con_id = s.con_id
       AND p.addr = s.paddr
       AND o.con_id = l.con_id
       AND o.object_id = l.id1
       AND o.object_name = c_table_name
       AND o.object_type = 'TABLE' -- redundant
       AND o.temporary = 'N' -- redundant
       AND o.oracle_maintained = 'N' -- redundant
       AND c.con_id = s.con_id
       AND c.open_mode = 'READ WRITE'
       AND p.con_id = c.con_id -- adding transitive join predicate
       AND p.con_id = l.con_id -- adding transitive join predicate
       AND p.con_id = o.con_id -- adding transitive join predicate
       AND c.con_id = l.con_id -- adding transitive join predicate
       AND c.con_id = o.con_id -- adding transitive join predicate
       AND o.con_id = s.con_id -- adding transitive join predicate
     UNION ALL
    --
    -- TX Transaction enqueue locks on specific table (row lock)
    --
    SELECT /*+ ORDERED */
           DISTINCT -- needed since one session could be blocking several others (thus expecting duplicates)
           CASE WHEN bs.status = 'INACTIVE' AND b.ctime >= c_lock_secs_thres AND bs.last_call_et >= c_lock_secs_thres AND w.ctime >= c_lock_secs_thres AND ws.last_call_et >= c_lock_secs_thres THEN 'Y' ELSE 'N' END death_row,
           bs.sid,
           bs.serial#,
           bp.spid,
           bs.status,
           bs.logon_time,
           --SYSDATE snap_time,
           bs.last_call_et,
           b.ctime,
           b.type,
           b.lmode,
           bs.service_name,
           bs.machine,
           bs.osuser,
           bs.program,
           bs.module,
           bs.client_info,
           bs.sql_id,
           bs.sql_exec_start,
           bs.prev_sql_id,
           bs.prev_exec_start,
           bs.username,
           wo.object_id,
           bs.con_id,
           bc.name pdb_name,
           --'TX LOCK AND INACTIVE > '|| c_lock_secs_thres||'s' reason,
           'TX LOCK AND INACTIVE '|| bs.last_call_et||'s' reason,
           1 pty
      FROM s_v$lock       b,  -- blockers
           s_v$session    bs, -- sessions blocking others
           s_v$process    bp, -- processes for sessions blocking others
           s_v$containers bc,
           s_v$lock       w,  -- waiters
           s_v$session    ws, -- sessions waiting
           s_cdb_objects  wo  -- objects for which sessions are waiting on
     WHERE c_tx_locks IN ('Y', 'T') -- (Y)es or (T)rue
       AND b.type = 'TX' -- transaction enqueue
       --AND b.ctime >= c_lock_secs_thres -- lock duration in seconds
       AND b.block = 1 -- blocking oher session(s) on this instance
       --AND bs.con_id = b.con_id -- bs.con_id <> 0 and b.con_id = 0
       AND bs.sid = b.sid
       --AND bs.status = 'INACTIVE' -- blocker could potentially being doing some work if it were ACTIVE. collect also ACTIVE or KILLED
       AND bs.type = 'USER'
       AND bs.user# > 0 -- skip SYS
       --AND bs.last_call_et >= c_lock_secs_thres -- seconds since inactive (blocking)
       AND bp.con_id = bs.con_id -- bp.con_id <> 0 and bs.con_id <> 0
       AND bp.addr = bs.paddr
       AND bc.con_id = bs.con_id
       AND bc.open_mode = 'READ WRITE'
       AND w.type = 'TX' -- transaction enqueue
       --AND w.ctime >= c_lock_secs_thres -- wait duration in seconds
       --AND w.block = 0 -- the waiter could potentially be blocking others as well
       AND w.request > 0 -- requesting a lock on some resource
       AND w.con_id = b.con_id -- w.con_id = 0 and b.con_id = 0
       AND w.id1 = b.id1 -- rollback segment
       AND w.id2 = b.id2 -- transaction table entries
       --AND ws.con_id = w.con_id -- ws.con_id <> 0 and w.con_id = 0
       AND ws.sid = w.sid
       AND ws.status = 'ACTIVE'
       AND ws.type = 'USER'
       AND ws.user# > 0 -- skip SYS
       --AND ws.last_call_et >= c_lock_secs_thres -- seconds since active (waiting)
       AND wo.con_id = ws.con_id -- wo.con_id <> 0 and ws.con_id <> 0
       AND wo.object_id = ws.row_wait_obj#
       AND wo.object_name = c_table_name
       AND wo.object_type = 'TABLE' -- redundant
       AND wo.temporary = 'N' -- redundant
       AND wo.oracle_maintained = 'N' -- redundant
       AND bp.con_id = bc.con_id -- adding transitive join predicate (con_id <> 0)
       AND wo.con_id = bp.con_id -- adding transitive join predicate (con_id <> 0)
       AND wo.con_id = bs.con_id -- adding transitive join predicate (con_id <> 0)
       AND wo.con_id = bc.con_id -- adding transitive join predicate (con_id <> 0)
       AND ws.con_id = bp.con_id -- adding transitive join predicate (con_id <> 0)
       AND ws.con_id = bs.con_id -- adding transitive join predicate (con_id <> 0)
       AND ws.con_id = bc.con_id -- adding transitive join predicate (con_id <> 0)
    )
    SELECT m.pty,
           m.death_row,
           m.sid,
           m.serial#,
           m.spid,
           m.status,
           m.logon_time,
           --SYSDATE snap_time,
           m.last_call_et,
           m.ctime,
           m.type,
           m.lmode,
           m.service_name,
           m.machine,
           m.osuser,
           m.program,
           m.module,
           m.client_info,
           m.sql_id,
           m.sql_exec_start,
           m.prev_sql_id,
           m.prev_exec_start,
           m.username,
           m.object_id,
           m.con_id,
           m.pdb_name,
           m.reason
      FROM main_query m
     ORDER BY
           m.pty,
           m.sid,
           m.serial#;
--
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
--
BEGIN
  -- execute only if SYSDATE < p_expire_date - 1m
  IF SYSDATE >= l_expire_date - (1/1440) THEN
    output('*** api call expired (SYSDATE:'||TO_CHAR(SYSDATE, gk_date_format)||' < expire_date:'||TO_CHAR(l_expire_date, gk_date_format)||') ***');
    RETURN;
  END IF;
  --
  SELECT name, open_mode INTO l_db_name, l_open_mode FROM v$database;
  -- to be executed on DG primary only
  IF l_open_mode <> 'READ WRITE' THEN
    output('*** to be executed only on DG primary ***');
    RETURN;
  END IF;
  --
  output('begin '||TO_CHAR(SYSDATE, gk_date_format));
  DBMS_APPLICATION_INFO.SET_MODULE(UPPER('&&1.')||'.IOD_SESS','AUDIT_AND_DISCONNECT');
  -- main cursor
  FOR i IN candidate_sessions (l_table_name, l_lock_secs_thres, l_inac_secs_thres, l_snip_secs_thres, l_snip_idle_profile, l_snip_candidates, l_sniped_sessions, l_tm_locks, l_tx_locks)
  LOOP
    IF i.status IN ('INACTIVE', 'SNIPED') AND ((i.type IN ('TM', 'TX') AND l_kill_locked = 'Y') OR (i.type IS NULL AND l_kill_idle = 'Y')) THEN
      l_kill_session_requested := 'Y';
    ELSE
      l_kill_session_requested := 'N';
    END IF;
    --
    IF l_kill_session_requested = 'Y' AND i.death_row = 'Y' THEN
      l_killed := 'Y';
    ELSE
      l_killed := 'N';
    END IF;
    --
    -- insert into audit table once
    INSERT /* &&1.iod_sess.audit_and_disconnect */
    INTO &&1..inactive_sessions_audit_trail (
      pty         ,
      death_row   ,
      sid         ,
      serial#     ,
      spid        ,
      status      ,
      logon_time  ,
      snap_time   ,
      killed      ,
      last_call_et,
      ctime       ,
      type        ,
      lmode       ,
      service_name,
      machine     ,
      osuser      ,
      program     ,
      module      ,
      client_info ,
      sql_id,
      sql_exec_start,
      prev_sql_id,
      prev_exec_start,
      username    ,
      object_id   ,
      con_id      ,
      pdb_name    ,
      reason
    ) 
    SELECT
      i.pty         ,
      i.death_row   ,
      i.sid         ,
      i.serial#     ,
      i.spid        ,
      i.status      ,
      i.logon_time  ,
      l_snap_time   , -- all rows get the same date so we can easily aggregate for reporting
      l_killed      ,
      i.last_call_et,
      i.ctime       ,
      i.type        ,
      i.lmode       ,
      i.service_name,
      i.machine     ,
      i.osuser      ,
      i.program     ,
      i.module      ,
      i.client_info ,
      i.sql_id      ,
      i.sql_exec_start,
      i.prev_sql_id ,
      i.prev_exec_start,
      i.username    ,
      i.object_id   ,
      i.con_id      ,
      i.pdb_name    ,
      i.reason
    FROM DUAL;
    l_insert_count := l_insert_count + 1;
    --WHERE NOT EXISTS (SELECT NULL FROM &&1..disconnected_sessions e WHERE e.sid = i.sid AND e.serial# = i.serial# AND e.logon_time = i.logon_time);    
    COMMIT; -- expected super low volume (then commit within loop)
    --
    l_message := 'pty:'||i.pty||' dead?:'||i.death_row||' kill?:'||l_kill_session_requested||' killed:'||l_killed||' stat:'||i.status||' et:'||i.last_call_et||'s sess:('||i.sid||','||i.serial#||')';
    IF l_killed = 'Y' THEN
      output('&&1..iod_sess.audit_and_disconnect: '||l_message, p_alert_log => 'Y');
      l_sql_statement := 'ALTER SYSTEM DISCONNECT SESSION '''||i.sid||','||i.serial#||''' IMMEDIATE';
      output('&&1..iod_sess.audit_and_disconnect: '||l_sql_statement||'; at '||TO_CHAR(SYSDATE, gk_date_format), p_alert_log => 'Y');
      DECLARE
        session_id_does_not_exist EXCEPTION;
        PRAGMA EXCEPTION_INIT(session_id_does_not_exist, -00030); -- ORA-00030: User session ID does not exist.
      BEGIN
        -- if you get "ORA-00031: session marked for kill" that means the kill took longer than 60s and timeout
        EXECUTE IMMEDIATE l_sql_statement;
      EXCEPTION
        WHEN session_id_does_not_exist THEN
          output('&&1..iod_sess.audit_and_disconnect: '||sqlerrm, p_alert_log => 'Y');
      END;
    ELSE
      output(l_message, p_alert_log => 'N');
    END IF;
  END LOOP;
  COMMIT; -- expected some volume (then commit outside loop)
  -- drop partitions with data older than 2 months (i.e. preserve between 2 and 3 months of history)
  IF l_insert_count > 1 THEN
    FOR i IN (
      SELECT partition_name, high_value, blocks
        FROM dba_tab_partitions
       WHERE table_owner = UPPER('&&1.')
         AND table_name = 'INACTIVE_SESSIONS_AUDIT_TRAIL'
       ORDER BY
             partition_name
    )
    LOOP
      EXECUTE IMMEDIATE 'SELECT '||i.high_value||' FROM DUAL' INTO l_high_value;
      output('PARTITION:'||RPAD(SUBSTR(i.partition_name, 1, 30), 32)||'HIGH_VALUE:'||TO_CHAR(l_high_value, gk_date_format)||'  BLOCKS:'||i.blocks);
      IF l_high_value <= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2) THEN
        output('&&1..iod_sess.audit_and_disconnect: ALTER TABLE &&1..inactive_sessions_audit_trail DROP PARTITION '||i.partition_name, p_alert_log => 'Y');
        EXECUTE IMMEDIATE q'[ALTER TABLE &&1..inactive_sessions_audit_trail SET INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))]';
        EXECUTE IMMEDIATE 'ALTER TABLE &&1..inactive_sessions_audit_trail DROP PARTITION '||i.partition_name;
      END IF;
    END LOOP;
  END IF;
  DBMS_APPLICATION_INFO.SET_MODULE(NULL,NULL);
  output('end '||TO_CHAR(SYSDATE, gk_date_format));
END audit_and_disconnect;
/* ------------------------------------------------------------------------------------ */
END iod_sess;
/
