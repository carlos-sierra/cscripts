----------------------------------------------------------------------------------------
--
-- File name:   cs_load_sysmetric_per_pdb_hist.sql
--
-- Purpose:     System Load as per DBA_HIST_CON_SYSMETRIC_SUMM View per PDB (text report)
--
-- Author:      Carlos Sierra
--
-- Version:     2021/04/06
--
-- Usage:       Execute connected to CDB and pass range of AWR snapshots, then enter metric group [{avg}|max]
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @cs_load_sysmetric_per_pdb_hist.sql
--
-- Notes:       Stand-alone script
--
--              Developed and tested on 19c.
--
--              Several columns are commented out simply to reduce report width.
--
---------------------------------------------------------------------------------------
--
DEF script_name = 'cs_load_sysmetric_per_pdb_hist';
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
PRO
PRO Enter Metric Group: [{avg}|max]
DEF cs_metric_group = '&4.';
UNDEF 4;
COL cs_metric_group NEW_V cs_metric_group NOPRI;
SELECT CASE WHEN LOWER(TRIM('&&cs_metric_group.')) IN ('avg' ,'max') THEN LOWER(TRIM('&&cs_metric_group.')) ELSE 'avg' END AS cs_metric_group FROM DUAL;
COL cs_hea NEW_V cs_hea NOPRI;
SELECT CASE '&&cs_metric_group.' WHEN 'avg' THEN 'Avg' WHEN 'max' THEN 'Max' ELSE 'Error' END AS cs_hea FROM DUAL;
DEF cs_hea_ps = '&&cs_hea. Per Sec';
--
COL cs_begin_time NEW_V cs_begin_time NOPRI;
COL cs_end_time NEW_V cs_end_time NOPRI;
SELECT TO_CHAR(MAX(CAST(end_interval_time AS DATE)), 'YYYY-MM-DD"T"HH24:MI:SS') AS cs_begin_time FROM dba_hist_snapshot WHERE snap_id = TO_NUMBER('&&begin_snap_id.');
SELECT TO_CHAR(MAX(CAST(end_interval_time AS DATE)), 'YYYY-MM-DD"T"HH24:MI:SS') AS cs_end_time FROM dba_hist_snapshot WHERE snap_id = TO_NUMBER('&&end_snap_id.');
--
DEF cs_format = 'FOR 999,999,999,990.0';
COL pdb_name FOR A30 HEA 'PDB Name' TRUNC;
COL db_cpu &&cs_format. HEA 'DB CPU(s)|&&cs_hea_ps.';
COL redo_size &&cs_format. HEA 'Redo size|(MB)|&&cs_hea_ps.';
COL logical_reads &&cs_format. HEA 'Logical read|(blocks)|&&cs_hea_ps.';
COL block_changes &&cs_format. HEA 'Block changes|&&cs_hea_ps.';
COL physical_reads &&cs_format. HEA 'Physical read|(blocks)|&&cs_hea_ps.';
COL physical_writes &&cs_format. HEA 'Physical write|(blocks)|&&cs_hea_ps.';
COL total_read_io &&cs_format. HEA 'Total read IO|(MB)|&&cs_hea_ps.';
COL total_write_io &&cs_format. HEA 'Total write IO|(MB)|&&cs_hea_ps.';
COL appl_read_io &&cs_format. HEA 'Appl read IO|(MB)|&&cs_hea_ps.';
COL appl_write_io &&cs_format. HEA 'Appl wite IO|(MB)|&&cs_hea_ps.';
COL network_traffic &&cs_format. HEA 'Network traffic|(MB)|&&cs_hea_ps.';
COL user_calls &&cs_format. HEA 'User calls|&&cs_hea_ps.';
COL parses &&cs_format. HEA 'Parses|(SQL)|&&cs_hea_ps.';
COL hard_parses &&cs_format. HEA 'Hard parses|(SQL)|&&cs_hea_ps.';
COL failed_parses &&cs_format. HEA 'Failed parses|(SQL)|&&cs_hea_ps.';
COL executes &&cs_format. HEA 'Executes|(SQL)|&&cs_hea_ps.';
COL logons &&cs_format. HEA 'Logons|&&cs_hea_ps.';
COL open_cursors &&cs_format. HEA 'Open cursors|&&cs_hea_ps.';
COL transactions &&cs_format. HEA 'Transactions|&&cs_hea_ps.';
COL commits &&cs_format. HEA 'Commits|&&cs_hea_ps.';
COL rollbacks &&cs_format. HEA 'Rollbacks|&&cs_hea_ps.';
COL logons_count &&cs_format. HEA 'Logons|Count|&&cs_hea.';
COL session_count &&cs_format. HEA 'Session|Count|&&cs_hea.';
COL aas &&cs_format. HEA 'Average Active|Sessions|&&cs_hea.';
COL ass &&cs_format. HEA 'Active Serial|Sessions|&&cs_hea.';
COL aps &&cs_format. HEA 'Active Parallel|Sessions|&&cs_hea.';
COL bs &&cs_format. HEA 'Background|Sessions|&&cs_hea.';
COL open_cursors_count &&cs_format. HEA 'Open Cursors|Count|&&cs_hea.';
--
BREAK ON REPORT;
COMPUTE SUM OF db_cpu redo_size logical_reads block_changes physical_reads physical_writes total_read_io total_write_io appl_read_io appl_write_io network_traffic user_calls parses hard_parses failed_parses executes logons open_cursors transactions commits rollbacks logons_count session_count aas ass aps bs open_cursors_count ON REPORT;
--
ALTER SESSION SET container = CDB$ROOT;
--
SPO /tmp/&&script_name._&&report_date_time..txt
PRO /tmp/&&script_name._&&report_date_time..txt
PRO
PRO Date     : &&cs_date.
PRO Host     : &&cs_host.
PRO Database : &&cs_db.
PRO Container: &&cs_con.
PRO Metric   : &&cs_hea. : &&cs_begin_time. - &&cs_end_time.
PRO
PRO Load Profile (dba_hist_con_sysmetric_summ)
PRO ~~~~~~~~~~~~
WITH 
sysmetric_norm AS (
SELECT /*+ MATERIALIZE NO_MERGE OPT_PARAM('_px_cdb_view_enabled' 'FALSE') */
       con_id,
       metric_name,
       AVG(CASE WHEN metric_unit = 'CentiSeconds Per Second' THEN average / 100 WHEN metric_unit IN ('Bytes Per Second', 'bytes per sec', 'bytes', 'Bytes Per Txn') THEN average / POWER(10, 6) ELSE average END) AS value_avg,
       MAX(CASE WHEN metric_unit = 'CentiSeconds Per Second' THEN maxval / 100 WHEN metric_unit IN ('Bytes Per Second', 'bytes per sec', 'bytes', 'Bytes Per Txn') THEN maxval / POWER(10, 6) ELSE maxval END) AS value_max
  FROM dba_hist_con_sysmetric_summ
 WHERE group_id = 18
   AND snap_id > TO_NUMBER('&&begin_snap_id.') AND snap_id <= TO_NUMBER('&&end_snap_id.')
 GROUP BY
       con_id,
       metric_name
)
SELECT /*+ MATERIALIZE NO_MERGE */
         c.name  AS pdb_name
       , SUM(CASE s.metric_name WHEN 'CPU Usage Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS db_cpu
       , SUM(CASE s.metric_name WHEN 'Redo Generated Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS redo_size
       , SUM(CASE s.metric_name WHEN 'Logical Reads Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS logical_reads
      --  , SUM(CASE s.metric_name WHEN 'DB Block Changes Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS block_changes
       , SUM(CASE s.metric_name WHEN 'Physical Reads Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS physical_reads
       , SUM(CASE s.metric_name WHEN 'Physical Writes Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS physical_writes
      --  , SUM(CASE s.metric_name WHEN 'Physical Read Total Bytes Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS total_read_io
      --  , SUM(CASE s.metric_name WHEN 'Physical Write Total Bytes Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS total_write_io
      --  , SUM(CASE s.metric_name WHEN 'Physical Read Bytes Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS appl_read_io
      --  , SUM(CASE s.metric_name WHEN 'Physical Write Bytes Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS appl_write_io
       , SUM(CASE s.metric_name WHEN 'Network Traffic Volume Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS network_traffic
       , SUM(CASE s.metric_name WHEN 'User Calls Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS user_calls
      --  , SUM(CASE s.metric_name WHEN 'Total Parse Count Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS parses
      --  , SUM(CASE s.metric_name WHEN 'Hard Parse Count Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS hard_parses
      --  , SUM(CASE s.metric_name WHEN 'Parse Failure Count Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS failed_parses
       , SUM(CASE s.metric_name WHEN 'Executions Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS executes
       , SUM(CASE s.metric_name WHEN 'Logons Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS logons
      --  , SUM(CASE s.metric_name WHEN 'Open Cursors Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS open_cursors
       , SUM(CASE s.metric_name WHEN 'User Transaction Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS transactions
       , SUM(CASE s.metric_name WHEN 'User Commits Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS commits
      --  , SUM(CASE s.metric_name WHEN 'User Rollbacks Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS rollbacks
      --  , SUM(CASE s.metric_name WHEN 'Current Logons Count' THEN s.value_&&cs_metric_group. ELSE 0 END) AS logons_count
       , SUM(CASE s.metric_name WHEN 'Session Count' THEN s.value_&&cs_metric_group. ELSE 0 END) AS session_count
       , SUM(CASE s.metric_name WHEN 'Average Active Sessions' THEN s.value_&&cs_metric_group. ELSE 0 END) AS aas
      --  , SUM(CASE s.metric_name WHEN 'Active Serial Sessions' THEN s.value_&&cs_metric_group. ELSE 0 END) AS ass
       , SUM(CASE s.metric_name WHEN 'Active Parallel Sessions' THEN s.value_&&cs_metric_group. ELSE 0 END) AS aps
      --  , SUM(CASE s.metric_name WHEN 'Background Time Per Sec' THEN s.value_&&cs_metric_group. ELSE 0 END) AS bs
      --  , SUM(CASE s.metric_name WHEN 'Current Open Cursors Count' THEN s.value_&&cs_metric_group. ELSE 0 END) AS open_cursors_count
  FROM sysmetric_norm s,
       v$containers c
 WHERE c.con_id = s.con_id
 GROUP BY
       c.name
 ORDER BY
       c.name
/
PRO
PRO SQL> @&&script_name..sql "&&num_days." "&&begin_snap_id." "&&end_snap_id." "&&cs_metric_group."
SPO OFF;
--
ALTER SESSION SET CONTAINER = &&cs_con.;
--
PRO
PRO /tmp/&&script_name._&&report_date_time..txt
--