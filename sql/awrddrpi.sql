Rem
Rem $Header: rdbms/admin/awrddrpi.sql /main/5 2011/05/12 23:28:37 shiyadav Exp $
Rem
Rem awrddrpi.sql
Rem
Rem Copyright (c) 2004, 2011, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      awrddrpi.sql - Workload Repository Compare Periods Report
Rem
Rem    DESCRIPTION
Rem      SQL*Plus command file to report on differences between differences
Rem      between values recorded in two pairs of snapshots.
Rem
Rem      This script requests the user for the dbid and instance number
Rem      of the instance to report on, for each snapshot pair, 
Rem      before producing the standard Workload Repository report.
Rem
Rem    NOTES
Rem      Run as SYSDBA.  Generally this script should be invoked by awrddrpt,
Rem      unless you want to pick a database/instance other than the default.
Rem
Rem      If you want to use this script in an non-interactive fashion,
Rem      without executing the script through awrrpt, then
Rem      do something similar to the following:
Rem
Rem      define  inst_num     = 1;
Rem      define  num_days     = 3;
Rem      define  inst_name    = 'Instance';
Rem      define  db_name      = 'Database';
Rem      define  dbid         = 4;
Rem      define  begin_snap   = 10;
Rem      define  end_snap     = 11;
Rem      define  report_type  = 'text';
Rem      define  report_name  = /tmp/swrf_report_10_11.txt
Rem      @@?/rdbms/admin/awrrpti
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    shiyadav    04/25/10 - change linesize to 8000 for html report
Rem    ilistvin    05/08/09 - change linesize to 320 for text report
Rem    ysarig      05/27/05 - Fix comments for compare period report 
Rem    pbelknap    08/04/04 - make awr html types bigger 
Rem    pbelknap    07/23/04 - change linesize to 240 
Rem    mramache    06/17/04 - mramache_diff_diff
Rem    mramache    05/25/04 - 
Rem    ilistvin    05/25/04 - created
Rem

set echo off;

-- ***************************************************
--   Customer-customizable report settings
--   Change these variables to run a report on different statistics
-- ***************************************************
-- The default number of days of snapshots to list when displaying the
-- list of snapshots to choose the begin and end snapshot Ids from.
--
--   List all snapshots
-- define num_days = '';
--
--   List no (i.e. 0) snapshots
-- define num_days = 0;
--
-- List past 3 day's snapshots
-- define num_days = 3;
--
-- Reports can be printed in text or html, and you must set the report_type
-- in addition to the report_name
--
-- Issue Report in Text Format
--define report_type='text';
--
-- Issue Report in HTML Format
--define report_type='html';

-- Optionally, set the snapshots for the report.  If you do not set them,
-- you will be prompted for the values.
--define begin_snap = 545;
--define end_snap   = 546;
--define begin_snap2 = 873;
--define end_snap2   = 874;

-- Optionally, set the name for the report itself
--define report_name = 'awrrpt_1_545_546.html'

-- ***************************************************
--   End customer-customizable settings
-- ***************************************************


-- *******************************************************
--  The report_options variable will be the options for
--  the AWR report.
--
--  Currently, only one option is available.
--
--  NO_OPTIONS -
--    No options. Setting this will not show the ADDM
--    specific portions of the report.
--    This is the default setting.
--
--  ENABLE_ADDM -
--    Show the ADDM specific portions of the report.
--    These sections include the Buffer Pool Advice,
--    Shared Pool Advice, PGA Target Advice, and
--    Wait Class sections.
--

set veri off;
set feedback off;

variable rpt_options number;

-- option settings
define NO_OPTIONS   = 0;
define ENABLE_ADDM  = 8;

-- set the report_options. To see the ADDM sections,
-- set the rpt_options to the ENABLE_ADDM constant.
begin
  :rpt_options := &NO_OPTIONS;
end;
/

--
-- Find out if we are going to print report to html or to text
prompt
prompt Specify the Report Type
prompt ~~~~~~~~~~~~~~~~~~~~~~~
prompt Would you like an HTML report, or a plain text report?
prompt Enter 'html' for an HTML report, or 'text' for plain text
prompt  Defaults to 'html'

column report_type new_value report_type;
set heading off;
select 'Type Specified: ',lower(nvl('&&report_type','html')) report_type from dual;
set heading on;

set termout off;
-- Set the extension based on the report_type
column ext new_value ext;
select '.html' ext from dual where lower('&&report_type') <> 'text';
select '.txt' ext from dual where lower('&&report_type') = 'text';
set termout on;

-- Get the common input!
-- awrinput will set up the bind variables we need to call the PL/SQL procedure
@@awrddinp.sql 'awrdiff_' &&ext

set termout off;
-- set report function name and line size
column fn_name new_value fn_name noprint;
select 'awr_diff_report_text' fn_name from dual where lower('&report_type') = 'text';
select 'awr_diff_report_html' fn_name from dual where lower('&report_type') <> 'text';

column lnsz new_value lnsz noprint;
select '320' lnsz from dual where lower('&report_type') = 'text';
select '8000' lnsz from dual where lower('&report_type') <> 'text';

set linesize &lnsz;
set termout on;
spool &report_name;
prompt

select 'WARNING: timed_statistics setting changed between begin/end snaps: TIMINGS ARE INVALID'
  from dual
 where not exists
      (select null
         from dba_hist_parameter b
            , dba_hist_parameter e
        where b.snap_id         = :bid
          and e.snap_id         = :eid
          and b.dbid            = :dbid
          and e.dbid            = :dbid
          and b.instance_number = :inst_num
          and e.instance_number = :inst_num
          and b.parameter_hash  = e.parameter_hash
          and b.parameter_name = 'timed_statistics'
          and b.value           = e.value)
 or not exists
      (select null
         from dba_hist_parameter b
            , dba_hist_parameter e
        where b.snap_id         = :bid2
          and e.snap_id         = :eid2
          and b.dbid            = :dbid2
          and e.dbid            = :dbid2
          and b.instance_number = :inst_num2
          and e.instance_number = :inst_num2
          and b.parameter_hash  = e.parameter_hash
          and b.parameter_name = 'timed_statistics'
          and b.value           = e.value);

select output from table(dbms_workload_repository.&fn_name( :dbid,
                                                            :inst_num,
                                                            :bid, :eid,
                                                            :dbid2,
                                                            :inst_num2,
                                                            :bid2, :eid2
                                                           ));

spool off;

prompt Report written to &report_name.

set termout off;
clear columns sql;
ttitle off;
btitle off;
repfooter off;
set linesize 78 termout on feedback 6 heading on;
-- Undefine report name (created in awrinput.sql)
undefine report_name

undefine report_type
undefine ext
undefine fn_name
undefine lnsz

undefine NO_OPTIONS
undefine ENABLE_ADDM

undefine top_n_events
undefine num_days
undefine top_n_sql
undefine top_pct_sql
undefine sh_mem_threshold
undefine top_n_segstat

whenever sqlerror continue;
--
--  End of script file;
