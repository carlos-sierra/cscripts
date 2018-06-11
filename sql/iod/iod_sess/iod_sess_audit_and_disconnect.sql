-- IOD_SESS_AUDIT_AND_DISCONNECT (IOD_REPEATING_SESS_AUDIT_AND_DISCONNECT)
-- AUDITs INACTIVE sessions.
-- Kills inactive sessions holding a lock on an application table for 
-- over N seconds. (e.g. KievTransactions).
-- Kills also sniped sessions.
--
-- hours_allowed should be consistent with OEM interval (e.g. hours_allowed = 1 = 1h OEM job interval)
-- sleep_seconds is interval between API call cycles (e.g. 30 for every 30s, 20 for every 20s)
-- e.g.: hours_allowed = 1 and sleep_seconds = 30, then audit_and_disconnect is called 120 times (every 30s during 1h)
-- e.g.: hours_allowed = 24 and sleep_seconds = 20, then audit_and_disconnect is called 4320 times (every 20s during 1d)
--
DEF hours_allowed = '1';
DEF sleep_seconds = '20';
--
DEF table_name = 'KIEVTRANSACTIONS';
DEF lock_secs_thres = '30';
DEF inac_secs_thres = '3600';
DEF snip_secs_thres = '300';
DEF snip_idle_profile = 'APP_PROFILE';
DEF snip_candidates = 'Y';
DEF sniped_sessions = 'Y';
DEF tm_locks = 'Y';
DEF tx_locks = 'Y';
DEF kill_locked = 'Y';
DEF kill_idle = 'N';
--
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
WHENEVER SQLERROR EXIT FAILURE;
--
-- exit graciously if package does not exist. execute twice to overcome possible ORA-04068
SET SERVEROUT ON SIZE UNLIMITED;
WHENEVER SQLERROR CONTINUE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('API version: '||c##iod.iod_sess.gk_package_version);
END;
/
WHENEVER SQLERROR EXIT SUCCESS;
BEGIN
  DBMS_OUTPUT.PUT_LINE('API version: '||c##iod.iod_sess.gk_package_version);
END;
/
WHENEVER SQLERROR EXIT FAILURE;
--
ALTER SESSION SET tracefile_identifier = 'iod_sess';
ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 8';
--
SET HEA ON LIN 500 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF;
SET HEA OFF;
-- dynamic SQL below is to allow for new code versions (pl/sql pks and pkb) to compile between executions
-- else, if cycle where inside pl/sql pkg, then it would be in execution almost all the time (except between jobs)
-- and odo may fail, while trying to aquire resource to compile package
SPO iod_sess_audit_and_disconnect_driver.sql
DECLARE 
  l_executions NUMBER := &&hours_allowed. * 3600 / &&sleep_seconds.;
BEGIN
  FOR i IN 1 .. l_executions
  LOOP
    DBMS_OUTPUT.PUT_LINE(q'[-- ]');
    DBMS_OUTPUT.PUT_LINE(q'[-- circumvent ORA-04068: existing state of packages has been discarded]');
    DBMS_OUTPUT.PUT_LINE(q'[WHENEVER SQLERROR CONTINUE;]');
    DBMS_OUTPUT.PUT_LINE(q'[SELECT 'c##iod.iod_sess version: '||c##iod.iod_sess.get_package_version FROM DUAL;]');
    DBMS_OUTPUT.PUT_LINE(q'[SELECT 'c##iod.iod_sess version: '||c##iod.iod_sess.get_package_version FROM DUAL;]');
    DBMS_OUTPUT.PUT_LINE(q'[WHENEVER SQLERROR EXIT FAILURE;]');
    DBMS_OUTPUT.PUT_LINE(q'[-- ]');
    DBMS_OUTPUT.PUT_LINE(q'[PRO begin ]'||i||q'[ out of ]'||l_executions);
    DBMS_OUTPUT.PUT_LINE(q'[BEGIN]');
    DBMS_OUTPUT.PUT_LINE(q'[IF SYSDATE < TO_DATE(']'||TO_CHAR(SYSDATE + (&&hours_allowed./24), 'YYYY-MM-DD"T"HH24:MI:SS')||q'[','YYYY-MM-DD"T"HH24:MI:SS') THEN ]');
    DBMS_OUTPUT.PUT_LINE(q'[c##iod.iod_sess.audit_and_disconnect]');
    DBMS_OUTPUT.PUT_LINE(q'[(]');
    DBMS_OUTPUT.PUT_LINE(q'[p_table_name        => '&&table_name.', ]');
    DBMS_OUTPUT.PUT_LINE(q'[p_lock_secs_thres   => &&lock_secs_thres., ]');
    DBMS_OUTPUT.PUT_LINE(q'[p_inac_secs_thres   => &&inac_secs_thres., ]');
    DBMS_OUTPUT.PUT_LINE(q'[p_snip_secs_thres   => &&snip_secs_thres., ]');
    DBMS_OUTPUT.PUT_LINE(q'[p_snip_idle_profile => '&&snip_idle_profile.', ]');
    DBMS_OUTPUT.PUT_LINE(q'[p_snip_candidates   => '&&snip_candidates.', ]');
    DBMS_OUTPUT.PUT_LINE(q'[p_sniped_sessions   => '&&sniped_sessions.', ]');
    DBMS_OUTPUT.PUT_LINE(q'[p_tm_locks          => '&&tm_locks.', ]');
    DBMS_OUTPUT.PUT_LINE(q'[p_tx_locks          => '&&tx_locks.',  ]');
    DBMS_OUTPUT.PUT_LINE(q'[p_kill_locked       => '&&kill_locked.', ]');
    DBMS_OUTPUT.PUT_LINE(q'[p_kill_idle         => '&&kill_idle.', ]');
    DBMS_OUTPUT.PUT_LINE(q'[p_expire_date       => TO_DATE(']'||TO_CHAR(SYSDATE + (&&hours_allowed./24), 'YYYY-MM-DD"T"HH24:MI:SS')||q'[','YYYY-MM-DD"T"HH24:MI:SS')]');
    DBMS_OUTPUT.PUT_LINE(q'[);]');
    DBMS_OUTPUT.PUT_LINE(q'[END IF;]');
    DBMS_OUTPUT.PUT_LINE(q'[END;]');
    DBMS_OUTPUT.PUT_LINE(q'[/]');
    DBMS_OUTPUT.PUT_LINE(q'[PRO end ]'||i||q'[ out of ]'||l_executions);
    IF i < l_executions THEN
      DBMS_OUTPUT.PUT_LINE(q'[PRO sleeping for &&sleep_seconds. seconds... Zzz Zzz Zzz]');
      DBMS_OUTPUT.PUT_LINE(q'[BEGIN]');
      DBMS_OUTPUT.PUT_LINE(q'[IF SYSDATE < TO_DATE(']'||TO_CHAR(SYSDATE + (&&hours_allowed./24), 'YYYY-MM-DD"T"HH24:MI:SS')||q'[','YYYY-MM-DD"T"HH24:MI:SS') THEN ]');
      DBMS_OUTPUT.PUT_LINE(q'[DBMS_LOCK.SLEEP(&&sleep_seconds.);]');
      DBMS_OUTPUT.PUT_LINE(q'[END IF;]');
      DBMS_OUTPUT.PUT_LINE(q'[END;]');
      DBMS_OUTPUT.PUT_LINE(q'[/]');
    END IF;
  END LOOP;
END;
/
SPO OFF;
--
COL zip_file_name NEW_V zip_file_name;
COL output_file_name NEW_V output_file_name;
SELECT '/tmp/iod_sess_'||LOWER(name)||'_'||LOWER(REPLACE(SUBSTR(host_name, 1 + INSTR(host_name, '.', 1, 2), 30), '.', '_')) zip_file_name FROM v$database, v$instance;
SELECT '&&zip_file_name._'||TO_CHAR(SYSDATE, 'dd"T"hh24') output_file_name FROM DUAL;
--
SET TIMI ON;
SPO &&output_file_name..txt;
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
PRO &&output_file_name..txt;
--
@iod_sess_audit_and_disconnect_driver.sql
--
PRO &&output_file_name..txt;
SELECT value FROM v$diag_info WHERE name = 'Default Trace File';
SPO OFF;
HOS rm iod_sess_audit_and_disconnect_driver.sql
HOS zip -mj &&zip_file_name..zip &&output_file_name..txt
HOS unzip -l &&zip_file_name..zip
WHENEVER SQLERROR CONTINUE;
--
ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
ALTER SESSION SET SQL_TRACE = FALSE;
