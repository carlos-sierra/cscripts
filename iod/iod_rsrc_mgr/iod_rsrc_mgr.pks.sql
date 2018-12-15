CREATE OR REPLACE PACKAGE &&1..iod_rsrc_mgr AUTHID CURRENT_USER AS
/* $Header: iod_rsrc_mgr.pks.sql &&library_version. carlos.sierra $ */
/* ------------------------------------------------------------------------------------ */
--
-- Purpose:     CDB Resource Manager - Setup
--
-- Author:      Carlos Sierra
--
-- Usage:       Execute from CDB$ROOT.
--
--              Sets a CDB resource manager that assigns weigthed shares and utilization
--              limits per PDB.
--
--              Shares are between 4 and 8. The most privileged PDB can get up to 2x  
--              more CPU quantums than the least privileged. Privilege is based on ASH
--              history, where a 95th PCTL on "ON CPU" and "Scheduler" times are prorated
--              as per adjusted number of cores. E.g. 36 cores, and PDB has a 95th PCTL 
--              of 36 (or higher), then shares becomes 8.
--
--              Utlization limits is between 6 and 36.
--              Prorated as per ratio between 99th PCTL of "ON CPU" + "Scheduler" as per
--              ASH history, where if such AAS were equal or larger than CPU cores 
--              (e.g. 36) then utlization limit for PDB would be 36%. Then, any PDB could
--              consume up to 36% of the resources (cpu_count) assigned to database.
--              With 36 cores, and 2 threads per core, we have 72 "cpus", then
--              if a PDB gets 36% utilization limit, such PDB can use of to 25.92 CPUs.
--
-- Example:     SET LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
--              EXEC &&1..iod_rsrc_mgr.reset(p_report_only => 'N', p_plan => 'IOD_CDB_PLAN', p_switch_plan => 'Y');
--              EXEC &&1..iod_rsrc_mgr.reset_iod_cdb_plan;
--  
-- Example(2):  -- update one PDB
--              EXEC &&1..iod_rsrc_mgr.update_cdb_plan_directive(p_plan => 'IOD_CDB_PLAN', p_pluggable_database => 'WFS', p_shares => 4, p_utilization_limit => 25, p_parallel_server_limit = 50);
--              EXEC &&1..iod_rsrc_mgr.update_cdb_plan_directive(p_pluggable_database => 'WFS', p_shares => 4, p_utilization_limit => 25);
--
-- Notes:       (1) Parameter p_report_only = 'Y' produces "what-if" report.
--
/* ------------------------------------------------------------------------------------ */
gk_report_only                CONSTANT VARCHAR2(1)   := 'Y';
gk_plan                       CONSTANT VARCHAR2(128) := 'IOD_CDB_PLAN';
gk_incl_pdb_directives        CONSTANT VARCHAR2(1)   := 'Y';
gk_switch_plan                CONSTANT VARCHAR2(1)   := 'N';
gk_ash_age_days               CONSTANT NUMBER        := 10;
gk_pdb_age_days               CONSTANT NUMBER        := 5;
gk_utilization_adjust_factor  CONSTANT NUMBER        := 1; -- 1.2 means adjust 20% up "original" algorithm
gk_autotask_shares            CONSTANT NUMBER        := 2;
gk_shares_low                 CONSTANT NUMBER        := 4;
gk_shares_high                CONSTANT NUMBER        := 8;
gk_shares_default             CONSTANT NUMBER        := 6;
gk_utilization_limit_low      CONSTANT NUMBER        := 6;
gk_utilization_limit_high     CONSTANT NUMBER        := 36;
gk_utilization_limit_default  CONSTANT NUMBER        := 12;
gk_parallel_server_limit_low  CONSTANT NUMBER        := 50;
gk_parallel_server_limit_high CONSTANT NUMBER        := 100;
gk_parallel_server_limit_def  CONSTANT NUMBER        := 50;
--
gk_core_util_days_default     CONSTANT NUMBER        := 7;
gk_core_util_perc_default     CONSTANT NUMBER        := 100;
gk_history_days_default       CONSTANT NUMBER        := 60;
gk_date_format                CONSTANT VARCHAR2(30)  := 'YYYY-MM-DD"T"HH24:MI:SS';
/* ------------------------------------------------------------------------------------ */
FUNCTION core_util_perc (
  p_days                   IN NUMBER   DEFAULT gk_core_util_days_default
)
RETURN NUMBER;
/* ------------------------------------------------------------------------------------ */
FUNCTION core_util_forecast_date (
  p_core_util_perc         IN NUMBER   DEFAULT gk_core_util_perc_default,
  p_history_days           IN NUMBER   DEFAULT gk_history_days_default
)
RETURN DATE;
/* ------------------------------------------------------------------------------------ */
FUNCTION core_util_forecast_days (
  p_core_util_perc         IN NUMBER   DEFAULT gk_core_util_perc_default,
  p_history_days           IN NUMBER   DEFAULT gk_history_days_default
)
RETURN NUMBER;
/* ------------------------------------------------------------------------------------ */
PROCEDURE update_cdb_plan_directive (
  p_plan                   IN VARCHAR2 DEFAULT gk_plan,
  p_pluggable_database     IN VARCHAR2,
  p_comment                IN VARCHAR2 DEFAULT 'UPD:'||TO_CHAR(SYSDATE, gk_date_format)||' MANUAL',
  p_shares                 IN NUMBER   DEFAULT gk_shares_default,
  p_utilization_limit      IN NUMBER   DEFAULT gk_utilization_limit_default,
  p_parallel_server_limit  IN NUMBER   DEFAULT gk_parallel_server_limit_def,
  p_aas_p99                IN NUMBER   DEFAULT TO_NUMBER(NULL),
  p_aas_p95                IN NUMBER   DEFAULT TO_NUMBER(NULL),
  p_con_id                 IN NUMBER   DEFAULT TO_NUMBER(NULL),
  p_snap_time              IN DATE     DEFAULT SYSDATE
);
/* ------------------------------------------------------------------------------------ */
PROCEDURE reset (
  p_report_only            IN VARCHAR2 DEFAULT gk_report_only,
  p_plan                   IN VARCHAR2 DEFAULT gk_plan,
  p_include_pdb_directives IN VARCHAR2 DEFAULT gk_incl_pdb_directives,
  p_switch_plan            IN VARCHAR2 DEFAULT gk_switch_plan
);
/* ------------------------------------------------------------------------------------ */
END iod_rsrc_mgr;
/
