DEF spb_script = 'spb_zap';
----------------------------------------------------------------------------------------
--
-- File name:   spb_zap.sql
--
-- Purpose:     Zap a SQL Plan Baseline for given SQL_ID
--
-- Author:      Carlos Sierra
--
-- Version:     2018/05/11
--
-- Usage:       Connecting into PDB.
--
--              Enter SQL_ID when requested.
--
-- Example:     $ sqlplus / as sysdba
--              SQL> @spb_zap.sql
--
-- Notes:       Accesses AWR data thus you must have an Oracle Diagnostics Pack License.
--
--              Developed and tested on 12.1.0.2.
--
---------------------------------------------------------------------------------------
--
@@spb_internal_begin.sql
--
---------------------------------------------------------------------------------------
--
PRO
PRO EXISTING BASELINES
PRO ~~~~~~~~~~~~~~~~~~
@@spb_internal_list.sql
--
---------------------------------------------------------------------------------------
--
@@spb_internal_plans_perf.sql
--
---------------------------------------------------------------------------------------
--
PRO
PRO EXECUTING MIGHTY ZAPPER
PRO ~~~~~~~~~~~~~~~~~~~~~~~
PRO please wait...
PRO
ALTER SESSION SET CONTAINER = CDB$ROOT;
SET SERVEROUT ON;
EXEC c##iod.IOD_SPM.fpz(p_report_only => 'N', p_pdb_name => '&&x_container.', p_sql_id => '&&sql_id.');
SET SERVEROUT OFF;
ALTER SESSION SET CONTAINER = &&x_container.;
--
---------------------------------------------------------------------------------------
--
PRO
PRO RESULTING BASELINES
PRO ~~~~~~~~~~~~~~~~~~~
@@spb_internal_list.sql
--
@@spb_internal_end.sql
