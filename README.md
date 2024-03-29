CS Scripts Inventory by Type (2023-07-29)
============================
* Latency
* Load
* SQL Performance
* SPBL - SQL Plan Baselines
* SPRF - SQL Profiles
* SPCH - SQL Patches
* Sessions
* Kill Sessions
* Blocked Sessions
* Locks
* Space Reporting
* Space Maintenance
* Container
* System Metrics
* System Stats and Events
* Configuration
* Logs
* Traces
* Reports
* Miscellaneous Utilities

Latency
-------
* la.sql | l.sql | cs_latency.sql                               - Current SQL latency (elapsed time over executions)
* le.sql | cs_latency_extended.sql                              - Current SQL latency (elapsed time over executions) - Extended
* lr.sql | cs_latency_range.sql                                 - SQL latency for a time range (elapsed time over executions) (AWR) - 15m Granularity 
* lre.sql | cs_latency_range_extended.sql                       - SQL latency for a time range (elapsed time over executions) (AWR) - 15m Granularity - Extended
* cs_latency_1m.sql                                             - Last 1m SQL latency (elapsed time over executions)
* cs_latency_1m_extended.sql                                    - Last 1m SQL latency (elapsed time over executions) - Extended
* cs_latency_snapshot.sql                                       - Snapshot SQL latency (elapsed time over executions)
* cs_latency_snapshot_extended.sql                              - Snapshot SQL latency (elapsed time over executions) - Extended
* lah.sql | lh.sql | cs_latency_hist.sql                        - Current and Historical SQL latency (cpu time over executions)
* cs_sql_latency_histogram.sql                                  - SQL Latency Histogram (elapsed time over executions)
* cs_sql_perf_long_executions.sql                               - SQL Executions longer than N seconds
* cs_dg_redo_dest_resp_histogram_chart.sql                      - Data Guard (DG) REDO Transport Duration Chart
* cs_dg_redo_dest_resp_histogram_report.sql                     - Data Guard (DG) REDO Transport Duration Report
* cs_LGWR_chart.sql                                             - Log Writer LGWR Slow Writes Duration Chart - from current LGWR trace
* cs_LGWR_report.sql                                            - Log Writer LGWR Slow Writes Duration Report - from current LGWR trace

Load
----
* ta.sql | t.sql | cs_top.sql                                   - Top Active SQL as per Active Sessions History ASH - last 1m
* tr.sql | cs_top_range.sql                                     - Top Active SQL as per Active Sessions History ASH - time range
* aa.sql | cs_ash_analytics.sql                                 - Poor-man's version of ASH Analytics for all Timed Events (Average Active Sessions AAS)
* ma.sql | cs_max_ash_analytics.sql                             - Poor-man's version of ASH Analytics for all Timed Events (Maximum Active Sessions)
* cpu.sql | cs_cpu_demand.sql                                   - Poor-man's version of ASH Analytics for CPU Demand (ON CPU + Scheduler)
* aas.sql | cs_average_active_sessions.sql                      - Average Active Sessions (ASH Analytics on dbc_active_session)
* mas.sql | cs_maximum_active_sessions.sql                      - Maximum Active Sessions (ASH Analytics on dbc_active_session)
* cs_osstat_chart.sql                                           - OS Stats from AWR (time series chart)
* cs_osstat_cpu_util_perc_chart.sql                             - CPU Utilization Percent Chart (AWR) - 15m Granularity
* cs_osstat_cpu_util_perc_now.sql                               - CPU Utilization Percent - Now
* cs_osstat_cpu_report.sql                                      - CPU Cores Load and Busyness as per OS Stats from AWR (time series report)
* cs_osstat_cpu_load_chart.sql                                  - CPU Cores Load as per OS Stats from AWR (time series chart)
* cs_osstat_cpu_busy_chart.sql                                  - CPU Cores Busyness as per OS Stats from AWR (time series chart)
* cs_top_pdb_chart.sql                                          - Top PDBs as per use of CPU Cores, Disk Space or Sessions (time series chart)
* cs_top_pdb_tps_chart.sql                                      - Top PDBs as per TPS (time series chart)
* cs_timed_event_top_consumers_pie.sql                          - Top contributors of a given Wait Class or Event (pie chart)
* cs_timed_event_top_consumers_report.sql                       - Top contributors of a given Wait Class or Event (text report)

