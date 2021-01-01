----------------------------------------------------------------------------------------
--
-- File name:   cs_blocked_sessions_ash_mem_report.sql
--
-- Purpose:     Top Session Blockers as per ASH from Memory (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2020/12/06
--
-- Usage:       Execute connected to CDB or PDB
--
--              Enter range of dates and filters when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_blocked_sessions_ash_mem_report.sql
--
-- Notes:       Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@cs_internal/cs_primary.sql
@@cs_internal/cs_set.sql
@@cs_internal/cs_def.sql
@@cs_internal/cs_file_prefix.sql
--
DEF cs_script_name = 'cs_blocked_sessions_ash_mem_report';
DEF cs_hours_range_default = '3';
DEF cs_top_n = '20';
--
@@cs_internal/cs_sample_time_from_and_to.sql
@@cs_internal/cs_snap_id_from_and_to.sql
--
--ALTER SESSION SET container = CDB$ROOT;
--
SELECT '&&cs_file_prefix._&&cs_script_name.' cs_file_name FROM DUAL;
--
@@cs_internal/cs_spool_head.sql
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
@@cs_internal/cs_spool_id.sql
--
@@cs_internal/cs_spool_id_sample_time.sql
--
COL time FOR A19 HEA 'SAMPLE TIME';
COL blocked FOR 999,990 HEA 'BLOCKED|SESSIONS|COUNT';
COL percent FOR 999,990.000 HEA 'CONTRIBUTION|PERCENT %'
COL blocker FOR A12 HEA 'ROOT|BLOCKER|SID_SERIAL#';
COL blocker_machine FOR A64 HEA 'ROOT BLOCKER MACHINE';
COL blocker_status FOR A80 HEA 'ROOT BLOCKER SESSION STATUS';
COL blocker_sql_id FOR A13 HEA 'ROOT|BLOCKER|SQL_ID';
COL blocker_sql_text FOR A80 TRUNC HEA 'ROOT BLOCKER SQL_TEXT';
COL wait_class_event FOR A80 TRUNC HEA 'BLOCKEE(S) WAIT CLASS AND EVENT';
--
PRO
PRO Root Blocker contribution percent by Status (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
ash AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, 
       sample_time, 
       machine, 
       session_id, 
       session_serial#, 
       blocking_session, 
       blocking_session_serial#, 
       session_state, 
       wait_class, 
       event,
       sql_id,
       top_level_sql_id
  FROM v$active_session_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
),
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
all_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       a.sample_id, CAST(a.sample_time AS DATE) sample_time, a.machine, a.session_id, a.session_serial#, a.blocking_session, a.blocking_session_serial#, 
       'ACTIVE' status, session_state, wait_class, event, sql_id, top_level_sql_id
  FROM ash a
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       i.sample_id, i.sample_time, NULL machine, i.session_id, i.session_serial#, TO_NUMBER(NULL), TO_NUMBER(NULL), 
       'INACTIVE or UNKNOWN' status, NULL session_state, NULL wait_class, NULL event, NULL sql_id, NULL top_level_sql_id
  FROM inactive_sessions i
),
sess_history AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, machine, session_id, session_serial#, status, session_state, wait_class, event, sql_id, top_level_sql_id,
       LEVEL lvl,
       CONNECT_BY_ROOT machine blocker_machine,
       CONNECT_BY_ROOT session_id blocker_session,
       CONNECT_BY_ROOT session_serial# blocker_session_serial#,
       CONNECT_BY_ISLEAF AS leaf
  FROM all_sessions
 START WITH blocking_session IS NULL AND blocking_session_serial# IS NULL
