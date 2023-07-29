WITH
FUNCTION num_format (p_number IN NUMBER, p_round IN NUMBER DEFAULT 0) 
RETURN VARCHAR2 IS
BEGIN
  IF p_number IS NULL OR ROUND(p_number, p_round) <= 0 THEN
    RETURN 'null';
  ELSE
    RETURN TO_CHAR(ROUND(p_number, p_round));
  END IF;
END num_format;
/****************************************************************************************/
ash AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       h.sample_id, 
       h.sample_time, 
       h.machine, 
       h.module,
       h.session_id, 
       h.session_serial#, 
       h.blocking_session, 
       h.blocking_session_serial#, 
       h.session_state, 
       h.wait_class, 
       h.event,
       h.sql_id,
       h.top_level_sql_id
  FROM dba_hist_active_sess_history h
 WHERE 1 = 1
   AND TO_NUMBER('&&cs_con_id.') IN (1, h.con_id)
   AND h.sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND h.sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
   AND h.dbid = TO_NUMBER('&&cs_dbid.')
   AND h.instance_number = TO_NUMBER('&&cs_instance_number.')
   AND h.snap_id BETWEEN TO_NUMBER('&&cs_snap_id_from.') AND TO_NUMBER('&&cs_snap_id_to.')
),
/****************************************************************************************/
inactive_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       DISTINCT 
       i.sample_id, 
       CAST(i.sample_time AS DATE) sample_time,
       i.blocking_session session_id,
       i.blocking_session_serial# session_serial#
  FROM ash i
 WHERE i.blocking_session IS NOT NULL
   AND i.blocking_session_serial# IS NOT NULL
   AND NOT EXISTS (
SELECT /*+ MATERIALIZE NO_MERGE */
       NULL
  FROM ash a
 WHERE a.sample_id = i.sample_id
   AND a.session_id = i.blocking_session
   AND a.session_serial# = i.blocking_session_serial#
)),
/****************************************************************************************/
all_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       a.sample_id, CAST(a.sample_time AS DATE) sample_time, a.machine, a.module, a.session_id, a.session_serial#, a.blocking_session, a.blocking_session_serial#, 
       'ACTIVE' status, session_state, wait_class, event, sql_id, top_level_sql_id
  FROM ash a
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       i.sample_id, i.sample_time, NULL machine, NULL module, i.session_id, i.session_serial#, TO_NUMBER(NULL), TO_NUMBER(NULL), 
       'INACTIVE or UNKNOWN' status, NULL session_state, NULL wait_class, NULL event, NULL sql_id, NULL top_level_sql_id
  FROM inactive_sessions i
),
/****************************************************************************************/
sess_history AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, machine, module, session_id, session_serial#, status, session_state, wait_class, event, sql_id, top_level_sql_id,
       LEVEL lvl,
       CONNECT_BY_ROOT machine blocker_machine,
       CONNECT_BY_ROOT module blocker_module,
       CONNECT_BY_ROOT session_id blocker_session,
       CONNECT_BY_ROOT session_serial# blocker_session_serial#,
       CONNECT_BY_ISLEAF AS leaf
  FROM all_sessions
 START WITH blocking_session IS NULL AND blocking_session_serial# IS NULL
CONNECT BY sample_id = PRIOR sample_id AND blocking_session = PRIOR session_id AND blocking_session_serial# = PRIOR session_serial#
),
/****************************************************************************************/
blockers AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, status, session_state, wait_class, event, sql_id, top_level_sql_id, session_id, session_serial#
  FROM sess_history
 WHERE lvl = 1
),
/****************************************************************************************/
blockees AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, status, wait_class, event, blocker_session, blocker_session_serial#, COUNT(*) cnt
  FROM sess_history
 WHERE lvl > 1
 GROUP BY
       sample_id, sample_time, status, wait_class, event, blocker_session, blocker_session_serial#
),
/****************************************************************************************/
machines AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       session_id, session_serial#, MAX(machine) machine
  FROM sess_history
 WHERE machine IS NOT NULL
 GROUP BY
       session_id, session_serial#
 UNION
SELECT /*+ MATERIALIZE NO_MERGE */
       sid session_id, serial# session_serial#, machine
  FROM v$session
),
/****************************************************************************************/
modules AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       session_id, session_serial#, MAX(module) module
  FROM sess_history
 WHERE module IS NOT NULL
 GROUP BY
       session_id, session_serial#
 UNION
SELECT /*+ MATERIALIZE NO_MERGE */
       sid session_id, serial# session_serial#, module
  FROM v$session
),
/****************************************************************************************/
blockers_and_blockees AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       b.sample_id, 
       b.sample_time time, 
       a.wait_class||' - '||a.event AS wait_class_event,
       b.status blocker_status,
       b.session_state blocker_session_state, 
       b.wait_class blocker_wait_class, 
       b.event blocker_event,
       COALESCE(b.sql_id, b.top_level_sql_id) AS blocker_sql_id,
       NVL(m.machine, 'unknown') machine,
       NVL(m2.module, 'unknown') module,
       b.session_id blocker_session_id, 
       b.session_serial# blocker_session_serial#,
       NVL(a.cnt, 0) sessions_blocked,
       CASE b.session_state WHEN 'ON CPU' THEN NVL(a.cnt, 0) ELSE 0 END AS active_on_cpu,
       CASE b.session_state WHEN 'WAITING' THEN NVL(a.cnt, 0) ELSE 0 END AS active_waiting,
       CASE b.status WHEN 'INACTIVE or UNKNOWN' THEN (CASE NVL(m.machine, 'unknown') WHEN '&&cs_host_name.' THEN 0 ELSE NVL(a.cnt, 0) END) ELSE 0 END AS inactive,
       CASE b.status WHEN 'INACTIVE or UNKNOWN' THEN (CASE NVL(m.machine, 'unknown') WHEN '&&cs_host_name.' THEN NVL(a.cnt, 0) ELSE 0 END) ELSE 0 END AS unknown
  FROM blockers b,
       blockees a,
       machines m,
       modules m2
 WHERE a.sample_id(+) = b.sample_id
   AND a.sample_time(+) = b.sample_time
   AND a.blocker_session(+) = b.session_id
   AND a.blocker_session_serial#(+) = b.session_serial#
   AND m.session_id(+) = b.session_id
   AND m.session_serial#(+) = b.session_serial#
   AND m2.session_id(+) = b.session_id
   AND m2.session_serial#(+) = b.session_serial#
)
/****************************************************************************************/
