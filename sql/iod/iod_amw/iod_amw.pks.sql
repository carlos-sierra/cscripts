CREATE OR REPLACE PACKAGE &&1..iod_amw AUTHID CURRENT_USER AS
/* $Header: iod_amw.pks.sql &&library_version. carlos.sierra $ */
/* ------------------------------------------------------------------------------------ */
--
-- Purpose:     Autotask Maintenance Windows - Configuration
--              Reset related Autotasks and Windows
--
-- Author:      Carlos Sierra
--
-- Usage:       Execute from CDB$ROOT.
--
-- Example:     For all PDBs:
--                SET LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
--                EXEC &&1..iod_amw.reset(p_report_only => 'N');
--  
--              For one PDB:
--                SET LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
--                EXEC &&1..iod_amw.reset(p_report_only => 'N', p_pdb_name => 'COMPUTE');
--
-- Notes:       (1) Parameter p_report_only = 'Y' produces "what-if" report.
--
--              (2) Expected to execute for all PDBs.
--
/* ------------------------------------------------------------------------------------ */
gk_report_only                 CONSTANT VARCHAR2(1) := 'N';
gk_default_timezone            CONSTANT VARCHAR2(8) := '+00:00';
gk_log_history                 CONSTANT VARCHAR2(8) := '14';
gk_accept_sql_profiles_status  CONSTANT VARCHAR2(8) := 'DISABLE';
gk_auto_spm_evolve_status      CONSTANT VARCHAR2(8) := 'DISABLE';
gk_optimizer_stats_status      CONSTANT VARCHAR2(8) := 'ENABLE';
gk_sql_tune_advisor_status     CONSTANT VARCHAR2(8) := 'DISABLE';
gk_segment_advisor_status      CONSTANT VARCHAR2(8) := 'DISABLE';
/* ------------------------------------------------------------------------------------ */
gk_maintenance_windows_per_day CONSTANT NUMBER := 4; -- 1-4, 4 is recommended (how many times per day we open all maintenance windows)
gk_first_window_offset_hours   CONSTANT NUMBER := 0; -- 1 means 1AM, 12 is fine if there is only 1 window, else set to 0
gk_opening_window_size_hours   CONSTANT NUMBER := 2; -- >= 2 is recommended (all pdbs get staggered open during this time)
gk_window_duration_in_hours    CONSTANT NUMBER := 4; -- must be >= 4, 4 is recommended (all pdbs have same maintenance window duration)
/* ------------------------------------------------------------------------------------ */
/*
-- MON-FRI - one window
gk_mon_fri_maintenance_windows CONSTANT NUMBER := 1; 
gk_mon_fri_first_window_offset CONSTANT NUMBER := gk_first_window_offset_hours + 12; 
gk_mon_fri_opening_window_size CONSTANT NUMBER := gk_opening_window_size_hours; 
gk_mon_fri_window_duration_in  CONSTANT NUMBER := gk_window_duration_in_hours; 
*/
-- MON-FRI - multiple windows
gk_mon_fri_maintenance_windows CONSTANT NUMBER := gk_maintenance_windows_per_day; 
gk_mon_fri_first_window_offset CONSTANT NUMBER := gk_first_window_offset_hours; 
gk_mon_fri_opening_window_size CONSTANT NUMBER := gk_opening_window_size_hours; 
gk_mon_fri_window_duration_in  CONSTANT NUMBER := gk_window_duration_in_hours; 
/* ------------------------------------------------------------------------------------ */
/*
-- SAT-SUN - one window
gk_sat_sun_maintenance_windows CONSTANT NUMBER := 1; 
gk_sat_sun_first_window_offset CONSTANT NUMBER := gk_first_window_offset_hours + 12; 
gk_sat_sun_opening_window_size CONSTANT NUMBER := gk_opening_window_size_hours; 
gk_sat_sun_window_duration_in  CONSTANT NUMBER := gk_window_duration_in_hours; 
*/
-- SAT-SUN - multiple windows
gk_sat_sun_maintenance_windows CONSTANT NUMBER := gk_maintenance_windows_per_day; 
gk_sat_sun_first_window_offset CONSTANT NUMBER := gk_first_window_offset_hours; 
gk_sat_sun_opening_window_size CONSTANT NUMBER := gk_opening_window_size_hours; 
gk_sat_sun_window_duration_in  CONSTANT NUMBER := gk_window_duration_in_hours; 
/* ------------------------------------------------------------------------------------ */
PROCEDURE autotasks_and_maint_windows (
  p_report_only                 IN VARCHAR2 DEFAULT gk_report_only,
  p_pdb_name                    IN VARCHAR2 DEFAULT NULL,
  p_default_timezone            IN VARCHAR2 DEFAULT gk_default_timezone,
  p_log_history                 IN VARCHAR2 DEFAULT gk_log_history,
  p_accept_sql_profiles         IN VARCHAR2 DEFAULT gk_accept_sql_profiles_status,
  p_auto_spm_evolve             IN VARCHAR2 DEFAULT gk_auto_spm_evolve_status,
  p_optimizer_stats             IN VARCHAR2 DEFAULT gk_optimizer_stats_status,
  p_sql_tune_advisor            IN VARCHAR2 DEFAULT gk_sql_tune_advisor_status,
  p_segment_advisor             IN VARCHAR2 DEFAULT gk_segment_advisor_status,
  p_mon_fri_maintenance_windows IN NUMBER   DEFAULT gk_mon_fri_maintenance_windows,
  p_mon_fri_first_window_offset IN NUMBER   DEFAULT gk_mon_fri_first_window_offset,
  p_mon_fri_opening_window_size IN NUMBER   DEFAULT gk_mon_fri_opening_window_size,
  p_mon_fri_window_duration_in  IN NUMBER   DEFAULT gk_mon_fri_window_duration_in,
  p_sat_sun_maintenance_windows IN NUMBER   DEFAULT gk_sat_sun_maintenance_windows,
  p_sat_sun_first_window_offset IN NUMBER   DEFAULT gk_sat_sun_first_window_offset,
  p_sat_sun_opening_window_size IN NUMBER   DEFAULT gk_sat_sun_opening_window_size,
  p_sat_sun_window_duration_in  IN NUMBER   DEFAULT gk_sat_sun_window_duration_in 
);
/* ------------------------------------------------------------------------------------ */
PROCEDURE reset (
  p_report_only IN VARCHAR2 DEFAULT gk_report_only,
  p_pdb_name    IN VARCHAR2 DEFAULT NULL
);
/* ------------------------------------------------------------------------------------ */
PROCEDURE reset_amw (
  p_report_only IN VARCHAR2 DEFAULT gk_report_only,
  p_pdb_name    IN VARCHAR2 DEFAULT NULL,
  p_windows     IN VARCHAR2 DEFAULT gk_maintenance_windows_per_day /* [{4}|1|0|2|3|6] */
);
/* ------------------------------------------------------------------------------------ */
END iod_amw;
/