CONNECT BY sample_id = PRIOR sample_id AND blocking_session = PRIOR session_id AND blocking_session_serial# = PRIOR session_serial#
),
blockers AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, status, session_state, wait_class, event, sql_id, top_level_sql_id, session_id, session_serial#
  FROM sess_history
 WHERE lvl = 1
),
blockees AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, status, wait_class, event, blocker_session, blocker_session_serial#, COUNT(*) cnt
  FROM sess_history
 WHERE lvl > 1
 GROUP BY
       sample_id, sample_time, status, wait_class, event, blocker_session, blocker_session_serial#
),
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
       b.session_id blocker_session_id, 
       b.session_serial# blocker_session_serial#,
       NVL(a.cnt, 0) sessions_blocked
  FROM blockers b,
       blockees a,
       machines m
 WHERE a.sample_id(+) = b.sample_id
   AND a.sample_time(+) = b.sample_time
   AND a.blocker_session(+) = b.session_id
   AND a.blocker_session_serial#(+) = b.session_serial#
   AND m.session_id(+) = b.session_id
   AND m.session_serial#(+) = b.session_serial#
)
/****************************************************************************************/
,
detail AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       b.time,
       b.sessions_blocked blocked,
       b.blocker_session_id||','||b.blocker_session_serial# blocker,
       b.machine blocker_machine,
       CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
       b.blocker_sql_id,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
  FROM blockers_and_blockees b
 WHERE b.sessions_blocked > 0
),
summary AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
       blocker_status
  FROM detail
 GROUP BY
       blocker_status
)
SELECT * 
       FROM summary
 WHERE percent > 1
 ORDER BY
       1 DESC
FETCH FIRST &&cs_top_n. ROWS ONLY
/
--
PRO
PRO Root Blocker contribution percent by Status and SQL_ID (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
ash AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, 
       sample_time, 
       machine, 
       session_id, 
       session_serial#, 
       blocking_session, 
       blocking_session_serial#, 
       session_state, 
       wait_class, 
       event,
       sql_id,
       top_level_sql_id
  FROM v$active_session_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
),
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
all_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       a.sample_id, CAST(a.sample_time AS DATE) sample_time, a.machine, a.session_id, a.session_serial#, a.blocking_session, a.blocking_session_serial#, 
       'ACTIVE' status, session_state, wait_class, event, sql_id, top_level_sql_id
  FROM ash a
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       i.sample_id, i.sample_time, NULL machine, i.session_id, i.session_serial#, TO_NUMBER(NULL), TO_NUMBER(NULL), 
       'INACTIVE or UNKNOWN' status, NULL session_state, NULL wait_class, NULL event, NULL sql_id, NULL top_level_sql_id
  FROM inactive_sessions i
),
sess_history AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, machine, session_id, session_serial#, status, session_state, wait_class, event, sql_id, top_level_sql_id,
       LEVEL lvl,
       CONNECT_BY_ROOT machine blocker_machine,
       CONNECT_BY_ROOT session_id blocker_session,
       CONNECT_BY_ROOT session_serial# blocker_session_serial#,
       CONNECT_BY_ISLEAF AS leaf
  FROM all_sessions
 START WITH blocking_session IS NULL AND blocking_session_serial# IS NULL
CONNECT BY sample_id = PRIOR sample_id AND blocking_session = PRIOR session_id AND blocking_session_serial# = PRIOR session_serial#
),
blockers AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, status, session_state, wait_class, event, sql_id, top_level_sql_id, session_id, session_serial#
  FROM sess_history
 WHERE lvl = 1
),
blockees AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, status, wait_class, event, blocker_session, blocker_session_serial#, COUNT(*) cnt
  FROM sess_history
 WHERE lvl > 1
 GROUP BY
       sample_id, sample_time, status, wait_class, event, blocker_session, blocker_session_serial#
),
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
       b.session_id blocker_session_id, 
       b.session_serial# blocker_session_serial#,
       NVL(a.cnt, 0) sessions_blocked
  FROM blockers b,
       blockees a,
       machines m
 WHERE a.sample_id(+) = b.sample_id
   AND a.sample_time(+) = b.sample_time
   AND a.blocker_session(+) = b.session_id
   AND a.blocker_session_serial#(+) = b.session_serial#
   AND m.session_id(+) = b.session_id
   AND m.session_serial#(+) = b.session_serial#
)
/****************************************************************************************/
,
detail AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       b.time,
       b.sessions_blocked blocked,
       b.blocker_session_id||','||b.blocker_session_serial# blocker,
       b.machine blocker_machine,
       CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
       b.blocker_sql_id,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
  FROM blockers_and_blockees b
 WHERE b.sessions_blocked > 0
),
summary AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
       blocker_status,
       blocker_sql_id,
       blocker_sql_text
  FROM detail
 GROUP BY
       blocker_status,
       blocker_sql_id,
       blocker_sql_text
)
SELECT * 
       FROM summary
 WHERE percent > 1
 ORDER BY
       1 DESC
