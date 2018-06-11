CREATE OR REPLACE PACKAGE &&1..iod_space AUTHID CURRENT_USER AS
/* $Header: iod_space.pks.sql 2018-06-02T00:56:18 carlos.sierra $ */
/* ------------------------------------------------------------------------------------ */
--
-- Purpose:     Space related APIs
--
-- Author:      Carlos Sierra
--
-- Usage:       Execute from CDB$ROOT.
--
--              TABLE_STATS_HIST
--                  Table Statistics History - used for table growth monitoring
--                  Expected to execute every hour
--
--              TAB_MODIFICATIONS_HIST
--                  Table Modifications History - used for insert/delete rate monitoring
--                  Expected to execute every hour
--
--              SEGMENTS_HIST
--                  Segments History - used for tablespace and segment monitoring
--                  Expected to execute every day
--
--              TABLESPACES_HIST
--                  Segments History - used for tablespace monitoring
--                  Expected to execute every day
--
--              INDEX_REBUILD
--                  Online Index Rebuild - Full Scans
--                  Expected to execute every day
--
--              TABLE_REDEFINITION
--                  Table Redefinition - Full Scans
--                  Expected to execute every day
--
--              PURGE_RECYCLEBIN
--                  Purge outdated segments on Recyclebin
--                  Expected to execute every day
--
/* ------------------------------------------------------------------------------------ */
gk_package_version            CONSTANT VARCHAR2(30)  := '2018-06-02T00:56:18'; -- used to circumvent ORA-04068: existing state of packages has been discarded
gk_report_only                CONSTANT VARCHAR2(1)   := 'Y';
gk_only_if_ref_by_full_scans  CONSTANT VARCHAR2(1)   := 'Y'; -- to perform DDL oprration
gk_min_size_mb                CONSTANT NUMBER        := 10; -- of segment to perform DDL oprration
gk_min_savings_perc           CONSTANT NUMBER        := 25; -- for segment to perform DDL oprration
gk_min_ts_used_percent        CONSTANT NUMBER        := 85; -- to perform DDL operation
gk_min_obj_age_days           CONSTANT NUMBER        := 8; -- to perform DDL operation
gk_sleep_seconds              CONSTANT NUMBER        := 120; -- between 2 DDLs
gk_timeout_hours              CONSTANT NUMBER        := 4; -- max hours to execute DDL APIs
gk_table_stats_days           CONSTANT NUMBER        := 63; -- max age to collect table stats history  
gk_preserve_recyclebin_days   CONSTANT NUMBER        := 8; -- purge older recyclebin segments
gk_date_format                CONSTANT VARCHAR2(30)  := 'YYYY-MM-DD"T"HH24:MI:SS';
/* ------------------------------------------------------------------------------------ */
FUNCTION get_package_version -- used to circumvent ORA-04068: existing state of packages has been discarded
RETURN VARCHAR2;
/* ------------------------------------------------------------------------------------ */
PROCEDURE table_stats_hist;
/* ------------------------------------------------------------------------------------ */
PROCEDURE tab_modifications_hist;
/* ------------------------------------------------------------------------------------ */
PROCEDURE segments_hist;
/* ------------------------------------------------------------------------------------ */
PROCEDURE tablespaces_hist;
/* ------------------------------------------------------------------------------------ */
PROCEDURE index_rebuild (
  p_report_only               IN VARCHAR2 DEFAULT gk_report_only,
  p_only_if_ref_by_full_scans IN VARCHAR2 DEFAULT gk_only_if_ref_by_full_scans,
  p_min_size_mb               IN NUMBER   DEFAULT gk_min_size_mb,
  p_min_savings_perc          IN NUMBER   DEFAULT gk_min_savings_perc,
  p_min_obj_age_days          IN NUMBER   DEFAULT gk_min_obj_age_days,
  p_sleep_seconds             IN NUMBER   DEFAULT gk_sleep_seconds,
  p_timeout                   IN DATE     DEFAULT SYSDATE + (gk_timeout_hours/24),
  p_pdb_name                  IN VARCHAR2 DEFAULT NULL
);
/* ------------------------------------------------------------------------------------ */
PROCEDURE table_redefinition (
  p_report_only               IN VARCHAR2 DEFAULT gk_report_only,
  p_only_if_ref_by_full_scans IN VARCHAR2 DEFAULT gk_only_if_ref_by_full_scans,
  p_min_size_mb               IN NUMBER   DEFAULT gk_min_size_mb,
  p_min_savings_perc          IN NUMBER   DEFAULT gk_min_savings_perc,
  p_min_ts_used_percent       IN NUMBER   DEFAULT gk_min_ts_used_percent,
  p_min_obj_age_days          IN NUMBER   DEFAULT gk_min_obj_age_days,
  p_sleep_seconds             IN NUMBER   DEFAULT gk_sleep_seconds,
  p_timeout                   IN DATE     DEFAULT SYSDATE + (gk_timeout_hours/24),
  p_pdb_name                  IN VARCHAR2 DEFAULT NULL
);
/* ------------------------------------------------------------------------------------ */
PROCEDURE purge_recyclebin (
  p_preserve_recyclebin_days  IN NUMBER   DEFAULT gk_preserve_recyclebin_days,
  p_timeout                   IN DATE     DEFAULT SYSDATE + (gk_timeout_hours/24),
  p_pdb_name                  IN VARCHAR2 DEFAULT NULL
);
/* ------------------------------------------------------------------------------------ */
END iod_space;
/
