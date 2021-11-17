----------------------------------------------------------------------------------------
--
-- File name:   cs_all_sysmetric_for_pdb_hist.sql
--
-- Purpose:     All System Metrics as per DBA_HIST_CON_SYSMETRIC_SUMM View for a PDB (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/04/06
--
-- Usage:       Execute connected to CDB and pass range of AWR snapshots.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_all_sysmetric_for_pdb_hist.sql
--
-- Notes:       Stand-alone script
--
--              Developed and tested on 19c.
--
---------------------------------------------------------------------------------------
--
DEF view_name = 'dba_hist_con_sysmetric_summ';
DEF common_predicate = "con_id = SYS_CONTEXT('USERENV', 'CON_ID') AND";
DEF script_name = 'cs_all_sysmetric_for_pdb_hist';
--
COL cs_date NEW_V cs_date NOPRI;
COL cs_host NEW_V cs_host NOPRI;
COL cs_db NEW_V cs_db NOPRI;
COL cs_con NEW_V cs_con NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS') AS cs_date, SYS_CONTEXT('USERENV','HOST') AS cs_host, UPPER(name) AS cs_db, SYS_CONTEXT('USERENV', 'CON_NAME') AS cs_con FROM v$database;
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
COL cs_begin_time NEW_V cs_begin_time NOPRI;
COL cs_end_time NEW_V cs_end_time NOPRI;
COL cs_seconds NEW_V cs_seconds NOPRI;
SELECT TO_CHAR(MAX(CAST(end_interval_time AS DATE)), 'YYYY-MM-DD"T"HH24:MI:SS') AS cs_begin_time FROM dba_hist_snapshot WHERE snap_id = TO_NUMBER('&&begin_snap_id.');
SELECT TO_CHAR(MAX(CAST(end_interval_time AS DATE)), 'YYYY-MM-DD"T"HH24:MI:SS') AS cs_end_time FROM dba_hist_snapshot WHERE snap_id = TO_NUMBER('&&end_snap_id.');
SELECT TRIM(TO_CHAR(intsize/100, '999,999,990.00')) AS cs_seconds FROM &&view_name. WHERE snap_id > TO_NUMBER('&&begin_snap_id.') AND snap_id <= TO_NUMBER('&&end_snap_id.') AND ROWNUM = 1;
--
SET TERM ON HEA ON LIN 2490 PAGES 100 TAB OFF FEED OFF ECHO OFF VER OFF TRIMS ON TRIM ON TI OFF TIMI OFF LONG 240000 LONGC 2400 NUM 20 SERVEROUT OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS';
COL report_date_time NEW_V report_date_time NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24.MI.SS"Z"') AS report_date_time FROM DUAL;
SPO /tmp/&&script_name._&&report_date_time..txt
PRO /tmp/&&script_name._&&report_date_time..txt
PRO
PRO Date     : &&cs_date.
PRO Host     : &&cs_host.
PRO Database : &&cs_db.
PRO Container: &&cs_con.
PRO Range    : &&cs_begin_time. - &&cs_end_time. (&&cs_seconds. seconds)
--
COL metric_name FOR A45 TRUN;
COL metric_unit FOR A41 TRUN;
COL seconds FOR 9,900.00;
--
PRO
PRO System Metrics by Name (&&view_name.)
PRO ~~~~~~~~~~~~~~~~~~~~~~
SELECT metric_name,
       AVG(average) AS average,
       MAX(maxval) AS maxval,
       metric_unit
  FROM &&view_name.
 WHERE &&common_predicate. snap_id > TO_NUMBER('&&begin_snap_id.') AND snap_id <= TO_NUMBER('&&end_snap_id.')
 GROUP BY
       metric_name, metric_unit
 ORDER BY
       metric_name, metric_unit
/
PRO
PRO System Metrics by Unit and Name (&&view_name.)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT metric_unit,
       metric_name,
       AVG(average) AS average,
       MAX(maxval) AS maxval
  FROM &&view_name.
 WHERE &&common_predicate. snap_id > TO_NUMBER('&&begin_snap_id.') AND snap_id <= TO_NUMBER('&&end_snap_id.')
 GROUP BY
       metric_unit, metric_name
 ORDER BY
       metric_unit, metric_name
/
--
PRO
PRO SQL> @&&script_name..sql 
SPO OFF;
PRO
PRO /tmp/&&script_name._&&report_date_time..txt
--