FETCH FIRST &&cs_top_n. ROWS ONLY
/
--
PRO
PRO Root Blocker contribution percent by Machine, Status and SQL_ID (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
ash AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, 
       sample_time, 
       machine, 
       session_id, 
       session_serial#, 
       blocking_session, 
       blocking_session_serial#, 
       session_state, 
       wait_class, 
       event,
       sql_id,
       top_level_sql_id
  FROM v$active_session_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
),
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
all_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       a.sample_id, CAST(a.sample_time AS DATE) sample_time, a.machine, a.session_id, a.session_serial#, a.blocking_session, a.blocking_session_serial#, 
       'ACTIVE' status, session_state, wait_class, event, sql_id, top_level_sql_id
  FROM ash a
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       i.sample_id, i.sample_time, NULL machine, i.session_id, i.session_serial#, TO_NUMBER(NULL), TO_NUMBER(NULL), 
       'INACTIVE or UNKNOWN' status, NULL session_state, NULL wait_class, NULL event, NULL sql_id, NULL top_level_sql_id
  FROM inactive_sessions i
),
sess_history AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, machine, session_id, session_serial#, status, session_state, wait_class, event, sql_id, top_level_sql_id,
       LEVEL lvl,
       CONNECT_BY_ROOT machine blocker_machine,
       CONNECT_BY_ROOT session_id blocker_session,
       CONNECT_BY_ROOT session_serial# blocker_session_serial#,
       CONNECT_BY_ISLEAF AS leaf
  FROM all_sessions
 START WITH blocking_session IS NULL AND blocking_session_serial# IS NULL
CONNECT BY sample_id = PRIOR sample_id AND blocking_session = PRIOR session_id AND blocking_session_serial# = PRIOR session_serial#
),
blockers AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, status, session_state, wait_class, event, sql_id, top_level_sql_id, session_id, session_serial#
  FROM sess_history
 WHERE lvl = 1
),
blockees AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, status, wait_class, event, blocker_session, blocker_session_serial#, COUNT(*) cnt
  FROM sess_history
 WHERE lvl > 1
 GROUP BY
       sample_id, sample_time, status, wait_class, event, blocker_session, blocker_session_serial#
),
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
       b.session_id blocker_session_id, 
       b.session_serial# blocker_session_serial#,
       NVL(a.cnt, 0) sessions_blocked
  FROM blockers b,
       blockees a,
       machines m
 WHERE a.sample_id(+) = b.sample_id
   AND a.sample_time(+) = b.sample_time
   AND a.blocker_session(+) = b.session_id
   AND a.blocker_session_serial#(+) = b.session_serial#
   AND m.session_id(+) = b.session_id
   AND m.session_serial#(+) = b.session_serial#
)
/****************************************************************************************/
,
detail AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       b.time,
       b.sessions_blocked blocked,
       b.blocker_session_id||','||b.blocker_session_serial# blocker,
       b.machine blocker_machine,
       CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
       b.blocker_sql_id,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
  FROM blockers_and_blockees b
 WHERE b.sessions_blocked > 0
),
summary AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
       blocker_machine,
       blocker_status,
       blocker_sql_id,
       blocker_sql_text
  FROM detail
 GROUP BY
       blocker_machine,
       blocker_status,
       blocker_sql_id,
       blocker_sql_text
)
SELECT * 
       FROM summary
 WHERE percent > 1
 ORDER BY
       1 DESC