SQL Performance
---------------
* p.sql | cs_sqlperf.sql                                        - Basic SQL performance metrics for a given SQL_ID
* pp.sql | cs_sqlperf_plus.sql                                  - Basic SQL performance metrics for a given SQL_ID + Top Keys
* x.sql | cs_planx.sql                                          - Execution Plans and SQL performance metrics for a given SQL_ID
* ssa.sql | cs_sqlstat_analytics.sql                            - SQL Statistics Analytics (AWR) - 15m Granularity
* ssaa.sql | cs_sqlstat_analytics_aggregate.sql                 - SQL Statistics Analytics Aggregate (AWR) - 15m Granularity
* ssr.sql | cs_sqlstat_report.sql                               - SQL Statistics Report (AWR) - detailed(15m), hourly, daily, global
* pm.sql | cs_planm.sql                                         - Execution Plans in Memory for a given SQL_ID
* ph.sql | cs_planh.sql                                         - Execution Plans in AWR for a given SQL_ID
* dc.sql                                                        - Display Cursor Execution Plan. Execute this script after one SQL for which you want to see the Execution Plan
* dp.sql                                                        - Display Plan Table Explain Plan. Execute this script after one EXPLAIN PLAN FOR for a SQL for which you want to see the Explain Plan
* cs_sqltext.sql                                                - SQL Text for a given SQL_ID
* cs_sqlmon_hist.sql                                            - SQL Monitor Report for a given SQL_ID (from AWR)
* cs_sqlmon_mem.sql                                             - SQL Monitor Report for a given SQL_ID (from MEM)
* cs_sqlmon_duration_chart.sql                                  - SQL Monitor Reports duration for a given SQL_ID (time series chart)
* cs_sqlmon_capture.sql                                         - Generate SQL Monitor Reports for given SQL_ID for a short period of time
* cs_sqlmon_binds.sql                                           - SQL Monitor Binds for given SQL_ID
* cs_sqlmon_top_binds.sql                                       - SQL Monitor Top Binds for given SQL_ID
* cs_sql_bind_capture.sql                                       - SQL Bind Capture for given SQL_ID
* cs_sql_bind_capture_one.sql                                   - SQL Bind Capture for given SQL_ID and Bind name (text report)
* cs_sql_bind_capture_one_chart.sql                             - SQL Bind Capture for given SQL_ID and Bind name (time series chart)
* cs_binds.sql                                                  - Binds for a given SQL_ID
* cs_sql_sessions.sql                                           - Recent and Active Sessions executing a SQL_ID
* cs_high_execution_rate_rps.sql                                - List executions by time for a given SQL_ID with high RPS 
* cs_sql_perf_concurrency.sql                                   - Concurrency Histogram of SQL with more than N Concurrent Sessions
* cs_sql_perf_high_aas.sql                                      - SQL with AAS per hour for a given Timed Event higher than N (time series text report)
* cs_purge_cursor.sql                                           - Purge Cursor(s) for SQL_ID using DBMS_SHARED_POOL.PURGE and SQL Patch

