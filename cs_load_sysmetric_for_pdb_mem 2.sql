----------------------------------------------------------------------------------------
--
-- File name:   cs_load_sysmetric_for_pdb_mem.sql
--
-- Purpose:     System Load as per V$CON_SYSMETRIC Views for a PDB (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/08/09
--
-- Usage:       Execute connected to PDB.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_load_sysmetric_for_pdb_mem.sql
--
-- Notes:       Stand-alone script
--
--              Developed and tested on 19c.
--
---------------------------------------------------------------------------------------
--
DEF view_name_prefix = 'v$con_sysmetric';
DEF common_predicate = "con_id = SYS_CONTEXT('USERENV', 'CON_ID') AND ";
DEF script_name = 'cs_load_sysmetric_for_pdb_mem';
--
COL cs_date NEW_V cs_date NOPRI;
COL cs_host NEW_V cs_host NOPRI;
COL cs_db NEW_V cs_db NOPRI;
COL cs_con NEW_V cs_con NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS') AS cs_date, SYS_CONTEXT('USERENV','HOST') AS cs_host, UPPER(name) AS cs_db, SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con FROM v$database;
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
COL report_date_time NEW_V report_date_time NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24.MI.SS"Z"') AS report_date_time FROM DUAL;
SPO /tmp/&&script_name._&&report_date_time..txt
--
-- anonymous pl/sql below is identical for cs_load_sysmetric_for_cdb_mem.sql and cs_load_sysmetric_for_pdb_mem.sql
--
SET SERVEROUT ON;
DECLARE
  l_begin_time DATE;
  l_end_time   DATE;
  --
  FUNCTION get_15s_avg (p_metric_name IN VARCHAR2) RETURN NUMBER IS
    l_avg NUMBER;
  BEGIN
    SELECT MAX(CASE WHEN metric_unit = 'CentiSeconds Per Second' THEN value / 100 WHEN metric_unit IN ('Bytes Per Second', 'bytes per sec', 'bytes', 'Bytes Per Txn') THEN value / POWER(10, 6) ELSE value END) INTO l_avg FROM &&view_name_prefix. WHERE &&common_predicate. group_id = 3 AND metric_name = p_metric_name; -- MAX returns NULL when NOT FOUND
    RETURN l_avg;
  END get_15s_avg;
  --
  FUNCTION get_1m_avg (p_metric_name IN VARCHAR2) RETURN NUMBER IS
    l_avg NUMBER;
  BEGIN
    SELECT MAX(CASE WHEN metric_unit = 'CentiSeconds Per Second' THEN value / 100 WHEN metric_unit IN ('Bytes Per Second', 'bytes per sec', 'bytes', 'Bytes Per Txn') THEN value / POWER(10, 6) ELSE value END) INTO l_avg FROM &&view_name_prefix. WHERE &&common_predicate. group_id IN (2, 18) AND metric_name = p_metric_name; -- MAX returns NULL when NOT FOUND
    RETURN l_avg;
  END get_1m_avg;
  --
  FUNCTION get_1h_avg (p_metric_name IN VARCHAR2) RETURN NUMBER IS
    l_avg NUMBER;
  BEGIN
    SELECT MAX(CASE WHEN metric_unit = 'CentiSeconds Per Second' THEN average / 100 WHEN metric_unit IN ('Bytes Per Second', 'bytes per sec', 'bytes', 'Bytes Per Txn') THEN average / POWER(10, 6) ELSE average END) INTO l_avg FROM &&view_name_prefix._summary WHERE &&common_predicate. group_id IN (2, 18) AND metric_name = p_metric_name; -- MAX returns NULL when NOT FOUND
    RETURN l_avg;
  END get_1h_avg;
  --
  FUNCTION get_1h_max (p_metric_name IN VARCHAR2) RETURN NUMBER IS
    l_max NUMBER;
  BEGIN
    SELECT MAX(CASE WHEN metric_unit = 'CentiSeconds Per Second' THEN maxval / 100 WHEN metric_unit IN ('Bytes Per Second', 'bytes per sec', 'bytes', 'Bytes Per Txn') THEN maxval / POWER(10, 6) ELSE maxval END) INTO l_max FROM &&view_name_prefix._summary WHERE &&common_predicate. group_id IN (2, 18) AND metric_name = p_metric_name; -- MAX returns NULL when NOT FOUND
    RETURN l_max;
  END get_1h_max;
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
      LPAD(NVL(TRIM(TO_CHAR(get_15s_avg(p_metric_name_per_sec), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_15s_avg(p_metric_name_per_txn), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_1m_avg(p_metric_name_per_sec), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_1m_avg(p_metric_name_per_txn), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_1h_avg(p_metric_name_per_sec), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_1h_avg(p_metric_name_per_txn), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_1h_max(p_metric_name_per_sec), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_1h_max(p_metric_name_per_txn), '999,999,999,999,990.0')), '-'), 22, ' ')
    );
  END output;
  --
  PROCEDURE output (p_title IN VARCHAR2, p_metric_name IN VARCHAR2) IS
  BEGIN
    output (
      '| '||
      LPAD(p_title, 25, ' ')||':'||
      LPAD(NVL(TRIM(TO_CHAR(get_15s_avg(p_metric_name), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_1m_avg(p_metric_name), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_1h_avg(p_metric_name), '999,999,999,999,990.0')), '-'), 22, ' ')||
      LPAD(NVL(TRIM(TO_CHAR(get_1h_max(p_metric_name), '999,999,999,999,990.0')), '-'), 22, ' ')
    );
  END output;
