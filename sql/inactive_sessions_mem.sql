SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET LIN 1000;
SET TIMI ON TIM ON;
SET FEED ON;

VAR c_table_name VARCHAR2(30);
VAR c_seconds_threshold NUMBER;
VAR c_snip_secs_thres NUMBER;
VAR c_snip_idle_profile VARCHAR2(30);
VAR c_snip_candidates VARCHAR2(1);
VAR c_sniped_sessions VARCHAR2(1);
VAR c_tm_locks VARCHAR2(1);
VAR c_tx_locks VARCHAR2(1);

EXEC :c_table_name := 'KIEVTRANSACTIONS';
EXEC :c_seconds_threshold := 30;
EXEC :c_snip_secs_thres := 60;
EXEC :c_snip_idle_profile := 'APP_PROFILE';
EXEC :c_snip_candidates := 'Y';
EXEC :c_sniped_sessions := 'Y';
EXEC :c_tm_locks := 'Y';
EXEC :c_tx_locks := 'Y';

ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
COL sid FOR 99999;
COL serial# FOR 9999999;
COL spid FOR 99999;
COL logon_time FOR A19;
COL ctime FOR 99999;
COL type FOR A4;
COL lmode FOR 99999;
COL con_id FOR 999999;
COL reason FOR A30;
COL pty 999;
COL death_row FOR A2 HEA 'DR';

COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;
COL x_host_name NEW_V x_host_name;
SELECT host_name x_host_name FROM v$instance;
COL x_db_name NEW_V x_db_name;
SELECT name x_db_name FROM v$database;
COL x_container NEW_V x_container;
SELECT 'NONE' x_container FROM DUAL;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') x_container FROM DUAL;

