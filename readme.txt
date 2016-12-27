Carlos Sierra's Shared Scripts 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
last update: 2016/12/18

Feel free to use these scripts. They are mostly useful in the scope of SQL performance
diagnostics. Keep original names please.

Script Name                 YY/MM/DD Purpose
~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
act.sql                     14/10/13 Active Sessions (lite)
active_sessions.sql         14/10/31 Active Sessions (more columns)
active_sql.sql              14/10/31 Simple list of Active SQL (just sql id and text)
alter_plans.sql             13/12/28 Alter attributes of a SQL Plan Baseline
awr_ash_pre_check.sql       16/12/18 Analyzes state of ASH on AWR and computes how long eDB360 would take to execute
chained_rows.sql            16/04/18 Chained rows analysis for one table
columns_multiple_types.sql  15/07/07 List Columns with multiple data types
constraints_nonindexed.sql  15/07/05 List FK Constrains with no index to supportthem
data_files_usage.sql        14/02/12 Reports Datafiles and Tablespaces usage
dba_hist_ash_summaries.sql  13/12/19 ASH summaries by timed events then by plan operation
display.sql                 16/06/22 Display explain plan for most recent EXPLAIN PLAN FOR
display_cursor.sql          16/06/22 Display execution plan for most recent cursor executed on current session
estimate_index_size.sql     16/03/22 Reports Indexes with an Actual size > Estimated size for over 1 MB
evolve.sql                  13/12/18 Evolve SQL Plan Baselines
execution_plan_v.sql        16/06/21 Creates a view displaying execution plan for most recent cursor
explain_plan_v.sql          16/06/21 Creates a view displaying explain plan for most recent EXPLAIN PLAN FOR
find_apex.sql               14/09/03 Finds APEX related expensive SQL for given application user and session
gather_stats_wr_sys.sql     15/10/15 Gather fresh CBO statistics for AWR Tables and Indexes
get_my_trace1.sql           16/06/24 Copy trace file on DB server from trace directory into local
get_my_trace2.sql           16/06/24 Copy trace file from DB server into local directory using all_directories
identification.sql          16/05/27 System identification with global info such as versions
largest_200_objects.sql     14/01/23 Reports 200 largest objects as per segments bytes
line_chart.sql              16/08/19 Sample script to generate a Google line chart
list_plans.sql              13/12/28 Lists SQL Plan Baselines
mon subdirectory            16/02/29 A set of scripts to monitor executions taking over X time
mystat_reset.sql            13/10/04 Resets snaps credated by mystat.sql
mystat.sql                  14/01/11 Reports delta of current sessions stats before and after a SQL
one_sql_time_series.sql     14/10/31 Performance History for one SQL
planx.sql                   16/11/18 Gets execution plan for given SQL_ID
plan_prev.sql               16/08/29 Execution Plan for last SQL executed in current session
prev.sql                    16/06/21 Most recent SQL_ID and CHILD_NUMBER for current SID
profiler.sql                15/12/28 Generates HTML report out of DBMS_PROFILER data
recent.sql                  15/07/09 List of SQL on execution or recently executed
planx.sql                   16/07/14 Reports Execution Plans for one SQL_ID from RAC and AWR(opt)
sql_perf_change_by_date.sql 14/11/28 Lists SQL Statements with Elapsed Time per Execution changing over time (passing date)
sql_performance_changed.sql 14/11/28 Lists SQL Statements with Elapsed Time per Execution changing over time
sql_with_multiple_plans.sql 14/11/28 Lists SQL Statements with multiple Execution Plans performing significantly different
sqlash.sql                  13/12/18 ASH Reports for one SQL_ID
spm subdirectory            16/02/29 Several scripts to manage SQL Plan Baselines
sqlmon.sql                  16/04/19 SQL Monitor Reports for one SQL_ID
sqlpch.sql                  15/01/28 Create Diagnostics SQL Patch for one SQL_ID
spm directory               16/01/01 SQL Plan Management scripts
tablex.sql                  14/01/24 Reports CBO Statistics for a given Table
tkprof.sql                  13/10/15 Turns trace off and generates a TKPROF for trace under current session
trace_off.sql               16/06/19 Turns sql trace off
trace_on.sql                16/06/19 Turns sql trace on using event 10046 level 12 (include binds and waits)
verify_stats_wr_sys.sql     16/11/23 Verify CBO statistics for AWR Tables and Indexes