SPBL - SQL Plan Baselines
-------------------------
* cs_spbl_evolve.sql                                            - Evolve a SQL Plan Baseline for given SQL_ID
* cs_spbl_create.sql                                            - Create a SQL Plan Baseline for given SQL_ID
* cs_spbl_drop.sql                                              - Drop one or all SQL Plan Baselines for given SQL_ID
* cs_spbl_drop_all.sql                                          - Drop all SQL Plan Baselines for some SQL Text string on PDB
* cs_spbl_sprf_spch_drop_all.sql                                - Drop all SQL Plan Baselines, SQL Profiles and SQL Patches for some SQL Text string on PDB
* cs_spbl_list.sql                                              - Summary list of SQL Plan Baselines for given SQL_ID
* cs_spbl_list_all_pdb.sql                                      - List all SQL Plan Baselines for some SQL Text string on PDB
* cs_spbl_list_all_cdb.sql                                      - List all SQL Plan Baselines for some SQL Text string on CDB
* cs_spbl_sprf_spch_list_all.sql                                - List all SQL Plan Baselines, SQL Profiles and SQL Patches for some SQL Text string on PDB
* cs_spbl_plan.sql                                              - Display SQL Plan Baseline for given SQL_ID
* cs_spbl_enable.sql                                            - Enable one or all SQL Plan Baselines for given SQL_ID
* cs_spbl_disable.sql                                           - Disable one or all SQL Plan Baselines for given SQL_ID
* cs_spbl_accept.sql                                            - Accept one or all SQL Plan Baselines for given SQL_ID
* cs_spbl_fix.sql                                               - Fix one or all SQL Plan Baselines for given SQL_ID
* cs_spbl_unfix.sql                                             - Unfix one or all SQL Plan Baselines for given SQL_ID
* cs_spbl_stgtab.sql                                            - Creates Staging Table for SQL Plan Baselines
* cs_spbl_stgtab_delete.sql                                     - Deletes Staging Table for SQL Plan Baselines
* cs_spbl_pack.sql                                              - Packs into staging table one or all SQL Plan Baselines for given SQL_ID
* cs_spbl_unpack.sql                                            - Unpacks from staging table one or all SQL Plan Baselines for given SQL_ID
* cs_spbl_expdp.sql                                             - Packs into staging table one or all SQL Plan Baselines for given SQL_ID and Exports such Baselines using Datapump
* cs_spbl_impdp.sql                                             - Imports from Datapump file into a staging table all SQL Plan Baselines and Unpacks from staging table one or all SQL Plan Baselines for given SQL
* cs_spbl_meta.sql                                              - SQL Plan Baseline Metadata for given SQL_ID
* cs_spbl_indexes.sql                                           - List of Indexes Referenced by all SQL Plan Baselines on PDB
* cs_spbl_failed.sql                                            - List of SQL Plans with: "Failed to use SQL plan baseline for this statement"
* cs_spbl_corrupt.sql                                           - List of Corrupt SQL Plans with: missing Plan Rows from sys.sqlobj$plan
* cs_spbl_purge_outdated.sql                                    - Purge Outdated SQL Plan Baselines
* create_spb_from_awr.sql                                       - Create SQL Plan Baselin from AWR Plan (legacy script)
* create_spb_from_cur.sql                                       - Create SQL Plan Baseline from SQL Cursor (legacy script)
* spm_backup.sql                                                - Create DATAPUMP backup of SQL Plan Management (SPM) Repository for one PDB

SPRF - SQL Profiles
-------------------
* cs_sprf_create.sql                                            - Create a SQL Profile for given SQL_ID
* cs_sprf_drop.sql                                              - Drop all SQL Profiles for given SQL_ID
* cs_sprf_drop_all.sql                                          - Drop all SQL Profiles for some SQL Text string on PDB
* cs_sprf_list.sql                                              - Summary list of SQL Profiles for given SQL_ID
* cs_sprf_list_all_pdb.sql                                      - List all SQL Profiles for some SQL Text string on PDB
* cs_sprf_list_all_cdb.sql                                      - List all SQL Profiles for some SQL Text string on CDB
* cs_sprf_plan.sql                                              - Display SQL Profile Plan for given SQL_ID
* cs_sprf_enable.sql                                            - Enable one or all SQL Profiles for given SQL_ID
* cs_sprf_disable.sql                                           - Disable one or all SQL Profiles for given SQL_ID
* cs_sprf_xfr.sql                                               - Transfers a SQL Profile for given SQL_ID
* cs_sprf_export.sql                                            - Exports Execution Plans for some SQL_ID or all SQL in some PDBs, using SQL Profile(s)
* cs_sprf_stgtab.sql                                            - Creates Staging Table for SQL Profiles
* cs_sprf_pack.sql                                              - Packs into staging table one or all SQL Profiles for given SQL_ID
* cs_sprf_unpack.sql                                            - Unpack from staging table one or all SQL Profiles for given SQL_ID
* cs_sprf_category.sql                                          - Changes category for a SQL Profile for given SQL_ID
* cs_sprf_indexes.sql                                           - List of Indexes Referenced by all SQL Profiles on PDB
* coe_xfr_sql_profile.sql                                       - Transfer (copy) a SQL Profile from PDBx on CDBa into PDBy on CDBb (legacy script)

