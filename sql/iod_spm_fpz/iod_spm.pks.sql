CREATE OR REPLACE PACKAGE &&1..iod_spm AUTHID DEFINER AS
/* $Header: iod_spm.pks.sql 2017-12-20T21:41:59 carlos.sierra $ */
/* ------------------------------------------------------------------------------------ */
--
-- Purpose:     Implement SQL Plan Management (SPM) on a high-rate OLTP application 
--              where stable latency is prefered over flexible execution plans.
--
-- Author:      Carlos Sierra
--
-- Usage:       Execute from CDB$ROOT. Levels: one SQL_ID, one PDB, or all PDBS.
--
-- Example:     For one SQL:
--                SET LINES 145 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
--                EXEC &&1..iod_spm.fpz(p_report_only => 'N', p_pdb_name => 'COMPUTE', p_sql_id => '9knmfv7smm4q1');
--
--              For one PDB:
--                SET LINES 145 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
--                EXEC &&1..iod_spm.fpz(p_report_only => 'N', p_pdb_name => 'COMPUTE');
--
--              For all PDBs:
--                SET LINES 145 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
--                EXEC &&1..iod_spm.fpz(p_report_only => 'N');
--
-- Notes:       Parameter p_report_only = 'Y' produces "what-if" report.
--
--              For more granularity consider maintain_plans procedure instead of fpz.
--
/* ------------------------------------------------------------------------------------ */
PROCEDURE maintain_plans (
  p_report_only                  IN VARCHAR2 DEFAULT NULL, -- (Y|N) when Y then only produces report and changes nothing
  p_create_spm_limit             IN NUMBER   DEFAULT NULL, -- limits the number of SPMs to be created in one execution
  p_promote_spm_limit            IN NUMBER   DEFAULT NULL, -- limits the number of SPMs to be promoted to "FIXED" in one execution
  p_disable_spm_limit            IN NUMBER   DEFAULT NULL, -- limits the number of SPMs to be demoted to "DISABLE" in one execution
  p_aggressiveness               IN NUMBER   DEFAULT NULL, -- (1-5) range between 1 to 5 where 1 is conservative and 5 is aggresive
  p_repo_rejected_candidates     IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include on report rejected candidates
  p_repo_non_promoted_spb        IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include on report non-fixed SPB that is not getting promoted to "FIXED"
  p_pdb_name                     IN VARCHAR2 DEFAULT NULL, -- evaluate only this one PDB
  p_sql_id                       IN VARCHAR2 DEFAULT NULL, -- evaluate only this one SQL
  p_incl_plans_appl_1            IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include SQL from 1st application (BeginTx)
  p_incl_plans_appl_2            IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include SQL from 2nd application (CommitTx)
  p_incl_plans_appl_3            IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include SQL from 3rd application (Read)
  p_incl_plans_appl_4            IN VARCHAR2 DEFAULT 'Y',  -- (Y|N) include SQL from 4th application (GC)
  p_incl_plans_non_appl          IN VARCHAR2 DEFAULT 'N',  -- (N|Y) consider as candidate SQL not qualified as "application module"
  p_execs_candidate              IN NUMBER   DEFAULT NULL, -- a plan must be executed these many times to be a candidate
  p_secs_per_exec_cand           IN NUMBER   DEFAULT NULL, -- a plan must perform better than this threshold to be a candidate
  p_first_load_time_days_cand    IN NUMBER   DEFAULT NULL, -- a sql must be loaded into memory at least this many days before it is considered as candidate
  p_awr_days                     IN NUMBER   DEFAULT NULL, -- amount of days to consider from AWR history assuming retention is at least this long
  p_cur_days                     IN NUMBER   DEFAULT NULL  -- cursor must be active within the past k_cur_days to be considered
);
/* ------------------------------------------------------------------------------------ */
PROCEDURE fpz (
  p_report_only                  IN VARCHAR2 DEFAULT NULL, -- (Y|N) when Y then only produces report and changes nothing
  p_pdb_name                     IN VARCHAR2 DEFAULT NULL, -- evaluate only this one PDB
  p_sql_id                       IN VARCHAR2 DEFAULT NULL  -- evaluate only this one SQL
);
/* ------------------------------------------------------------------------------------ */
END iod_spm;
/
