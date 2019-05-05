CREATE OR REPLACE PACKAGE &&1..iod_spm AUTHID DEFINER AS
/* $Header: iod_spm.pks.sql &&library_version. carlos.sierra $ */
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
--                SET LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
--                EXEC &&1..iod_spm.fpz(p_report_only => 'N', p_pdb_name => 'COMPUTE', p_sql_id => '9knmfv7smm4q1');
--
--              For one PDB:
--                SET LINES 145 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
--                EXEC &&1..iod_spm.fpz(p_report_only => 'N', p_pdb_name => 'COMPUTE');
--
--              For all PDBs:
--                SET LINES 300 TRIMS ON SERVEROUT ON SIZE UNLIMITED;
--                EXEC &&1..iod_spm.fpz(p_report_only => 'N');
--
-- Notes:       (1) Parameter p_report_only = 'Y' produces "what-if" report.
--
--              (2) To demote SPBs that perform poor compared to when they created, 
--                  use "sentinel" API
--
/* ------------------------------------------------------------------------------------ */
gk_all CONSTANT VARCHAR2(3) := 'ALL';
/* ------------------------------------------------------------------------------------ */
FUNCTION application_category (p_sql_text IN VARCHAR2)
RETURN VARCHAR2;
/* ------------------------------------------------------------------------------------ */
PROCEDURE maintain_plans (
  p_report_only    IN VARCHAR2 DEFAULT 'N',    -- (Y|N) when Y then only produces report and changes nothing
  p_aggressiveness IN NUMBER   DEFAULT 1,      -- (1 .. N) 1=conservative, 2, 3=moderate, 4, ..., N=aggressive
  p_pdb_name       IN VARCHAR2 DEFAULT gk_all, -- evaluate only this one PDB
  p_sql_id         IN VARCHAR2 DEFAULT gk_all  -- evaluate only this one SQL
);
/* ------------------------------------------------------------------------------------ */
PROCEDURE fpz (
  p_report_only IN VARCHAR2 DEFAULT 'N',    -- (Y|N) when Y then only produces report and changes nothing
  p_pdb_name    IN VARCHAR2 DEFAULT gk_all, -- evaluate only this one PDB
  p_sql_id      IN VARCHAR2 DEFAULT gk_all  -- evaluate only this one SQL
);
/* ------------------------------------------------------------------------------------ */
END iod_spm;
/