SPCH - SQL Patches
------------------
* cs_spch_first_rows.sql                                        - Create a SQL Patch with FIRST_ROWS for given SQL_ID, and drops SQL Profile and SQL Plan Baselines
* cs_spch_create.sql                                            - Create a SQL Patch for given SQL_ID
* cs_spch_drop.sql                                              - Drop all SQL Patches for given SQL_ID
* cs_spch_drop_all.sql                                          - Drop all SQL Patches for some SQL Text string on PDB
* cs_spch_list.sql                                              - Summary list of SQL Patches for given SQL_ID
* cs_spch_list_all_pdb.sql                                      - List all SQL Patches for some SQL Text string on PDB
* cs_spch_list_all_cdb.sql                                      - List all SQL Patches for some SQL Text string on CDB
* cs_spch_plan.sql                                              - Display SQL Patch Plan for given SQL_ID
* cs_spch_enable.sql                                            - Enable one or all SQL Patches for given SQL_ID
* cs_spch_disable.sql                                           - Disable one or all SQL Patches for given SQL_ID
* cs_spch_stgtab.sql                                            - Creates Staging Table for SQL Patches
* cs_spch_pack.sql                                              - Packs into staging table one or all SQL Patches for given SQL_ID
* cs_spch_unpack.sql                                            - Unpack from staging table one or all SQL Patches for given SQL_ID
* cs_spch_xfr.sql                                               - Transfers a SQL Patch for given SQL_ID
* cs_spch_category.sql                                          - Changes category for a SQL Patch for given SQL_ID

Sessions
--------
* a.sql | as.sql | cs_active_sessions.sql                       - Active Sessions including SQL Text and Exection Plan
* am.sql | cs_ash_mem_sample_report.sql                         - ASH Samples from MEM
* ah.sql | cs_ash_awr_sample_report.sql                         - ASH Samples from AWR
* cs_ash_awr_block_chains_report.sql                            - ASH Block Chains Report from AWR
* cs_ash_mem_block_chains_report.sql                            - ASH Block Chains Report from MEM
* cs_ash_awr_peaks_report.sql                                   - ASH Peaks Report from AWR
* cs_ash_mem_peaks_report.sql                                   - ASH Peaks Report from MEM
* cs_ash_awr_peaks_chart.sql                                    - ASH Peaks Chart from AWR
* cs_ash_mem_peaks_chart.sql                                    - ASH Peaks Chart from MEM
* cs_ash_awr_peaks_bubble.sql                                   - ASH Peaks Bubble from AWR
* cs_ash_mem_peaks_bubble.sql                                   - ASH Peaks Bubble from MEM
* cs_sessions.sql                                               - Simple list all current Sessions (all types and all statuses)
* cs_sessions_hist.sql                                          - Simple list all historical Sessions (all types and all statuses)
* cs_sessions_PCTL_by_machine.sql                               - Sessions Percentiles by Machine
* cs_sessions_by_type_and_status_chart.sql                      - Sessions by Type and Status (time series chart)
* cs_sessions_by_machine_chart.sql                              - Sessions by Machine (time series chart)
* cs_sessions_age_by_machine_chart.sql                          - Session Age by Machine (time series chart)
* cs_sessions_by_pdb_chart.sql                                  - Sessions by PDB (time series chart)
* cs_sess_mon.sql                                               - Monitored Sessions
* mysid.sql                                                     - Get SID and SPID of own Session
* open_cursor.sql                                               - Open Cursors and Count of Distinct SQL_ID per Session
* session_undo.sql                                              - Displays undo information on relevant database sessions (by Tim Hall)

