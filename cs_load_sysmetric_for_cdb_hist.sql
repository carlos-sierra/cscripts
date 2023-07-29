----------------------------------------------------------------------------------------
--
-- File name:   cs_load_sysmetric_for_cdb_hist.sql
--
-- Purpose:     System Load as per DBA_HIST_SYSMETRIC_SUMMARY View for a CDB (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/08/09
--
-- Usage:       Execute connected to CDB and pass range of AWR snapshots.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_load_sysmetric_for_cdb_hist.sql
--
-- Notes:       Stand-alone script
--
--              Developed and tested on 12.1.0.2 and 19c.
--
---------------------------------------------------------------------------------------
--
DEF view_name = 'dba_hist_sysmetric_summary';
DEF common_predicate = "";
DEF script_name = 'cs_load_sysmetric_for_cdb_hist';
--
COL cs_date NEW_V cs_date NOPRI;
COL cs_host NEW_V cs_host NOPRI;
COL cs_db NEW_V cs_db NOPRI;
COL cs_con_name NEW_V cs_con_name NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS') AS cs_date, SYS_CONTEXT('USERENV','HOST') AS cs_host, UPPER(name) AS cs_db, SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con_name FROM v$database;
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
COL report_date_time NEW_V report_date_time NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24.MI.SS"Z"') AS report_date_time FROM DUAL;
SPO /tmp/&&script_name._&&report_date_time..txt
--
PRO
PRO Specify the number of days of snapshots to choose from
PRO
PRO Enter number of days: [{1}|0-60]
DEF num_days = '&1'
UNDEF 1;
--
COL snap_id NEW_V snap_id FOR A7;
COL prior_snap_id NEW_V prior_snap_id FOR A7 NOPRI;
SELECT LPAD(TO_CHAR(snap_id), 7, ' ') AS snap_id, CAST(end_interval_time AS DATE) AS snap_time, LPAD(TO_CHAR(snap_id - 1), 7, ' ') AS prior_snap_id
  FROM dba_hist_snapshot
 WHERE instance_number = SYS_CONTEXT('USERENV','INSTANCE')
   AND dbid = (SELECT dbid FROM v$database)
   AND CAST(end_interval_time AS DATE) > SYSDATE - TO_NUMBER(NVL('&&num_days.', '1'))
 ORDER BY
       snap_id
/
--
PRO
PRO Enter begin snap_id: [{&&prior_snap_id.}]
DEF begin_snap_id = '&2.';
UNDEF 2;
COL begin_snap_id NEW_V begin_snap_id NOPRI;
SELECT NVL('&&begin_snap_id.', '&&prior_snap_id.') AS begin_snap_id FROM DUAL;
--
PRO
PRO Enter end snap_id: [{&&snap_id.}]
DEF end_snap_id = '&3.';
UNDEF 3;
COL end_snap_id NEW_V end_snap_id NOPRI;
SELECT NVL('&&end_snap_id.', '&&snap_id.') AS end_snap_id FROM DUAL;
--
-- @@cs_internal/&&cs_set_container_to_cdb_root.
ALTER SESSION SET container = CDB$ROOT;
--
-- anonymous pl/sql below is identical for cs_load_sysmetric_for_cdb_hist.sql and cs_load_sysmetric_for_pdb_hist.sql
--
SET SERVEROUT ON;
DECLARE
  l_begin_time DATE;
  l_end_time   DATE;
  --
  FUNCTION get_avg (p_metric_name IN VARCHAR2) RETURN NUMBER IS
    l_avg NUMBER;
  BEGIN
    SELECT AVG(CASE WHEN metric_unit = 'CentiSeconds Per Second' THEN average / 100 WHEN metric_unit IN ('Bytes Per Second', 'bytes per sec', 'bytes', 'Bytes Per Txn') THEN average / POWER(10, 6) ELSE average END) INTO l_avg FROM &&view_name. WHERE &&common_predicate. snap_id > TO_NUMBER('&&begin_snap_id.') AND snap_id <= TO_NUMBER('&&end_snap_id.') AND metric_name = p_metric_name; -- AVG returns NULL when NOT FOUND
    RETURN l_avg;
  END get_avg;
  --
  FUNCTION get_max (p_metric_name IN VARCHAR2) RETURN NUMBER IS
    l_max NUMBER;
  BEGIN
    SELECT MAX(CASE WHEN metric_unit = 'CentiSeconds Per Second' THEN maxval / 100 WHEN metric_unit IN ('Bytes Per Second', 'bytes per sec', 'bytes', 'Bytes Per Txn') THEN maxval / POWER(10, 6) ELSE maxval END) INTO l_max FROM &&view_name. WHERE &&common_predicate. snap_id > TO_NUMBER('&&begin_snap_id.') AND snap_id <= TO_NUMBER('&&end_snap_id.') AND metric_name = p_metric_name; -- MAX returns NULL when NOT FOUND
    RETURN l_max;
  END get_max;
  --
  PROCEDURE output (p_line IN VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.put_line(p_line);
  END output;
  --
  PROCEDURE output (p_title IN VARCHAR2, p_metric_name_per_sec IN VARCHAR2, p_metric_name_per_txn IN VARCHAR2) IS
  BEGIN
    output (
      '| '||
      LPAD(p_title, 25, ' ')||':'||
      LPAD(NVL(TRIM(TO_CHAR(get_avg(p_metric_name_per_sec), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_avg(p_metric_name_per_txn), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_max(p_metric_name_per_sec), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_max(p_metric_name_per_txn), '999,999,999,999,990.0')), '-'), 22, ' ')
    );
  END output;
  --
  PROCEDURE output (p_title IN VARCHAR2, p_metric_name IN VARCHAR2) IS
  BEGIN
    output (
      '| '||
      LPAD(p_title, 25, ' ')||':'||
      LPAD(NVL(TRIM(TO_CHAR(get_avg(p_metric_name), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_max(p_metric_name), '999,999,999,999,990.0')), '-'), 22, ' ')
    );
  END output;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') <> 'CDB$ROOT' AND LOWER('&&view_name.') = 'dba_hist_sysmetric_summary' THEN
    raise_application_error(-20000, 'Executed from '||SYS_CONTEXT('USERENV', 'CON_NAME')||' instead of CDB$ROOT');
  END IF;
  --
  output('/tmp/&&script_name._&&report_date_time..txt');
  output('+ ------------------------------------------------');
  output('|');
  output('|      Date: '||TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'));
  output('|      Host: '||SYS_CONTEXT('USERENV','HOST'));
  output('|  Database: &&cs_db.');
  output('| Container: '||SYS_CONTEXT('USERENV', 'CON_NAME'));
  SELECT MAX(CAST(end_interval_time AS DATE)) INTO l_begin_time FROM dba_hist_snapshot WHERE snap_id = TO_NUMBER('&&begin_snap_id.');
  SELECT MAX(CAST(end_interval_time AS DATE)) INTO l_end_time FROM dba_hist_snapshot WHERE snap_id = TO_NUMBER('&&end_snap_id.');
  output('|     Range: '||TO_CHAR(l_begin_time, 'YYYY-MM-DD"T"HH24:MI:SS')||' - '||TO_CHAR(l_end_time, 'YYYY-MM-DD"T"HH24:MI:SS'));
  output('|');
  output('| Load Profile (&&view_name.)');
  output('| ~~~~~~~~~~~~');
  output('|                                      Avg Per Sec           Avg Per Txn           Max Per Sec           Max Per Txn');
  output('|                            --------------------- --------------------- --------------------- ---------------------');
  output('DB Time(s)', 'Database Time Per Sec', NULL);
  output('DB CPU(s)', 'CPU Usage Per Sec', 'CPU Usage Per Txn');
  output('Background CPU(s)', 'Background CPU Usage Per Sec', NULL);
  output('Host CPU(s)', 'Host CPU Usage Per Sec', NULL);
  output('Redo size (MB)', 'Redo Generated Per Sec', 'Redo Generated Per Txn');
  output('Redo writes', 'Redo Writes Per Sec', 'Redo Writes Per Txn');
  output('DBWR checkpoints', 'DBWR Checkpoints Per Sec', NULL);
  output('Logical read (blocks)', 'Logical Reads Per Sec', 'Logical Reads Per Txn');
  output('Block gets', 'DB Block Gets Per Sec', 'DB Block Gets Per Txn');
  output('Consistent read gets', 'Consistent Read Gets Per Sec', 'Consistent Read Gets Per Txn');
  output('Block changes', 'DB Block Changes Per Sec', 'DB Block Changes Per Txn');
  output('Consistent read changes', 'Consistent Read Changes Per Sec', 'Consistent Read Changes Per Txn');
  output('CR blocks created', 'CR Blocks Created Per Sec', 'CR Blocks Created Per Txn');
  output('CR Undo records applied', 'CR Undo Records Applied Per Sec', 'CR Undo Records Applied Per Txn');
  output('IO (MB)', 'I/O Megabytes per Second', NULL);
  output('IO requests', 'I/O Requests per Second', NULL);
  output('Physical read (blocks)', 'Physical Reads Per Sec', 'Physical Reads Per Txn');
  output('Physical write (blocks)', 'Physical Writes Per Sec', 'Physical Writes Per Txn');
  output('Total read IO requests', 'Physical Read Total IO Requests Per Sec', NULL);
  output('Total write IO requests', 'Physical Write Total IO Requests Per Sec', NULL);
  output('Total read IO (MB)', 'Physical Read Total Bytes Per Sec', NULL);
  output('Total write IO (MB)', 'Physical Write Total Bytes Per Sec', NULL);
  output('Appl read IO requests', 'Physical Read IO Requests Per Sec', NULL);
  output('Appl write IO requests', 'Physical Write IO Requests Per Sec', NULL);
  output('Appl read IO (MB)', 'Physical Read Bytes Per Sec', NULL);
  output('Appl wite IO (MB)', 'Physical Write Bytes Per Sec', NULL);
  output('Total table scans', 'Total Table Scans Per Sec', 'Total Table Scans Per Txn');
  output('Long table scans', 'Long Table Scans Per Sec', 'Long Table Scans Per Txn');
  output('Total index scans', 'Total Index Scans Per Sec', 'Total Index Scans Per Txn');
  output('Full index scans', 'Full Index Scans Per Sec', 'Full Index Scans Per Txn');
  output('Leaf node splits', 'Leaf Node Splits Per Sec', 'Leaf Node Splits Per Txn');
  output('Network traffic (MB)', 'Network Traffic Volume Per Sec', NULL);
  output('User calls', 'User Calls Per Sec', 'User Calls Per Txn');
  output('Recursive calls', 'Recursive Calls Per Sec', 'Recursive Calls Per Txn');
  output('Parses (SQL)', 'Total Parse Count Per Sec', 'Total Parse Count Per Txn');
  output('Hard parses (SQL)', 'Hard Parse Count Per Sec', 'Hard Parse Count Per Txn');
  output('Failed parses (SQL)', 'Parse Failure Count Per Sec', 'Parse Failure Count Per Txn');
  output('Executes (SQL)', 'Executions Per Sec', 'Executions Per Txn');
  output('Logons', 'Logons Per Sec', 'Logons Per Txn');
  output('Open cursors', 'Open Cursors Per Sec', 'Open Cursors Per Txn');
  output('Transactions', 'User Transaction Per Sec', NULL);
  output('Commits', 'User Commits Per Sec', NULL);
  output('Rollbacks', 'User Rollbacks Per Sec', NULL);
  output('VM in (MB)', 'VM in bytes Per Sec', NULL);
  output('VM out (MB)', 'VM out bytes Per Sec', NULL);
  output('|');
  output('|                                              Avg                   Max');
  output('|                            --------------------- ---------------------');
  output('OS Load', 'Current OS Load');
  output('Logons Count', 'Current Logons Count');
  output('Session Count', 'Session Count');
  output('Average Active Sessions', 'Average Active Sessions');
  output('Active Serial Sessions', 'Active Serial Sessions');
  output('Active Parallel Sessions', 'Active Parallel Sessions');
  output('Background Sessions', 'Background Time Per Sec');
  output('Open Cursors Count', 'Current Open Cursors Count');
  output('Temp Space (MB)', 'Temp Space Used');
  output('PGA Allocated (MB)', 'Total PGA Allocated');
  output('PGA SQL Work Area (MB)', 'Total PGA Used by SQL Workareas');
  output('|');
  output('+ ------------------------------------------------');
  output('SQL> @&&script_name..sql "&&num_days." "&&begin_snap_id." "&&end_snap_id."');
END;
/
SPO OFF;
--
-- @@cs_internal/&&cs_set_container_to_curr_pdb.
ALTER SESSION SET CONTAINER = &&cs_con_name.;
--
PRO
PRO /tmp/&&script_name._&&report_date_time..txt
--