SPO inactive_sessions_mem_&&x_db_name._&&x_host_name._&&current_time..txt;
PRO HOST: &&x_host_name.
PRO DATABASE: &&x_db_name.
PRO CONTAINER: &&x_container.
PRO

    WITH /* iod_sess.audit_and_disconnect */
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
           s.prev_sql_id,
           s.username,
           s.con_id,
           s.row_wait_obj#
      FROM v$session s
     WHERE s.type = 'USER'
       AND s.user# > 0 -- skip SYS
       --AND s.last_call_et >= LEAST( :c_snip_secs_thres, :c_seconds_threshold) -- removed so we can see them all, including s.last_call_et = 0
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
       AND u.profile = :c_snip_idle_profile
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
       --AND l.ctime >= :c_seconds_threshold -- removed so we can see them all, including l.ctime = 0
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
       AND o.object_name = :c_table_name
       AND o.object_type = 'TABLE'
       AND o.temporary = 'N'
       AND o.oracle_maintained = 'N'
    ),
    main_query AS (
    -- 
    -- Sessions to be sniped as per DBA_PROFILE IDLE_TIME (regardless of table)
    --
    SELECT /*+ ORDERED */
           CASE WHEN s.last_call_et >= :c_snip_secs_thres THEN 'Y' ELSE 'N' END death_row,
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
           s.prev_sql_id,
           s.username,
           TO_NUMBER(NULL) object_id,
           s.con_id,
           c.name pdb_name,
           'INACTIVE > '|| :c_snip_secs_thres||'s' reason,
           3 pty
      FROM s_v$session    s,
           s_v$process    p,
           s_cdb_users    u,
           s_v$containers c
     WHERE :c_snip_candidates IN ('Y', 'T') -- (Y)es or (T)rue
       AND s.status = 'INACTIVE'
       AND s.type = 'USER'
       AND s.user# > 0 -- skip SYS
       AND s.last_call_et >= :c_snip_secs_thres -- seconds since became inactive
       AND p.con_id = s.con_id
       AND p.addr = s.paddr
       AND u.con_id = s.con_id
       AND u.username = s.username
       AND u.oracle_maintained = 'N'
       AND u.profile = :c_snip_idle_profile
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
           CASE WHEN s.last_call_et >= :c_seconds_threshold THEN 'Y' ELSE 'N' END death_row,
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
           s.prev_sql_id,
           s.username,
           TO_NUMBER(NULL) object_id,
           s.con_id,
           c.name pdb_name,
           'SNIPED' reason,
           4 pty
      FROM s_v$session    s,
           s_v$process    p,
           s_v$containers c
     WHERE :c_sniped_sessions IN ('Y', 'T') -- (Y)es or (T)rue
       AND s.status = 'SNIPED'
       AND s.type = 'USER'
       AND s.user# > 0 -- skip SYS
       AND s.last_call_et >= :c_seconds_threshold -- seconds since became inactive
       AND p.con_id = s.con_id
       AND p.addr = s.paddr
       AND c.con_id = s.con_id
       AND c.open_mode = 'READ WRITE'
       AND c.con_id = p.con_id -- adding transitive join predicate
     UNION ALL
    --
    -- TM DML enqueue locks on specific table
    --
    SELECT /*+ ORDERED */
           CASE WHEN l.ctime >= :c_seconds_threshold AND s.last_call_et >= :c_seconds_threshold THEN 'Y' ELSE 'N' END death_row,
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
           s.prev_sql_id,
           s.username,
           o.object_id,
           s.con_id,
           c.name pdb_name,
           'TM LOCK AND INACTIVE > '|| :c_seconds_threshold||'s' reason,
           2 pty
      FROM s_v$lock       l,
           s_v$session    s,
           s_v$process    p,
           s_cdb_objects  o,
           s_v$containers c
     WHERE :c_tm_locks IN ('Y', 'T') -- (Y)es or (T)rue
       AND l.type = 'TM' -- DML enqueue
       --AND l.ctime >= :c_seconds_threshold -- lock duration in seconds
       AND l.block = 1 -- blocking oher session(s) on this instance
       AND s.con_id = l.con_id -- <> 0
       AND s.sid = l.sid
       AND s.status = 'INACTIVE'
       AND s.type = 'USER'
       AND s.user# > 0 -- skip SYS
       --AND s.last_call_et >= :c_seconds_threshold -- seconds since became inactive
       AND p.con_id = s.con_id
       AND p.addr = s.paddr
       AND o.con_id = l.con_id
       AND o.object_id = l.id1
       AND o.object_name = :c_table_name
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
    -- TX Transaction enqueue locks on specific table
    --
    SELECT /*+ ORDERED */
           DISTINCT -- needed since one session could be blocking several others (thus expecting duplicates)
           CASE WHEN b.ctime >= :c_seconds_threshold AND bs.last_call_et >= :c_seconds_threshold AND w.ctime >= :c_seconds_threshold AND ws.last_call_et >= :c_seconds_threshold THEN 'Y' ELSE 'N' END death_row,
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
           bs.prev_sql_id,
           bs.username,
           wo.object_id,
           bs.con_id,
           bc.name pdb_name,
           'TX LOCK AND INACTIVE > '|| :c_seconds_threshold||'s' reason,
           1 pty
      FROM s_v$lock       b,  -- blockers
           s_v$session    bs, -- sessions blocking others
           s_v$process    bp, -- processes for sessions blocking others
           s_v$containers bc,
           s_v$lock       w,  -- waiters
           s_v$session    ws, -- sessions waiting
           s_cdb_objects  wo  -- objects for which sessions are waiting on
     WHERE :c_tx_locks IN ('Y', 'T') -- (Y)es or (T)rue
       AND b.type = 'TX' -- transaction enqueue
       --AND b.ctime >= :c_seconds_threshold -- lock duration in seconds
       AND b.block = 1 -- blocking oher session(s) on this instance
       --AND bs.con_id = b.con_id -- bs.con_id <> 0 and b.con_id = 0
       AND bs.sid = b.sid
       AND bs.status = 'INACTIVE' -- blocker could potentially being doing some work if it were ACTIVE
       AND bs.type = 'USER'
       AND bs.user# > 0 -- skip SYS
       --AND bs.last_call_et >= :c_seconds_threshold -- seconds since inactive (blocking)
       AND bp.con_id = bs.con_id -- bp.con_id <> 0 and bs.con_id <> 0
       AND bp.addr = bs.paddr
       AND bc.con_id = bs.con_id
       AND bc.open_mode = 'READ WRITE'
       AND w.type = 'TX' -- transaction enqueue
       --AND w.ctime >= :c_seconds_threshold -- wait duration in seconds
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
       --AND ws.last_call_et >= :c_seconds_threshold -- seconds since active (waiting)
       AND wo.con_id = ws.con_id -- wo.con_id <> 0 and ws.con_id <> 0
       AND wo.object_id = ws.row_wait_obj#
       AND wo.object_name = :c_table_name
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
           m.prev_sql_id,
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

SPO OFF;