FETCH FIRST &&cs_top_n. ROWS ONLY
/
--
PRO
PRO Root Blocker contribution percent by SID, Serial#, Machine, Status and SQL_ID (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
ash AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, 
       sample_time, 
       machine, 
       session_id, 
       session_serial#, 
       blocking_session, 
       blocking_session_serial#, 
       session_state, 
       wait_class, 
       event,
       sql_id,
       top_level_sql_id
  FROM v$active_session_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
),
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
all_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       a.sample_id, CAST(a.sample_time AS DATE) sample_time, a.machine, a.session_id, a.session_serial#, a.blocking_session, a.blocking_session_serial#, 
       'ACTIVE' status, session_state, wait_class, event, sql_id, top_level_sql_id
  FROM ash a
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       i.sample_id, i.sample_time, NULL machine, i.session_id, i.session_serial#, TO_NUMBER(NULL), TO_NUMBER(NULL), 
       'INACTIVE or UNKNOWN' status, NULL session_state, NULL wait_class, NULL event, NULL sql_id, NULL top_level_sql_id
  FROM inactive_sessions i
),
sess_history AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, machine, session_id, session_serial#, status, session_state, wait_class, event, sql_id, top_level_sql_id,
       LEVEL lvl,
       CONNECT_BY_ROOT machine blocker_machine,
       CONNECT_BY_ROOT session_id blocker_session,
       CONNECT_BY_ROOT session_serial# blocker_session_serial#,
       CONNECT_BY_ISLEAF AS leaf
  FROM all_sessions
 START WITH blocking_session IS NULL AND blocking_session_serial# IS NULL
CONNECT BY sample_id = PRIOR sample_id AND blocking_session = PRIOR session_id AND blocking_session_serial# = PRIOR session_serial#
),
blockers AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, status, session_state, wait_class, event, sql_id, top_level_sql_id, session_id, session_serial#
  FROM sess_history
 WHERE lvl = 1
),
blockees AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, status, wait_class, event, blocker_session, blocker_session_serial#, COUNT(*) cnt
  FROM sess_history
 WHERE lvl > 1
 GROUP BY
       sample_id, sample_time, status, wait_class, event, blocker_session, blocker_session_serial#
),
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
       b.session_id blocker_session_id, 
       b.session_serial# blocker_session_serial#,
       NVL(a.cnt, 0) sessions_blocked
  FROM blockers b,
       blockees a,
       machines m
 WHERE a.sample_id(+) = b.sample_id
   AND a.sample_time(+) = b.sample_time
   AND a.blocker_session(+) = b.session_id
   AND a.blocker_session_serial#(+) = b.session_serial#
   AND m.session_id(+) = b.session_id
   AND m.session_serial#(+) = b.session_serial#
)
/****************************************************************************************/
,
detail AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       b.time,
       b.sessions_blocked blocked,
       b.blocker_session_id||','||b.blocker_session_serial# blocker,
       b.machine blocker_machine,
       CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
       b.blocker_sql_id,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
  FROM blockers_and_blockees b
 WHERE b.sessions_blocked > 0
),
summary AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       100 * SUM(blocked) / SUM(SUM(blocked)) OVER () percent,
       blocker,
       blocker_machine,
       blocker_status,
       blocker_sql_id,
       blocker_sql_text
  FROM detail
 GROUP BY
       blocker,
       blocker_machine,
       blocker_status,
       blocker_sql_id,
       blocker_sql_text
)
SELECT * 
       FROM summary
 WHERE percent > 1
 ORDER BY
       1 DESC
FETCH FIRST &&cs_top_n. ROWS ONLY
/
--
PRO
PRO Sample of Blocked Sessions (between &&cs_sample_time_from. and &&cs_sample_time_to. UTC)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
WITH 
ash AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, 
       sample_time, 
       machine, 
       session_id, 
       session_serial#, 
       blocking_session, 
       blocking_session_serial#, 
       session_state, 
       wait_class, 
       event,
       sql_id,
       top_level_sql_id
  FROM v$active_session_history
 WHERE sample_time >= TO_TIMESTAMP('&&cs_sample_time_from.', '&&cs_datetime_full_format.') 
   AND sample_time < TO_TIMESTAMP('&&cs_sample_time_to.', '&&cs_datetime_full_format.')
),
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
all_sessions AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       a.sample_id, CAST(a.sample_time AS DATE) sample_time, a.machine, a.session_id, a.session_serial#, a.blocking_session, a.blocking_session_serial#, 
       'ACTIVE' status, session_state, wait_class, event, sql_id, top_level_sql_id
  FROM ash a
 UNION ALL
