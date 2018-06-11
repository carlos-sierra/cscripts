-- exit graciously if executed on standby
-- exit graciously if executed on standby
WHENEVER SQLERROR EXIT SUCCESS;
DECLARE
  l_open_mode VARCHAR2(20);
BEGIN
  SELECT open_mode INTO l_open_mode FROM v$database;
  IF l_open_mode <> 'READ WRITE' THEN
    raise_application_error(-20000, 'Must execute on PRIMARY');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
ALTER SESSION SET nls_date_format = 'YYYY-MM-DD"T"HH24:MI:SS';
--
PRO
PRO Killed Sessions
PRO ~~~~~~~~~~~~~~~
SELECT *
  FROM c##iod.inactive_sessions_audit_trail
 WHERE snap_time > TO_DATE('2018-04-18T15', 'YYYY-MM-DD"T"HH24')
   AND killed = 'Y'
 ORDER BY
       snap_time, sid
/
--
PRO
PRO TX and TM Sessions >= 1s
PRO ~~~~~~~~~~~~~~~~~~
SELECT *
  FROM c##iod.inactive_sessions_audit_trail
 WHERE snap_time > TO_DATE('2018-04-18T15', 'YYYY-MM-DD"T"HH24')
   AND pty IN (1, 2)
   AND last_call_et >= 1
   AND ctime >= 1
 ORDER BY
       snap_time, sid
/
--
PRO
PRO Sessions Summary
PRO ~~~~~~~~~~~~~~~~
SELECT COUNT(*), pty, death_row, killed
  FROM c##iod.inactive_sessions_audit_trail
 WHERE snap_time > TO_DATE('2018-04-18T15', 'YYYY-MM-DD"T"HH24')
 GROUP BY
       pty, death_row, killed
 ORDER BY
       1 DESC
/
--
PRO
PRO TX and TM Sessions
PRO ~~~~~~~~~~~~~~~~~~
SELECT *
  FROM c##iod.inactive_sessions_audit_trail
 WHERE snap_time > TO_DATE('2018-04-18T15', 'YYYY-MM-DD"T"HH24')
   AND pty IN (1, 2)
 ORDER BY
       snap_time, sid
/
--
PRO
PRO Sessions inactive for over 1h
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT MAX(last_call_et) last_call_et, service_name, machine, logon_time, sid, serial#
  FROM c##iod.inactive_sessions_audit_trail
 WHERE snap_time > TO_DATE('2018-04-18T15', 'YYYY-MM-DD"T"HH24')
 GROUP BY
       service_name, machine, logon_time, sid, serial#
HAVING MAX(last_call_et) > 3600
 ORDER BY
       1 DESC
/
--
/*
inactive_sessions_audit_trail (
  pty                            NUMBER,
  death_row                      VARCHAR2(1),
  sid                            NUMBER,
  serial#                        NUMBER,
  spid                           NUMBER,
  status                         VARCHAR2(8),
  logon_time                     DATE,
  snap_time                      DATE,
  killed                         VARCHAR2(1),
  last_call_et                   NUMBER,
  ctime                          NUMBER,
  type                           VARCHAR2(2),
  lmode                          NUMBER,
  service_name                   VARCHAR2(64),
  machine                        VARCHAR2(64),
  osuser                         VARCHAR2(30),
  program                        VARCHAR2(48),
  module                         VARCHAR2(64),
  client_info                    VARCHAR2(64),
  prev_sql_id                    VARCHAR2(13),
  username                       VARCHAR2(30),
  object_id                      NUMBER,
  con_id                         NUMBER,
  pdb_name                       VARCHAR2(30),
  reason                         VARCHAR2(30)
)
*/