Kill Sessions
-------------
* cs_kill_sid.sql                                               - Kill one User Session
* cs_kill_sql_id.sql                                            - Kill User Sessions executing some SQL_ID
* cs_kill_root_blockers.sql                                     - Kill Root Blocker User Sessions 
* cs_kill_machine.sql                                           - Kill User Sessions connected from some Machine(s)
* cs_kill_scheduler.sql                                         - Kill User Sessions waiting on Scheduler (Resource Manager)

Blocked Sessions
----------------
* bs.sql | cs_blocked_sessions_report.sql                       - Blocked Sessions Report
* cs_blocked_sessions_ash_awr_report.sql                        - Top Session Blockers by multiple Dimensions as per ASH from AWR (text report)
* cs_blocked_sessions_by_state_ash_awr_chart.sql                - Top Session Blockers by State of Root Blocker as per ASH from AWR (time series chart)
* cs_blocked_sessions_by_machine_ash_awr_chart.sql              - Top Session Blockers by Machine of Root Blocker as per ASH from AWR (time series chart)
* cs_blocked_sessions_by_module_ash_awr_chart.sql               - Top Session Blockers by Module of Root Blocker as per ASH from AWR (time series chart)
* cs_blocked_sessions_by_sid_ash_awr_chart.sql                  - Top Session Blockers by SID of Root Blocker as per ASH from AWR (time series chart)

Locks
-----
* locks.sql | cs_locks.sql                                      - Locks Summary and Details
* cs_locks_mon.sql                                              - Locks Summary and Details - Monitor
* cs_wait_chains.sql                                            - Wait Chains (text report)

Space Reporting
---------------
* cs_df_u02_chart.sql                                           - Disk FileSystem u02 Utilization Chart
* cs_top_pdb_size_chart.sql                                     - Top PDB Disk Size Utilization (time series chart)
* cdb_tablespace_usage_metrics.sql                              - Application Tablespace Inventory for all PDBs
* cs_tablespaces.sql                                            - Tablespace Utilization (text report)
* cs_tablespace_chart.sql                                       - Tablespace Utilization (time series chart)
* cs_extents_map.sql                                            - Tablespace Block Map
* cs_top_segments.sql                                           - Top CDB or PDB Segments (text report)
* cs_top_segments_pdb.sql                                       - Top PDB Segments (text report)
* cs_segment_chart.sql                                          - Segment Size GBs for given Segment (time series chart)
* cs_tempseg_usage.sql                                          - Temporary (Temp) Segment Usage (text report)
* cs_table_segments_chart.sql                                   - Table-related Segment Size GBs (Table, Indexes and Lobs) for given Table (time series chart)
* cs_estimate_table_size.sql                                    - Estimate Table Size
* cs_tables.sql                                                 - All Tables and Top N Tables (text report)
* cs_top_tables.sql                                             - Top Tables according to Segment(s) size (text report)
* cs_top_table_size_chart.sql                                   - Top PDB Tables (time series chart)
* cs_table.sql                                                  - Table Details
* cs_table_stats_chart.sql                                      - CBO Statistics History for given Table (time series chart)
* cs_table_stats_30d_chart.sql                                  - CBO Statistics History for given Table (30 days time series chart)
* cs_table_stats_report.sql                                     - CBO Statistics History for given Table (time series text report)
* cs_table_mod_chart.sql                                        - Table Modification History (INS, DEL and UPD) for given Table (time series chart)
* cs_table_mod_report.sql                                       - Table Modification History (INS, DEL and UPD) for given Table (text report)
* cs_tables_rows_vs_count.sql                                   - Compares CBO Stats Rows to COUNT(*) on Application Tables
* cs_tables_rows_vs_count_outliers.sql                          - Compares CBO Stats Rows to COUNT(*) on Application Tables and Reports Outliers
* cs_estimate_index_size.sql                                    - Estimate Index Size
* cs_top_bloated_indexes.sql                                    - Top bloated indexes on a PDB (text report)
* cs_top_indexes.sql                                            - Top Indexes according to Segment(s) size
* cs_index_part_reorg.sql                                       - Calculate index reorg savings
* cs_index_usage.sql                                            - Index Usage (is an index still in use?)
* cs_foreign_key_fk_constraints_missing_indexes.sql             - Generate DDL to create missing Indexes to support FK constraints
* cs_recyclebin.sql                                             - Recyclebin Content
* cs_top_lobs.sql                                               - Top Lobs according to Segment(s) size