BEGIN
  IF SYS_CONTEXT('USERENV', 'CON_NAME') <> 'CDB$ROOT' AND LOWER('&&view_name_prefix.') = 'v$sysmetric' THEN
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
  SELECT MAX(begin_time), MAX(end_time) INTO l_begin_time, l_end_time FROM &&view_name_prefix. WHERE group_id = 3 AND ROWNUM = 1; -- MAX returns NULL when NOT FOUND
  output('|       15s: '||TO_CHAR(l_begin_time, 'YYYY-MM-DD"T"HH24:MI:SS')||' - '||TO_CHAR(l_end_time, 'YYYY-MM-DD"T"HH24:MI:SS'));
  SELECT MAX(begin_time), MAX(end_time) INTO l_begin_time, l_end_time FROM &&view_name_prefix. WHERE group_id IN (2, 18) AND ROWNUM = 1; -- MAX returns NULL when NOT FOUND
  output('|        1m: '||TO_CHAR(l_begin_time, 'YYYY-MM-DD"T"HH24:MI:SS')||' - '||TO_CHAR(l_end_time, 'YYYY-MM-DD"T"HH24:MI:SS'));
  SELECT MAX(begin_time), MAX(end_time) INTO l_begin_time, l_end_time FROM &&view_name_prefix._summary WHERE group_id IN (2, 18) AND ROWNUM = 1; -- MAX returns NULL when NOT FOUND
  output('|        1h: '||TO_CHAR(l_begin_time, 'YYYY-MM-DD"T"HH24:MI:SS')||' - '||TO_CHAR(l_end_time, 'YYYY-MM-DD"T"HH24:MI:SS'));
  output('|');
  output('| Load Profile (&&view_name_prefix. and &&view_name_prefix._summary)');
  output('| ~~~~~~~~~~~~');
  output('|                                  15s Avg Per Sec       15s Avg Per Txn        1m Avg Per Sec        1m Avg Per Txn        1h Avg Per Sec        1h Avg Per Txn        1h Max Per Sec        1h Max Per Txn');
  output('|                            --------------------- --------------------- --------------------- --------------------- --------------------- --------------------- --------------------- ---------------------');
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
  output('|                                          15s Avg                1m Avg                1h Avg                1h Max');
  output('|                            --------------------- --------------------- --------------------- ---------------------');
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
  output('SQL> @&&script_name..sql');
END;
/
SPO OFF;
PRO
PRO /tmp/&&script_name._&&report_date_time..txt
--