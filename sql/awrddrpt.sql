Rem
Rem $Header: awrddrpt.sql 27-may-2005.10:42:41 ysarig Exp $
Rem
Rem awrddrpt.sql
Rem
Rem Copyright (c) 2004, 2005, Oracle. All rights reserved.  
Rem
Rem    NAME
Rem      awrddrpt.sql
Rem
Rem    DESCRIPTION
Rem      This script defaults the dbid and instance number to that of the
Rem      current instance connected-to, then calls awrddrpi.sql to produce
Rem      the Workload Repository Compare Periods report.
Rem
Rem    NOTES
Rem      Run as select_catalog privileges.  
Rem      This report is based on the Statspack report.
Rem
Rem      If you want to use this script in an non-interactive fashion,
Rem      see the 'customer-customizable report settings' section in
Rem      awrrpti.sql
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    ysarig      05/27/05 - Fix comments for compare period report 
Rem    mramache    06/17/04 - mramache_diff_diff
Rem    mramache    06/01/04 - rename awrddrpti to awrddrpi 
Rem    ilistvin    05/25/04 - Created
Rem

--
-- Get the current database/instance information - this will be used 
-- later in the report along with bid, eid to lookup snapshots

set echo off heading on underline on;
column inst_num  heading "Inst Num"  new_value inst_num  format 99999;
column inst_num2 heading "Inst Num"  new_value inst_num2 format 99999;
column inst_name heading "Instance"  new_value inst_name format a12;
column db_name   heading "DB Name"   new_value db_name   format a12;
column dbid      heading "DB Id"     new_value dbid      format 9999999999 just c;
column dbid2     heading "DB Id"     new_value dbid2     format 9999999999 just c;

prompt
prompt Current Instance
prompt ~~~~~~~~~~~~~~~~

select d.dbid            dbid
     , d.dbid            dbid2
     , d.name            db_name
     , i.instance_number inst_num
     , i.instance_number inst_num2
     , i.instance_name   inst_name
  from v$database d,
       v$instance i;

@@awrddrpi

undefine num_days;
undefine report_type;
undefine report_name;
undefine begin_snap;
undefine end_snap;
--
-- End of file
