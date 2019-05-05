CREATE OR REPLACE PACKAGE  &&1..iod_sqlstats AS
/* $Header: iod_sqlstats.pks.sql &&library_version. carlos.sierra $ */
/* ------------------------------------------------------------------------------------ */
--
-- Purpose:     SQLSTATS APIs
--
-- Author:      Carlos Sierra
--
-- Usage:       Execute from CDB$ROOT.
--
--              SNAP
--                  Snapshots of V$SQLSTATS
--                  Expected to execute 5 minutes
--
/* ------------------------------------------------------------------------------------ */
gk_package_version            CONSTANT VARCHAR2(30)  := '2018-08-03T21:37:01'; -- used to circumvent ORA-04068: existing state of packages has been discarded
gk_regression_threshold       CONSTANT NUMBER        := 2; -- N times regression of DB Time, CPU Time and Buffer Gets to capture sql (2x)
gk_db_aas_threshold           CONSTANT NUMBER        := 0.002; -- minimum average active sessions as per elapsed time from last awr to capture sql (0.002 DB AAS) 
gk_db_us_exe_threshold        CONSTANT NUMBER        := 1000; -- minimum microseconds of database time per execution from last awr to capture sql (1000 us = 1 ms)
gk_last_active_time_age_secs  CONSTANT NUMBER        := 300; -- maximum age in seconds, of last active time to capture sql (300 secs = 5 mins)
gk_last_awr_snapshot_age_secs CONSTANT NUMBER        := 1; -- minimum age of awr metrics to capture sql (1 sec)
gk_instance_startup_age_secs  CONSTANT NUMBER        := 60; -- minimum age of instance to capture sql (60 secs = 1 minute)
gk_capture_ash_secs           CONSTANT NUMBER        := 300; -- average active sessions history to capture
gk_date_format                CONSTANT VARCHAR2(30)  := 'YYYY-MM-DD"T"HH24:MI:SS';
/* ------------------------------------------------------------------------------------ */  
FUNCTION get_package_version
RETURN VARCHAR2;
/* ------------------------------------------------------------------------------------ */  
PROCEDURE snapshot (
  p_regression_threshold        IN NUMBER   DEFAULT gk_regression_threshold,
  p_db_aas_threshold            IN NUMBER   DEFAULT gk_db_aas_threshold,
  p_db_us_exe_threshold         IN NUMBER   DEFAULT gk_db_us_exe_threshold,
  p_last_active_time_age_secs   IN NUMBER   DEFAULT gk_last_active_time_age_secs,
  p_last_awr_snapshot_age_secs  IN NUMBER   DEFAULT gk_last_awr_snapshot_age_secs,
  p_instance_startup_age_secs   IN NUMBER   DEFAULT gk_instance_startup_age_secs,
  p_capture_ash_secs            IN NUMBER   DEFAULT gk_capture_ash_secs
);
/* ------------------------------------------------------------------------------------ */
END iod_sqlstats;
/

