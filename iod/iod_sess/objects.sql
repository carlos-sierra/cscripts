WHENEVER SQLERROR EXIT FAILURE;

-- create repository, partitioned and compressed
-- code preserves 2 months of data
DECLARE
  l_exists NUMBER;
  l_sql_statement VARCHAR2(32767) := q'[
CREATE TABLE &&1..inactive_sessions_audit_trail (
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
PARTITION BY RANGE (snap_time)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
PARTITION before_2017_12_01 VALUES LESS THAN (TO_DATE('2017-12-01', 'YYYY-MM-DD')),
PARTITION before_2018_01_01 VALUES LESS THAN (TO_DATE('2018-01-01', 'YYYY-MM-DD')),
PARTITION before_2018_02_01 VALUES LESS THAN (TO_DATE('2018-02-01', 'YYYY-MM-DD')),
PARTITION before_2018_03_01 VALUES LESS THAN (TO_DATE('2018-03-01', 'YYYY-MM-DD')),
PARTITION before_2018_04_01 VALUES LESS THAN (TO_DATE('2018-04-01', 'YYYY-MM-DD'))
)
ROW STORE COMPRESS ADVANCED
TABLESPACE IOD
]';
  l_sql_statement2 VARCHAR2(32767) := q'[
ALTER TABLE &&1..inactive_sessions_audit_trail ADD (
  sql_id                         VARCHAR2(13),
  sql_exec_start                 DATE,
  prev_exec_start                DATE
)
]';
BEGIN
  SELECT COUNT(*) INTO l_exists FROM dba_tables WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('inactive_sessions_audit_trail');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement;
  END IF;
  SELECT COUNT(*) INTO l_exists FROM dba_tab_columns WHERE owner = UPPER(TRIM('&&1.')) AND table_name = UPPER('inactive_sessions_audit_trail') AND column_name = UPPER('sql_id');
  IF l_exists = 0 THEN
    EXECUTE IMMEDIATE l_sql_statement2;
  END IF;
END;
/

SET LONG 40000;
SET LONGC 400 ;
SET PAGES 100;
SET LINE 200;
SET HEA OFF;
SELECT DBMS_METADATA.GET_DDL('TABLE', UPPER('inactive_sessions_audit_trail'), UPPER('&&1.')) inactive_sessions_audit_trail FROM DUAL
/
SET HEA ON;

