REM Dummy line to avoid "usage: r_sql_exec" when executed using iodcli
----------------------------------------------------------------------------------------
--
-- File name:   cs_fix_configuration_and_parameters.sql
--
-- Purpose:     Fix database configuration and parameters set incorrectly
--
-- Author:      Carlos Sierra
--
-- Version:     2021/11/03
--
-- Usage:       Execute connected to CDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_fix_configuration_and_parameters.sql
--
-- Notes:       Developed and tested on 12.1.0.2 and 19c
--
---------------------------------------------------------------------------------------
--
WHENEVER OSERROR CONTINUE;
WHENEVER SQLERROR EXIT FAILURE;
--
ALTER SESSION SET container = CDB$ROOT;
--
-- some changes should be applied only to primary, or command syntax may differ between primary and standby
--
VAR is_primary CHAR(1);
BEGIN
  SELECT CASE WHEN open_mode = 'READ WRITE' AND database_role = 'PRIMARY' THEN 'Y' ELSE 'N' END INTO :is_primary FROM v$database;
END;
/
--
-- job_queue_processes = 10 (DBPERF-7579)
--
DECLARE
  is_correct CHAR(1);
BEGIN
  SELECT CASE WHEN COUNT(*) = 1 THEN 'Y' ELSE 'N' END INTO is_correct FROM v$system_parameter WHERE name = 'job_queue_processes' AND value = '10';
  IF is_correct = 'N' THEN
    EXECUTE IMMEDIATE 'alter system set job_queue_processes=10 scope=both';
  END IF;
END;
/
--
-- session_cached_cursors = 400 (DBPERF-7642)
--
DECLARE
  is_correct CHAR(1);
BEGIN
  SELECT CASE WHEN COUNT(*) = 1 THEN 'Y' ELSE 'N' END INTO is_correct FROM v$system_parameter WHERE name = 'session_cached_cursors' AND value = '400';
  IF is_correct = 'N' THEN
    EXECUTE IMMEDIATE 'alter system set session_cached_cursors=400 deferred scope=both';
  END IF;
END;
/
--
-- cursor_invalidation = DEFERRED (DBPERF-7640)
--
DECLARE
  is_correct CHAR(1);
BEGIN
  $IF DBMS_DB_VERSION.ver_le_12_1
  $THEN
    NULL;
  $ELSE
    SELECT CASE WHEN COUNT(*) = 1 THEN 'Y' ELSE 'N' END INTO is_correct FROM v$system_parameter WHERE name = 'cursor_invalidation' AND value = 'DEFERRED';
    IF is_correct = 'N' THEN
      EXECUTE IMMEDIATE 'alter system set cursor_invalidation=DEFERRED scope=both';
    END IF;
  $END
  NULL;
END;
/
--
-- optimizer_adaptive_plans = FALSE (CHANGE-31454)
--
DECLARE
  is_correct CHAR(1);
BEGIN
  SELECT CASE WHEN COUNT(*) = 1 THEN 'Y' ELSE 'N' END INTO is_correct FROM v$system_parameter WHERE name = 'optimizer_adaptive_plans' AND value = 'FALSE';
  IF is_correct = 'N' THEN
    EXECUTE IMMEDIATE 'alter system set optimizer_adaptive_plans=FALSE scope=both';
  END IF;
END;
/
--
-- optimizer_adaptive_statistics = FALSE (CHANGE-146519)
--
DECLARE
  is_correct CHAR(1);
BEGIN
  SELECT CASE WHEN COUNT(*) = 1 THEN 'Y' ELSE 'N' END INTO is_correct FROM v$system_parameter WHERE name = 'optimizer_adaptive_statistics' AND value = 'FALSE';
  IF is_correct = 'N' THEN
    EXECUTE IMMEDIATE 'alter system set optimizer_adaptive_statistics=FALSE scope=both';
  END IF;
END;
/
--
-- optimizer_adaptive_reporting_only = TRUE (DBPERF-6981)
--
DECLARE
  is_correct CHAR(1);
BEGIN
  SELECT CASE WHEN COUNT(*) = 1 THEN 'Y' ELSE 'N' END INTO is_correct FROM v$system_parameter WHERE name = 'optimizer_adaptive_reporting_only' AND value = 'TRUE';
  IF is_correct = 'N' THEN
    EXECUTE IMMEDIATE 'alter system set optimizer_adaptive_reporting_only=TRUE scope=both';
  END IF;
END;
/
--
-- dba_hist_wr_control.topnsql = 600 (DBPERF-7602)
--
DECLARE
  is_correct CHAR(1);
BEGIN
  IF :is_primary = 'Y' THEN
    SELECT CASE topnsql WHEN '600' THEN 'Y' ELSE 'N' END INTO is_correct FROM dba_hist_wr_control;
    IF is_correct = 'N' THEN
      DBMS_WORKLOAD_REPOSITORY.modify_snapshot_settings(topnsql=>600);
    END IF;
  END IF;
END;
/