Space Maintenance
-----------------
* cs_tbs_resize.sql                                             - Tablespace Resize
* cs_redef_table.sql                                            - Table Redefinition
* cs_redef_table_silent.sql                                     - Table Redefinition - Silent
* cs_redef_table_with_purge.sql                                 - Table Redefinition with Purge
* cs_redef_schema.sql                                           - Schema Redefinition (by moving all objects into new Tablespace)
* cs_redef_remove_lob_dedup_on_pdb.sql                          - Remove LOB Deduplication on PDB
* cs_drop_redef_table.sql                                       - Generate commands to drop stale objects from failed Table Redefinition(s)

Container
---------
* cdb.sql                                                       - Connect into CDB$ROOT
* pdb.sql                                                       - List all PDBs and Connect into one PDB
* cs_pdbs.sql                                                   - PDBs attributes

System Metrics
--------------
* cs_all_sysmetric_for_cdb_mem.sql                              - All System Metrics as per V$SYSMETRIC Views for a CDB (text report)
* cs_all_sysmetric_for_pdb_mem.sql                              - All System Metrics as per V$CON_SYSMETRIC Views for a PDB (text report)
* cs_all_sysmetric_for_cdb_hist.sql                             - All System Metrics as per DBA_HIST_SYSMETRIC_SUMMARY View for a CDB (text report)
* cs_all_sysmetric_for_pdb_hist.sql                             - All System Metrics as per DBA_HIST_CON_SYSMETRIC_SUMM View for a PDB (text report)
* cs_load_sysmetric_for_cdb_mem.sql                             - System Load as per V$SYSMETRIC Views for a CDB (text report)
* cs_load_sysmetric_per_pdb_mem.sql                             - System Load as per V$CON_SYSMETRIC Views per PDB (text report)
* cs_load_sysmetric_for_pdb_mem.sql                             - System Load as per V$CON_SYSMETRIC Views for a PDB (text report)
* cs_load_sysmetric_for_cdb_hist.sql                            - System Load as per DBA_HIST_SYSMETRIC_SUMMARY View for a CDB (text report)
* cs_load_sysmetric_per_pdb_hist.sql                            - System Load as per DBA_HIST_CON_SYSMETRIC_SUMM View per PDB (text report)
* cs_load_sysmetric_for_pdb_hist.sql                            - System Load as per DBA_HIST_CON_SYSMETRIC_SUMM View for a PDB (text report)
* cs_one_sysmetric_per_pdb_chart.sql                            - One System Metric as per DBA_HIST_CON_SYSMETRIC_SUMM View per PDB (time series chart)
* cs_some_sysmetric_for_cdb_mem_chart.sql                       - Some System Metrics as per V$SYSMETRIC_HISTORY View for a CDB (time series chart)
* cs_some_sysmetric_for_pdb_mem_chart.sql                       - Some System Metrics as per V$CON_SYSMETRIC_HISTORY View for a PDB (time series chart)
* cs_some_sysmetric_for_cdb_hist_chart.sql                      - Some System Metrics as per DBA_HIST_SYSMETRIC_SUMMARY View for a CDB (time series chart)
* cs_some_sysmetric_for_pdb_hist_chart.sql                      - Some System Metrics as per DBA_HIST_CON_SYSMETRIC_SUMM View for a PDB (time series chart)
* cs_cpu_sysmetric_for_cdb_mem_chart.sql                        - CPU System Metrics as per V$SYSMETRIC_HISTORY View for a CDB (time series chart)
* cs_cpu_sysmetric_for_pdb_mem_chart.sql                        - CPU System Metrics as per V$CON_SYSMETRIC_HISTORY View for a PDB (time series chart)
* cs_cpu_sysmetric_for_cdb_hist_chart.sql                       - CPU System Metrics as per DBA_HIST_SYSMETRIC_SUMMARY View for a CDB (time series chart)
* cs_cpu_sysmetric_for_pdb_hist_chart.sql                       - CPU System Metrics as per DBA_HIST_CON_SYSMETRIC_SUMM View for a PDB (time series chart)

