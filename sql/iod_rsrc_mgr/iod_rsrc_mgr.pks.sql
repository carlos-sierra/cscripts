CREATE OR REPLACE PACKAGE &&1..iod_rsrc_mgr AUTHID CURRENT_USER AS
/* $Header: iod_rsrc_mgr.pks.sql 2018-02-27T01:15:26 carlos.sierra $ */
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
--              Shares are between 1 and 10. The most privileged PDB can get up to 10x  
--              more CPU quantums than the least privileged. Privilege is based on ASH
--              history, where a 95th PCTL on "ON CPU" and "Scheduler" times are prorated
--              as per adjusted number of cores. E.g. 36 cores, then 34 adjusted cores,
--              and PDB has a 95th PCTL of 34 (or higher), then shares becomes 10.
--
--              Utlization limits is between 10 and 50 on brakets of 5 (10, 15, ... , 50).
--              Prorated as per ratio between 99th PCTL of "ON CPU" and "Scheduler" as per
--              ASH hostory, where if such AAS were equal or larger than adjusted cores 
--              (e.g. 34) then utlization limit for PDB would be 50. Then, any PDB could
--              consume up to 50% of the resources (cpu_count) assigned to database.
--
-- Example:     SET LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
--              EXEC &&1..iod_rsrc_mgr.reset(p_report_only => 'N', p_plan => 'IOD_CDB_PLAN', p_switch_plan => 'Y');
--              EXEC &&1..iod_rsrc_mgr.reset_iod_cdb_plan;
--  
-- Notes:       (1) Parameter p_report_only = 'Y' produces "what-if" report.
--
/* ------------------------------------------------------------------------------------ */
gk_report_only CONSTANT VARCHAR2(1) := 'Y';
gk_plan        CONSTANT VARCHAR2(128) := 'IOD_CDB_PLAN';
gk_switch_plan CONSTANT VARCHAR2(1) := 'N';
/* ------------------------------------------------------------------------------------ */
PROCEDURE reset (
  p_report_only IN VARCHAR2 DEFAULT gk_report_only,
  p_plan        IN VARCHAR2 DEFAULT gk_plan,
  p_switch_plan IN VARCHAR2 DEFAULT gk_switch_plan
);
/* ------------------------------------------------------------------------------------ */
PROCEDURE reset_iod_cdb_plan;
/* ------------------------------------------------------------------------------------ */
END iod_rsrc_mgr;
/