SELECT /*+ MATERIALIZE NO_MERGE */
       i.sample_id, i.sample_time, NULL machine, i.session_id, i.session_serial#, TO_NUMBER(NULL), TO_NUMBER(NULL), 
       'INACTIVE or UNKNOWN' status, NULL session_state, NULL wait_class, NULL event, NULL sql_id, NULL top_level_sql_id
  FROM inactive_sessions i
),
sess_history AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, machine, session_id, session_serial#, status, session_state, wait_class, event, sql_id, top_level_sql_id,
       LEVEL lvl,
       CONNECT_BY_ROOT machine blocker_machine,
       CONNECT_BY_ROOT session_id blocker_session,
       CONNECT_BY_ROOT session_serial# blocker_session_serial#,
       CONNECT_BY_ISLEAF AS leaf
  FROM all_sessions
 START WITH blocking_session IS NULL AND blocking_session_serial# IS NULL
CONNECT BY sample_id = PRIOR sample_id AND blocking_session = PRIOR session_id AND blocking_session_serial# = PRIOR session_serial#
),
blockers AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, status, session_state, wait_class, event, sql_id, top_level_sql_id, session_id, session_serial#
  FROM sess_history
 WHERE lvl = 1
),
blockees AS (
SELECT /*+ MATERIALIZE NO_MERGE */
       sample_id, sample_time, status, wait_class, event, blocker_session, blocker_session_serial#, COUNT(*) cnt
  FROM sess_history
 WHERE lvl > 1
 GROUP BY
       sample_id, sample_time, status, wait_class, event, blocker_session, blocker_session_serial#
),
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
       b.session_id blocker_session_id, 
       b.session_serial# blocker_session_serial#,
       NVL(a.cnt, 0) sessions_blocked
  FROM blockers b,
       blockees a,
       machines m
 WHERE a.sample_id(+) = b.sample_id
   AND a.sample_time(+) = b.sample_time
   AND a.blocker_session(+) = b.session_id
   AND a.blocker_session_serial#(+) = b.session_serial#
   AND m.session_id(+) = b.session_id
   AND m.session_serial#(+) = b.session_serial#
)
/****************************************************************************************/
SELECT b.time,
       b.wait_class_event,
       b.sessions_blocked blocked,
       b.blocker_session_id||','||b.blocker_session_serial# blocker,
       b.machine blocker_machine,
       --CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN b.blocker_status ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
       CASE b.blocker_status WHEN 'INACTIVE or UNKNOWN' THEN (CASE b.machine WHEN '&&cs_host_name.' THEN 'UNKNOWN' ELSE 'INACTIVE' END) ELSE ('ACTIVE '||CASE b.blocker_session_state WHEN 'ON CPU' THEN b.blocker_session_state ELSE 'WAITING ON '||b.blocker_wait_class||' - '||b.blocker_event END) END blocker_status,
       b.blocker_sql_id,
       (SELECT s.sql_text FROM v$sql s WHERE s.sql_id = b.blocker_sql_id AND ROWNUM = 1) blocker_sql_text
  FROM blockers_and_blockees b
 WHERE b.sessions_blocked > 0
 ORDER BY
       b.time,
       b.blocker_session_id
/
--
PRO
PRO ROOT BLOCKER SESSION STATUS "INACTIVE" means: Database is waiting for Application Host to release LOCK, while "UNKNOWN" could be a BACKGROUND session on CDB$ROOT.
--
PRO
PRO SQL> @&&cs_script_name..sql "&&cs_sample_time_from." "&&cs_sample_time_to." 
--
@@cs_internal/cs_spool_tail.sql
--
--ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
@@cs_internal/cs_undef.sql
@@cs_internal/cs_reset.sql
--