System Stats and Events
-----------------------
* cs_sysstat_hist_chart.sql                                     - Subset of System Statistics from AWR (time series chart)
* cs_sysstat_hist_chart_io.sql                                  - IO System Statistics from AWR (time series chart)
* cs_system_event_hist_latency_chart.sql                        - Subset of System Event Latency from AWR (time series chart)
* cs_system_event_hist_load_char.sql                            - Subset of System Event AAS Load from AWR (time series chart)
* cs_system_event_hist_total_waits_chart.sql                    - Subset of System Event Total Waits from AWR (time series chart)
* cs_system_event_histogram_chart.sql                           - One System Event AAS Load Histogram from AWR as per Latency Bucket (time series chart)
* cs_sqlarea_per_pdb.sql                                        - SQL Area per PDB
* cs_pga_consumers.sql                                          - PGA Consumption per Process
* cs_resource_limit_chart.sql                                   - Resource Limit (time series chart)
* cs_total_and_parse_cpu_to_db_chart.sql                        - Total and Parse CPU-to-DB Ratio from AWR (time series chart)
* cs_total_and_parse_db_and_cpu_aas_chart.sql                   - Total and Parse DB and CPU Average Active Sessions (AAS) from AWR (time series chart)

Configuration
-------------
* cs_fix_configuration_and_parameters.sql                       - Fix database configuration and parameters set incorrectly
* cs_acs_enable.sql                                             - Enable Adaptive Cursor Sharing (ACS)
* cs_acs_disable.sql                                            - Disable Adaptive Cursor Sharing (ACS)
* cs_dba_hist_parameter.sql                                     - System Parameters History
* cs_dg.sql                                                     - Data Guard Configuration
* cs_dg_protection_mode_switches.sql                            - Data Guard Protection Mode Switches as per Log Archive Dest
* cs_sgastat_awr_area_chart.sql                                 - SGA Pools History Chart from AWR
* cs_sgastat_awr_line_chart.sql                                 - SGA Pools History Chart from AWR (include free memory)
* cs_sgastat_awr_report.sql                                     - SGA Pools History Report from AWR (include free memory)
* dba_high_water_mark_statistics.sql                            - Database High Water Mark (HWM) Statistics
* spfile.sql                                                    - SPFILE Parameters (from PDB or CDB)
* pdb_spfile.sql                                                - PDB SPFILE Parameters (from CDB)
* syncup_pdb_parameters_to_standbys.sql                         - Sync up SPFILE PDB Parameters from Primary into Standby and Bystander
* hidden_parameter.sql                                          - Get value of one hidden parameter
* hidden_parameters.sql                                         - Get value of all hidden parameters

Logs
----
* log.sql                                                       - REDO Log on Primary and Standby
* log_history.sql                                               - REDO Log History 
* archived_log.sql                                              - Archived Logs list

Traces
------
* cs_diag_trace.sql                                             - Directory path for traces
* alert_log_tail.sql                                            - Last 50 lines of alert log refreshed every 5 seconds 20 times 
* cs_alert_log.sql                                              - Get alert log
* cs_LGWR_trc.sql                                               - Get log writer LGWR trace
* cs_DBRM_trc.sql                                               - Get database resource manager DBRM trace
* cs_CKPT_trc.sql                                               - Get check point CKPT trace
* cs_listener_log.sql                                           - Get listener log
* cs_hanganalyze.sql                                            - Generate Hanganalyze Trace
* cs_systemstate.sql                                            - Generate System State Dump Trace
* cs_trace_session.sql                                          - Trace one session given a SID
* trace_10046_sql_id.sql                                        - Turn ON and OFF SQL Trace EVENT 10046 LEVEL 12 on given SQL_ID
* trace_10053_sql_id.sql                                        - Turn ON and OFF SQL Trace EVENT 10053 LEVEL 1 on given SQL_ID
* trace_DUMP_sql_id.sql                                         - DBMS_SQLDIAG.dump_trace SQL_Optimizer on given SQL_ID
* trace_SPM_sql_id.sql                                          - Turn ON and OFF SQL Plan Management Trace on given SQL_ID
* trace_10046_mysid_on.sql                                      - Turn ON SQL Trace EVENT 10046 LEVEL 12 on own Session
* trace_10046_mysid_off.sql                                     - Turn OFF SQL Trace on own Session
* trace_10053_mysid_on.sql                                      - Turn ON CBO EVENT 10053 LEVEL 1 on own Session
* trace_10053_mysid_off.sql                                     - Turn OFF CBO EVENT 10053 on own Session
* trace_10046_10053_mysid_on.sql                                - Turn ON SQL Trace EVENT 10046 LEVEL 12 and 10053 on own Session
* trace_10046_10053_mysid_off.sql                               - Turn OFF SQL Trace and 10053 on own Session

Reports
-------
* awrrpt.sql                                                    - AWR Report
* awrddrpt.sql                                                  - AWR Difference Report
* ashrpt.sql                                                    - ASH report
* awrsqrpt.sql                                                  - AWR SQL Report
* awr_snapshot.sql                                              - Create AWR snapshot
* cs_dbms_stats_age.sql                                         - DBMS_STATS Age as per "auto optimizer stats collection"
* cs_dbms_stats_gather_database_stats.sql                       - Execute DBMS_STATS.GATHER_DATABASE_STATS
* cs_dbms_stats_gather_database_stats_job.sql                   - Execute DBMS_STATS.GATHER_DATABASE_STATS (stand-alone)
* cs_dbms_stats_operations.sql                                  - Generate DBMS_STATS.report_stats_operations
* cs_dbms_stats_auto.sql                                        - Generate DBMS_STATS.report_gather_auto_stats
* cs_amw_report.sql                                             - Automatic Maintenance Window Report

Miscellaneous Utilities
-----------------------
* cs_fs.sql                                                     - Find SQL statements matching some string
* cs_mark_sql_hot.sql                                           - Use DBMS_SHARED_POOL.markhot to reduce contention during high concurency hard parse
* cs_unmark_sql_hot.sql                                         - Use DBMS_SHARED_POOL.unmarkhot to undo cs_mark_sql_hot.sql
* pr.sql | cs_pr.sql                                            - Print Table (vertical display of result columns for last query)
* cs_burn_cpu.sql                                               - Burn CPU in multiple cores/threads for some time
* cs_hexdump_to_timestamp.sql                                   - Convert Hexadecimal Dump to Time
* cs_epoch_to_time.sql                                          - Convert Epoch to Time
* cs_time_to_epoch.sql                                          - Convert Time to Epoch
* cs_past_days_to_epoch.sql                                     - Convert Past Days to Epoch
* opatch.sql                                                    - Oracle Patch Registry and History
* reason_not_shared.sql                                         - Reasons for not sharing Cursors
* sysdate.sql                                                   - Display SYSDATE in Filename safe format and in YYYY-MM-DDTHH24:MI:SS UTC format
* view.sql                                                      - Display Text of a given VIEW name
* find_all_privs.sql                                            - Roles and Priviledges for a given User (Pete Finnigan)

Notes
-----
* To use these cscripts scripts, connect to database server as oracle, navigate to cscripts scripts directory, and connect into SQL*Plus as SYS.
* Execute h.sql or help.sql for full list above. Execute ls.sql for a full alphabetical list. Type q to exit. 
